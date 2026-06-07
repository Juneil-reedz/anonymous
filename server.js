const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const path = require('path');
const db = require('./db');

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'anon-secret-change-in-prod';

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// ── Health check ─────────────────────────────────────────────────────────────
app.get('/api/health', (req, res) => {
  res.json({ ok: true, time: new Date().toISOString() });
});

// ── Auth middleware ───────────────────────────────────────────────────────────
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

// ── Helpers ───────────────────────────────────────────────────────────────────
function generateCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let i = 0; i < 8; i++) code += chars[Math.floor(Math.random() * chars.length)];
  return code;
}

function uniqueCode() {
  let code;
  do { code = generateCode(); }
  while (db.codeExists(code));
  return code;
}

// ── Auth routes ───────────────────────────────────────────────────────────────
app.post('/api/register', wrap((req, res) => {
  const { username, displayName, password } = req.body || {};
  if (!username || !password) return res.status(400).json({ error: 'Username and password required' });

  const trimmed = username.trim().toLowerCase();
  if (trimmed.length < 3) return res.status(400).json({ error: 'Username must be at least 3 characters' });
  if (!/^[a-z0-9_]+$/.test(trimmed)) return res.status(400).json({ error: 'Only letters, numbers, and underscores allowed' });

  const existing = db.findUser(u => u.username === trimmed);
  if (existing) return res.status(409).json({ error: 'Username already taken' });

  const hash = bcrypt.hashSync(password, 10);
  const id = uuidv4();
  const now = new Date().toISOString();
  const name = ((displayName || trimmed) + '').trim() || trimmed;

  db.createUser({ id, username: trimmed, displayName: name, passwordHash: hash, createdAt: now });

  const token = jwt.sign({ id, username: trimmed, displayName: name }, JWT_SECRET, { expiresIn: '90d' });
  res.json({ user: { id, username: trimmed, displayName: name }, token });
}));

app.post('/api/login', wrap((req, res) => {
  const { username, password } = req.body || {};
  const trimmed = username?.trim().toLowerCase();
  const user = db.findUser(u => u.username === trimmed);
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

// ── Link routes ───────────────────────────────────────────────────────────────
app.post('/api/links', auth, wrap((req, res) => {
  const { promptTypeKey } = req.body || {};
  if (!promptTypeKey) return res.status(400).json({ error: 'promptTypeKey required' });

  const code = uniqueCode();
  const id = uuidv4();
  const now = new Date().toISOString();

  db.createLink({ id, userId: req.user.id, username: req.user.username, promptTypeKey, shareCode: code, isActive: true, createdAt: now });

  res.json({ link: { id, userId: req.user.id, username: req.user.username, promptTypeKey, shareCode: code, isActive: true, responseCount: 0, createdAt: now } });
}));

app.get('/api/links', auth, wrap((req, res) => {
  const links = db.allLinksForUser(req.user.id);
  res.json({ links });
}));

app.delete('/api/links/:id', auth, wrap((req, res) => {
  const link = db.findLinkById(req.params.id);
  if (!link || link.userId !== req.user.id) return res.status(404).json({ error: 'Not found' });
  db.deleteLink(req.params.id);
  res.json({ success: true });
}));

app.get('/api/links/:id/responses', auth, wrap((req, res) => {
  const link = db.findLinkById(req.params.id);
  if (!link || link.userId !== req.user.id) return res.status(404).json({ error: 'Not found' });
  const responses = db.getResponses(req.params.id);
  res.json({ responses });
}));

// ── Public respond routes ─────────────────────────────────────────────────────
app.get('/api/r/:code', wrap((req, res) => {
  const link = db.findLinkByCode(req.params.code.toUpperCase());
  if (!link) return res.status(404).json({ error: 'Link not found' });
  if (!link.isActive) return res.status(410).json({ error: 'This link has been closed' });
  const responseCount = db.getResponses(link.id).length;
  res.json({ link: { ...link, responseCount } });
}));

app.post('/api/r/:code/respond', wrap((req, res) => {
  const { message } = req.body || {};
  if (!message?.trim()) return res.status(400).json({ error: 'Message cannot be empty' });
  if (message.trim().length > 500) return res.status(400).json({ error: 'Message too long (max 500 chars)' });

  const link = db.findLinkByCode(req.params.code.toUpperCase());
  if (!link) return res.status(404).json({ error: 'Link not found. Check the code.' });
  if (!link.isActive) return res.status(410).json({ error: 'This prompt link has been closed.' });

  const id = uuidv4();
  db.addResponse({ id, linkId: link.id, message: message.trim(), isRead: false, createdAt: new Date().toISOString() });
  res.json({ success: true });
}));

// ── Web respond page ──────────────────────────────────────────────────────────
app.get('/r/:code', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'respond.html'));
});

// ── Global error handler ──────────────────────────────────────────────────────
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: err.message || 'Internal server error' });
});

app.listen(PORT, () => {
  console.log(`Anonymous backend running on port ${PORT}`);
});
