const admin = require('firebase-admin');

const fs = () => admin.firestore();

module.exports = {
  // ── Users ──────────────────────────────────────────────────────────────────
  findUserByUsername: async (username) => {
    const snap = await fs().collection('users').where('username', '==', username).limit(1).get();
    return snap.empty ? null : { id: snap.docs[0].id, ...snap.docs[0].data() };
  },

  findUserById: async (id) => {
    const doc = await fs().collection('users').doc(id).get();
    return doc.exists ? { id: doc.id, ...doc.data() } : null;
  },

  createUser: async (user) => {
    const { id, ...data } = user;
    await fs().collection('users').doc(id).set(data);
  },

  updateUser: async (id, fields) => {
    await fs().collection('users').doc(id).update(fields);
  },

  // ── Links ──────────────────────────────────────────────────────────────────
  allLinksForUser: async (userId) => {
    const snap = await fs().collection('links').where('userId', '==', userId).get();
    const links = await Promise.all(
      snap.docs.map(async (doc) => {
        const countSnap = await fs().collection('responses').where('linkId', '==', doc.id).get();
        return { id: doc.id, ...doc.data(), responseCount: countSnap.size };
      })
    );
    return links.sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  },

  findLinkByCode: async (code) => {
    const snap = await fs().collection('links').where('shareCode', '==', code).limit(1).get();
    return snap.empty ? null : { id: snap.docs[0].id, ...snap.docs[0].data() };
  },

  findLinkById: async (id) => {
    const doc = await fs().collection('links').doc(id).get();
    return doc.exists ? { id: doc.id, ...doc.data() } : null;
  },

  createLink: async (link) => {
    const { id, ...data } = link;
    await fs().collection('links').doc(id).set(data);
  },

  deleteLink: async (id) => {
    const batch = fs().batch();
    batch.delete(fs().collection('links').doc(id));
    const responses = await fs().collection('responses').where('linkId', '==', id).get();
    responses.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
  },

  codeExists: async (code) => {
    const snap = await fs().collection('links').where('shareCode', '==', code).limit(1).get();
    return !snap.empty;
  },

  // ── Responses ──────────────────────────────────────────────────────────────
  getResponses: async (linkId) => {
    const snap = await fs().collection('responses').where('linkId', '==', linkId).get();
    return snap.docs
      .map((doc) => ({ id: doc.id, ...doc.data() }))
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  },

  addResponse: async (response) => {
    const { id, ...data } = response;
    await fs().collection('responses').doc(id).set(data);
  },

  addReply: async (responseId, reply, repliedAt) => {
    const ref = fs().collection('responses').doc(responseId);
    const doc = await ref.get();
    if (!doc.exists) return null;
    await ref.update({ reply, repliedAt });
    return { id: doc.id, ...doc.data(), reply, repliedAt };
  },
};
