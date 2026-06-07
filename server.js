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

// ── Auth middleware ──────────────────────────────────────────────────────────
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

// ── Helpers ──────────────────────────────────────────────────────────────────
function generateCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let i = 0; i < 8; i++) code += chars[Math.floor(Math.random() * chars.length)];
  return code;
}

function uniqueCode() {
  let code;
  do { code = generateCode(); }
  while (db.prepare('SELECT 1 FROM links WHERE share_code = ?').get(code));
  return code;
}

// ── Auth routes ───────────────────────────────────────────────────────────────
app.post('/api/register', (req, res) => {
  const { username, displayName, password } = req.body;
  if (!username || !password) return res.status(400).json({ error: 'Username and password required' });

  const trimmed = username.trim().toLowerCase();
  if (trimmed.length < 3) return res.status(400).json({ error: 'Username must be at least 3 characters' });
  if (!/^[a-z0-9_]+$/.test(trimmed)) return res.status(400).json({ error: 'Only letters, numbers, and underscores allowed' });

  const existing = db.prepare('SELECT id FROM users WHERE username = ?').get(trimmed);
  if (existing) return res.status(409).json({ error: 'Username already taken' });

  const hash = bcrypt.hashSync(password, 10);
  const id = uuidv4();
  const now = new Date().toISOString();
  const name = (displayName || trimmed).trim();

  db.prepare('INSERT INTO users (id, username, display_name, password_hash, created_at) VALUES (?, ?, ?, ?, ?)')
    .run(id, trimmed, name, hash, now);

  const token = jwt.sign({ id, username: trimmed, displayName: name }, JWT_SECRET, { expiresIn: '90d' });
  res.json({ user: { id, username: trimmed, displayName: name }, token });
});

app.post('/api/login', (req, res) => {
  const { username, password } = req.body;
  const trimmed = username?.trim().toLowerCase();
  const user = db.prepare('SELECT * FROM users WHERE username = ?').get(trimmed);
  if (!user || !bcrypt.compareSync(password, user.password_hash)) {
    return res.status(401).json({ error: 'Invalid username or password' });
  }
  const token = jwt.sign(
    { id: user.id, username: user.username, displayName: user.display_name },
    JWT_SECRET,
    { expiresIn: '90d' }
  );
  res.json({ user: { id: user.id, username: user.username, displayName: user.display_name }, token });
});

// ── Link routes ───────────────────────────────────────────────────────────────
app.post('/api/links', auth, (req, res) => {
  const { promptTypeKey } = req.body;
  if (!promptTypeKey) return res.status(400).json({ error: 'promptTypeKey required' });

  const code = uniqueCode();
  const id = uuidv4();
  const now = new Date().toISOString();

  db.prepare('INSERT INTO links (id, user_id, username, prompt_type_key, share_code, created_at) VALUES (?, ?, ?, ?, ?, ?)')
    .run(id, req.user.id, req.user.username, promptTypeKey, code, now);

  res.json({ link: { id, userId: req.user.id, username: req.user.username, promptTypeKey, shareCode: code, isActive: true, responseCount: 0, createdAt: now } });
});

app.get('/api/links', auth, (req, res) => {
  const rows = db.prepare(`
    SELECT l.*, COUNT(r.id) as response_count
    FROM links l
    LEFT JOIN responses r ON r.link_id = l.id
    WHERE l.user_id = ?
    GROUP BY l.id
    ORDER BY l.created_at DESC
  `).all(req.user.id);

  res.json({ links: rows.map(row => ({
    id: row.id,
    userId: row.user_id,
    username: row.username,
    promptTypeKey: row.prompt_type_key,
    shareCode: row.share_code,
    isActive: row.is_active === 1,
    responseCount: row.response_count,
    createdAt: row.created_at,
  }))});
});

app.delete('/api/links/:id', auth, (req, res) => {
  const link = db.prepare('SELECT * FROM links WHERE id = ? AND user_id = ?').get(req.params.id, req.user.id);
  if (!link) return res.status(404).json({ error: 'Not found' });
  db.prepare('DELETE FROM responses WHERE link_id = ?').run(link.id);
  db.prepare('DELETE FROM links WHERE id = ?').run(link.id);
  res.json({ success: true });
});

// ── Public respond routes ─────────────────────────────────────────────────────
app.get('/api/r/:code', (req, res) => {
  const row = db.prepare(`
    SELECT l.*, COUNT(r.id) as response_count
    FROM links l
    LEFT JOIN responses r ON r.link_id = l.id
    WHERE l.share_code = ?
    GROUP BY l.id
  `).get(req.params.code.toUpperCase());

  if (!row) return res.status(404).json({ error: 'Link not found' });
  if (!row.is_active) return res.status(410).json({ error: 'This link has been closed' });

  res.json({ link: {
    id: row.id,
    username: row.username,
    promptTypeKey: row.prompt_type_key,
    shareCode: row.share_code,
    isActive: row.is_active === 1,
    responseCount: row.response_count,
    createdAt: row.created_at,
  }});
});

app.post('/api/r/:code/respond', (req, res) => {
  const { message } = req.body;
  if (!message?.trim()) return res.status(400).json({ error: 'Message cannot be empty' });
  if (message.trim().length > 500) return res.status(400).json({ error: 'Message too long (max 500 chars)' });

  const link = db.prepare('SELECT * FROM links WHERE share_code = ?').get(req.params.code.toUpperCase());
  if (!link) return res.status(404).json({ error: 'Link not found. Check the code.' });
  if (!link.is_active) return res.status(410).json({ error: 'This prompt link has been closed.' });

  const id = uuidv4();
  db.prepare('INSERT INTO responses (id, link_id, message, created_at) VALUES (?, ?, ?, ?)')
    .run(id, link.id, message.trim(), new Date().toISOString());

  res.json({ success: true });
});

app.get('/api/links/:id/responses', auth, (req, res) => {
  const link = db.prepare('SELECT * FROM links WHERE id = ? AND user_id = ?').get(req.params.id, req.user.id);
  if (!link) return res.status(404).json({ error: 'Not found' });

  const rows = db.prepare('SELECT * FROM responses WHERE link_id = ? ORDER BY created_at DESC').all(link.id);
  res.json({ responses: rows.map(r => ({
    id: r.id,
    linkId: r.link_id,
    message: r.message,
    isRead: r.is_read === 1,
    createdAt: r.created_at,
  }))});
});

// ── Web respond page ──────────────────────────────────────────────────────────
app.get('/r/:code', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'respond.html'));
});

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`Anonymous backend running on http://localhost:${PORT}`);
});
