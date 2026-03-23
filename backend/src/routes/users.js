const express = require('express');
const User = require('../models/User');
const { auth } = require('../middleware/auth');
const { apiResponse } = require('../utils/helpers');

const router = express.Router();

// GET /users/me
router.get('/me', auth, async (req, res, next) => {
  try {
    const user = await User.findById(req.userId);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    res.json(apiResponse(user));
  } catch (err) {
    next(err);
  }
});

// PUT /users/me
router.put('/me', auth, async (req, res, next) => {
  try {
    const { name, email, phone, profileImageUrl } = req.body;
    const user = await User.findById(req.userId);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });

    if (name) user.name = name;
    if (email) user.email = email;
    if (phone) user.phone = phone;
    if (profileImageUrl) user.profileImageUrl = profileImageUrl;

    await user.save();
    res.json(apiResponse(user, 'Profile updated'));
  } catch (err) {
    next(err);
  }
});

// PUT /users/me/fcm-token
router.put('/me/fcm-token', auth, async (req, res, next) => {
  try {
    await User.findByIdAndUpdate(req.userId, { fcmToken: req.body.fcmToken });
    res.json(apiResponse(null, 'FCM token updated'));
  } catch (err) {
    next(err);
  }
});

// DELETE /users/me
router.delete('/me', auth, async (req, res, next) => {
  try {
    await User.findByIdAndUpdate(req.userId, { isActive: false });
    res.json(apiResponse(null, 'Account deactivated'));
  } catch (err) {
    next(err);
  }
});

module.exports = router;
