const Notification = require('../models/Notification');
const User = require('../models/User');

async function notify(userId, { title, body, type, referenceId }) {
  try {
    await Notification.create({
      user: userId,
      title,
      body,
      type,
      referenceId,
      sentAt: new Date(),
    });
  } catch (err) {
    console.error('Failed to create notification:', err.message);
  }
}

async function notifyAllAdmins({ title, body, type, referenceId }) {
  try {
    const admins = await User.find({ role: 'ADMIN', isActive: true }, '_id');
    for (const admin of admins) {
      await notify(admin._id, { title, body, type, referenceId });
    }
  } catch (err) {
    console.error('Failed to notify admins:', err.message);
  }
}

module.exports = { notify, notifyAllAdmins };
