const fs = require('fs');
const path = require('path');

const DB_PATH = path.join(__dirname, 'data.json');

function read() {
  if (!fs.existsSync(DB_PATH)) return { users: [], links: [], responses: [] };
  try { return JSON.parse(fs.readFileSync(DB_PATH, 'utf8')); }
  catch { return { users: [], links: [], responses: [] }; }
}

function write(data) {
  fs.writeFileSync(DB_PATH, JSON.stringify(data, null, 2));
}

const db = {
  // Users
  findUser: (pred) => read().users.find(pred) || null,
  createUser: (user) => {
    const data = read();
    data.users.push(user);
    write(data);
  },

  // Links
  allLinksForUser: (userId) => {
    const data = read();
    return data.links
      .filter(l => l.userId === userId)
      .map(l => ({ ...l, responseCount: data.responses.filter(r => r.linkId === l.id).length }))
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  },
  findLinkByCode: (code) => read().links.find(l => l.shareCode === code) || null,
  findLinkById: (id) => read().links.find(l => l.id === id) || null,
  createLink: (link) => {
    const data = read();
    data.links.push(link);
    write(data);
  },
  deleteLink: (id) => {
    const data = read();
    data.links = data.links.filter(l => l.id !== id);
    data.responses = data.responses.filter(r => r.linkId !== id);
    write(data);
  },
  codeExists: (code) => !!read().links.find(l => l.shareCode === code),

  // Responses
  getResponses: (linkId) =>
    read().responses
      .filter(r => r.linkId === linkId)
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt)),
  addResponse: (response) => {
    const data = read();
    data.responses.push(response);
    write(data);
  },
  addReply: (responseId, reply, repliedAt) => {
    const data = read();
    const idx = data.responses.findIndex(r => r.id === responseId);
    if (idx === -1) return null;
    data.responses[idx].reply = reply;
    data.responses[idx].repliedAt = repliedAt;
    write(data);
    return data.responses[idx];
  },
};

module.exports = db;
