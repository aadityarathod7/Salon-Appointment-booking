const jwt = require('jsonwebtoken');
const crypto = require('crypto');

function generateAccessToken(userId, email, role) {
  return jwt.sign(
    { userId, email, role },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_ACCESS_EXPIRATION || '15m' }
  );
}

function generateRefreshToken() {
  return crypto.randomUUID();
}

function hashToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

function generateBookingRef(date) {
  const d = new Date(date);
  const dateStr = d.toISOString().slice(0, 10).replace(/-/g, '');
  const random = Math.floor(100 + Math.random() * 900);
  return `SLN-${dateStr}-${random}`;
}

// Parse "HH:MM" to minutes since midnight
function timeToMinutes(timeStr) {
  const [h, m] = timeStr.split(':').map(Number);
  return h * 60 + m;
}

// Convert minutes since midnight to "HH:MM"
function minutesToTime(mins) {
  const h = Math.floor(mins / 60);
  const m = mins % 60;
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
}

function apiResponse(data = null, message = null) {
  return { success: true, message, data, errors: null };
}

function apiError(message, statusCode = 400) {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
}

module.exports = {
  generateAccessToken,
  generateRefreshToken,
  hashToken,
  generateBookingRef,
  timeToMinutes,
  minutesToTime,
  apiResponse,
  apiError,
};
