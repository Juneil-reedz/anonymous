const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'anon-secret-change-in-prod';

// ── Firebase Admin (required for Firestore + FCM) ─────────────────────────────
const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT;
if (!serviceAccountJson) {
  console.error('ERROR: FIREBASE_SERVICE_ACCOUNT env var is missing. Set it in Render → Environment.');
  process.exit(1);
}

const admin = require('firebase-admin');
try {
  admin.initializeApp({ credential: admin.credential.cert(JSON.parse(serviceAccountJson)) });
  console.log('Firebase Admin initialized — Firestore + FCM ready');
} catch (e) {
  console.error('Firebase Admin init failed:', e.message);
  process.exit(1);
}

const db = require('./db');

// ── Push notification helper ───────────────────────────────────────────────────
async function sendPushNotification(userId, title, body, data = {}) {
  try {
    const user = await db.findUserById(userId);
    if (!user?.fcmToken) return;
    await admin.messaging().send({
      token: user.fcmToken,
      notification: { title, body },
      data,
      android: { priority: 'high' },
    });
  } catch (e) {
    console.warn('Push notification failed:', e.message);
  }
}

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// ── Health check ───────────────────────────────────────────────────────────────
app.get('/api/health', (req, res) => {
  res.json({ ok: true, time: new Date().toISOString() });
});

// ── Auth middleware ────────────────────────────────────────────────────────────
function auth(req, res, next) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) return res.status(401).json({ error: 'Unauthorized' });
  try {
    req.user = jwt.verify(header.slice(7), JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ error: 'Invalid token' });
  }
}

function wrap(fn) {
  return async (req, res, next) => {
    try { await fn(req, res, next); }
    catch (e) {
      console.error(e);
      res.status(500).json({ error: e.message || 'Internal server error' });
    }
  };
}

// ── Helpers ────────────────────────────────────────────────────────────────────
function generateCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let i = 0; i < 8; i++) code += chars[Math.floor(Math.random() * chars.length)];
  return code;
}

async function uniqueCode() {
  let code;
  do { code = generateCode(); }
  while (await db.codeExists(code));
  return code;
}

// ── Auth routes ────────────────────────────────────────────────────────────────
app.post('/api/register', wrap(async (req, res) => {
  const { username, displayName, password } = req.body || {};
  if (!username || !password) return res.status(400).json({ error: 'Username and password required' });

  const trimmed = username.trim().toLowerCase();
  if (trimmed.length < 3) return res.status(400).json({ error: 'Username must be at least 3 characters' });
  if (!/^[a-z0-9_]+$/.test(trimmed)) return res.status(400).json({ error: 'Only letters, numbers, and underscores allowed' });

  const existing = await db.findUserByUsername(trimmed);
  if (existing) return res.status(409).json({ error: 'Username already taken' });

  const hash = bcrypt.hashSync(password, 10);
  const id = uuidv4();
  const now = new Date().toISOString();
  const name = ((displayName || trimmed) + '').trim() || trimmed;

  await db.createUser({ id, username: trimmed, displayName: name, passwordHash: hash, createdAt: now });

  const token = jwt.sign({ id, username: trimmed, displayName: name }, JWT_SECRET, { expiresIn: '90d' });
  res.json({ user: { id, username: trimmed, displayName: name }, token });
}));

app.post('/api/login', wrap(async (req, res) => {
  const { username, password } = req.body || {};
  const trimmed = username?.trim().toLowerCase();
  const user = await db.findUserByUsername(trimmed);
  if (!user || !bcrypt.compareSync(password, user.passwordHash)) {
    return res.status(401).json({ error: 'Invalid username or password' });
  }
  const token = jwt.sign(
    { id: user.id, username: user.username, displayName: user.displayName },
    JWT_SECRET,
    { expiresIn: '90d' }
  );
  res.json({ user: { id: user.id, username: user.username, displayName: user.displayName }, token });
}));

// ── FCM token ──────────────────────────────────────────────────────────────────
app.post('/api/fcm-token', auth, wrap(async (req, res) => {
  const { token } = req.body || {};
  await db.updateUser(req.user.id, { fcmToken: token || null });
  res.json({ ok: true });
}));

// ── Link routes ────────────────────────────────────────────────────────────────
app.post('/api/links', auth, wrap(async (req, res) => {
  const { promptTypeKey, customQuestion } = req.body || {};
  if (!promptTypeKey) return res.status(400).json({ error: 'promptTypeKey required' });
  if (promptTypeKey === 'customPrompt') {
    if (!customQuestion?.trim()) return res.status(400).json({ error: 'Custom prompt requires a question' });
    if (customQuestion.trim().length > 200) return res.status(400).json({ error: 'Question too long (max 200 chars)' });
  }

  const code = await uniqueCode();
  const id = uuidv4();
  const now = new Date().toISOString();

  const linkData = { id, userId: req.user.id, username: req.user.username, promptTypeKey, shareCode: code, isActive: true, createdAt: now };
  if (customQuestion?.trim()) linkData.customQuestion = customQuestion.trim();

  await db.createLink(linkData);
  res.json({ link: { ...linkData, responseCount: 0 } });
}));

app.get('/api/links', auth, wrap(async (req, res) => {
  const links = await db.allLinksForUser(req.user.id);
  res.json({ links });
}));

app.delete('/api/links/:id', auth, wrap(async (req, res) => {
  const link = await db.findLinkById(req.params.id);
  if (!link || link.userId !== req.user.id) return res.status(404).json({ error: 'Not found' });
  await db.deleteLink(req.params.id);
  res.json({ success: true });
}));

app.get('/api/links/:id/responses', auth, wrap(async (req, res) => {
  const link = await db.findLinkById(req.params.id);
  if (!link || link.userId !== req.user.id) return res.status(404).json({ error: 'Not found' });
  const responses = await db.getResponses(req.params.id);
  res.json({ responses });
}));

app.post('/api/links/:linkId/responses/:responseId/reply', auth, wrap(async (req, res) => {
  const { reply } = req.body || {};
  if (!reply?.trim()) return res.status(400).json({ error: 'Reply cannot be empty' });
  if (reply.trim().length > 300) return res.status(400).json({ error: 'Reply too long (max 300 chars)' });

  const link = await db.findLinkById(req.params.linkId);
  if (!link || link.userId !== req.user.id) return res.status(404).json({ error: 'Not found' });

  const updated = await db.addReply(req.params.responseId, reply.trim(), new Date().toISOString());
  if (!updated) return res.status(404).json({ error: 'Response not found' });

  res.json({ response: updated });
}));

// ── Public respond routes ──────────────────────────────────────────────────────
app.get('/api/r/:code', wrap(async (req, res) => {
  const link = await db.findLinkByCode(req.params.code.toUpperCase());
  if (!link) return res.status(404).json({ error: 'Link not found' });
  if (!link.isActive) return res.status(410).json({ error: 'This link has been closed' });
  const responses = await db.getResponses(link.id);
  res.json({ link: { ...link, responseCount: responses.length } });
}));

app.post('/api/r/:code/respond', wrap(async (req, res) => {
  const { message } = req.body || {};
  if (!message?.trim()) return res.status(400).json({ error: 'Message cannot be empty' });
  if (message.trim().length > 500) return res.status(400).json({ error: 'Message too long (max 500 chars)' });

  const link = await db.findLinkByCode(req.params.code.toUpperCase());
  if (!link) return res.status(404).json({ error: 'Link not found. Check the code.' });
  if (!link.isActive) return res.status(410).json({ error: 'This prompt link has been closed.' });

  const id = uuidv4();
  await db.addResponse({ id, linkId: link.id, message: message.trim(), isRead: false, createdAt: new Date().toISOString() });

  sendPushNotification(
    link.userId,
    'New anonymous response! 👀',
    `Someone just responded to your "${link.promptTypeKey === 'customPrompt' ? link.customQuestion || 'custom prompt' : link.promptTypeKey}" prompt.`,
    { linkId: link.id, shareCode: link.shareCode },
  );

  res.json({ success: true });
}));

// ── Web respond page ───────────────────────────────────────────────────────────
app.get('/r/:code', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'respond.html'));
});

// ── 404 catch-all ─────────────────────────────────────────────────────────────
app.use((req, res) => {
  if (req.accepts('html')) {
    res.status(404).sendFile(path.join(__dirname, 'public', 'index.html'));
  } else {
    res.status(404).json({ error: 'Not found' });
  }
});

// ── Global error handler ───────────────────────────────────────────────────────
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: err.message || 'Internal server error' });
});

app.listen(PORT, () => {
  console.log(`Anonymous backend running on port ${PORT}`);
});
