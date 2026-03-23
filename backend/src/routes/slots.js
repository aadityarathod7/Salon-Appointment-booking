const express = require('express');
const { auth } = require('../middleware/auth');
const { getAvailableSlots } = require('../services/slotService');
const { apiResponse } = require('../utils/helpers');

const router = express.Router();

// GET /slots/available?artistId=&serviceId=&date=
router.get('/available', auth, async (req, res, next) => {
  try {
    const { artistId, serviceId, date } = req.query;

    if (!artistId || !serviceId || !date) {
      return res.status(400).json({ success: false, message: 'artistId, serviceId, and date are required' });
    }

    const slots = await getAvailableSlots(artistId, serviceId, date);
    res.json(apiResponse(slots));
  } catch (err) {
    next(err);
  }
});

module.exports = router;
