const express = require('express');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const RefreshToken = require('../models/RefreshToken');
const { auth } = require('../middleware/auth');
const {
  generateAccessToken,
  generateRefreshToken,
  hashToken,
  apiResponse,
} = require('../utils/helpers');

const router = express.Router();

// POST /auth/register
router.post(
  '/register',
  [
    body('name').notEmpty().withMessage('Name is required'),
    body('email').optional().isEmail().withMessage('Invalid email format'),
    body('password').optional().isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  ],
  async (req, res, next) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ success: false, message: 'Validation failed', errors: errors.array().map((e) => e.msg) });
      }

      const { name, email, phone, password } = req.body;

      if (!email && !phone) {
        return res.status(400).json({ success: false, message: 'Either email or phone is required' });
      }

      if (email) {
        const existing = await User.findOne({ email });
        if (existing) return res.status(409).json({ success: false, message: 'Email already registered' });
      }
      if (phone) {
        const existing = await User.findOne({ phone });
        if (existing) return res.status(409).json({ success: false, message: 'Phone already registered' });
      }

      const user = new User({
        name,
        email,
        phone,
        passwordHash: password,
        role: 'CUSTOMER',
        authProvider: 'LOCAL',
      });
      await user.save();

      const tokens = await createTokens(user);
      res.status(201).json(apiResponse(tokens, 'Registration successful'));
    } catch (err) {
      next(err);
    }
  }
);

// POST /auth/login
router.post(
  '/login',
  [
    body('emailOrPhone').notEmpty(),
    body('password').notEmpty(),
  ],
  async (req, res, next) => {
    try {
      const { emailOrPhone, password } = req.body;

      const user =
        (await User.findOne({ email: emailOrPhone })) ||
        (await User.findOne({ phone: emailOrPhone }));

      if (!user || !user.isActive) {
        return res.status(401).json({ success: false, message: 'Invalid credentials' });
      }

      const isMatch = await user.comparePassword(password);
      if (!isMatch) {
        return res.status(401).json({ success: false, message: 'Invalid credentials' });
      }

      const tokens = await createTokens(user);
      res.json(apiResponse(tokens, 'Login successful'));
    } catch (err) {
      next(err);
    }
  }
);

// POST /auth/otp/send
router.post('/otp/send', async (req, res) => {
  // In production, integrate SMS provider (Twilio/MSG91)
  res.json(apiResponse(null, 'OTP sent successfully'));
});

// POST /auth/otp/verify
router.post('/otp/verify', async (req, res, next) => {
  try {
    const { phone, otp } = req.body;

    // Dev: accept "123456"
    if (otp !== '123456') {
      return res.status(401).json({ success: false, message: 'Invalid OTP' });
    }

    let user = await User.findOne({ phone });
    if (!user) {
      user = new User({ name: 'User', phone, role: 'CUSTOMER', authProvider: 'LOCAL' });
      await user.save();
    }

    if (!user.isActive) {
      return res.status(401).json({ success: false, message: 'Account is deactivated' });
    }

    const tokens = await createTokens(user);
    res.json(apiResponse(tokens, 'OTP verified'));
  } catch (err) {
    next(err);
  }
});

// POST /auth/social
router.post('/social', async (req, res, next) => {
  try {
    const { token, provider, name, email } = req.body;
    if (!email) {
      return res.status(400).json({ success: false, message: 'Email is required for social login' });
    }

    let user = await User.findOne({ email });
    if (!user) {
      user = new User({
        name: name || 'User',
        email,
        role: 'CUSTOMER',
        authProvider: provider.toUpperCase(),
      });
      await user.save();
    }

    if (!user.isActive) {
      return res.status(401).json({ success: false, message: 'Account is deactivated' });
    }

    const tokens = await createTokens(user);
    res.json(apiResponse(tokens, 'Login successful'));
  } catch (err) {
    next(err);
  }
});

// POST /auth/refresh
router.post('/refresh', async (req, res, next) => {
  try {
    const { refreshToken: token } = req.body;
    if (!token) {
      return res.status(400).json({ success: false, message: 'Refresh token is required' });
    }

    const tokenDoc = await RefreshToken.findOne({ tokenHash: hashToken(token) }).populate('user');
    if (!tokenDoc || tokenDoc.isRevoked || tokenDoc.expiresAt < new Date() || !tokenDoc.user) {
      return res.status(401).json({ success: false, message: 'Invalid or expired refresh token' });
    }

    // Revoke old token
    tokenDoc.isRevoked = true;
    await tokenDoc.save();

    const tokens = await createTokens(tokenDoc.user);
    res.json(apiResponse(tokens, 'Token refreshed'));
  } catch (err) {
    next(err);
  }
});

// POST /auth/logout
router.post('/logout', auth, async (req, res, next) => {
  try {
    await RefreshToken.updateMany({ user: req.userId, isRevoked: false }, { isRevoked: true });
    res.json(apiResponse(null, 'Logged out successfully'));
  } catch (err) {
    next(err);
  }
});

async function createTokens(user) {
  const userId = user._id || user.id;
  const accessToken = generateAccessToken(userId, user.email, user.role);
  const refreshTokenStr = generateRefreshToken();

  const refreshToken = new RefreshToken({
    user: userId,
    tokenHash: hashToken(refreshTokenStr),
    expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
  });
  await refreshToken.save();

  return {
    accessToken,
    refreshToken: refreshTokenStr,
    user: user.toJSON(),
  };
}

module.exports = router;
