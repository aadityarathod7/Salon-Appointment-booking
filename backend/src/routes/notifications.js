const express = require('express');
const Notification = require('../models/Notification');
const { auth } = require('../middleware/auth');
const { apiResponse } = require('../utils/helpers');

const router = express.Router();

// GET /notifications
router.get('/', auth, async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 0;
    const size = parseInt(req.query.size) || 50;

    const [notifications, total] = await Promise.all([
      Notification.find({ user: req.userId })
        .sort({ createdAt: -1 })
        .skip(page * size)
        .limit(size),
      Notification.countDocuments({ user: req.userId }),
    ]);

    const content = notifications.map((n) => ({
      id: n._id,
      title: n.title,
      body: n.body,
      type: n.type,
      referenceId: n.referenceId,
      isRead: n.isRead,
      sentAt: n.sentAt,
    }));

    res.json(
      apiResponse({
        content,
        totalElements: total,
        totalPages: Math.ceil(total / size),
        number: page,
        size,
      })
    );
  } catch (err) {
    next(err);
  }
});

// PUT /notifications/:id/read
router.put('/:id/read', auth, async (req, res, next) => {
  try {
    await Notification.findOneAndUpdate(
      { _id: req.params.id, user: req.userId },
      { isRead: true }
    );
    res.json(apiResponse(null, 'Notification marked as read'));
  } catch (err) {
    next(err);
  }
});

// PUT /notifications/read-all
router.put('/read-all', auth, async (req, res, next) => {
  try {
    await Notification.updateMany({ user: req.userId, isRead: false }, { isRead: true });
    res.json(apiResponse(null, 'All notifications marked as read'));
  } catch (err) {
    next(err);
  }
});

module.exports = router;
