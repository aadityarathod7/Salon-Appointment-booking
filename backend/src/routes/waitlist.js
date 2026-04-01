const express = require('express');
const Waitlist = require('../models/Waitlist');
const { auth } = require('../middleware/auth');
const { apiResponse } = require('../utils/helpers');

const router = express.Router();

// POST /waitlist
router.post('/', auth, async (req, res, next) => {
  try {
    const { artistId, serviceId, preferredDate, preferredTime, notes } = req.body;

    if (!artistId || !serviceId || !preferredDate) {
      return res.status(400).json({ success: false, message: 'artistId, serviceId, and preferredDate are required' });
    }

    const entry = new Waitlist({
      user: req.userId,
      artist: artistId,
      service: serviceId,
      preferredDate: new Date(preferredDate + 'T00:00:00'),
      preferredTimeStart: preferredTime,
      notes,
    });
    await entry.save();

    const populated = await Waitlist.findById(entry._id)
      .populate('artist', 'name')
      .populate('service', 'name');

    res.status(201).json(apiResponse(populated, 'Added to waitlist'));
  } catch (err) {
    next(err);
  }
});

// GET /waitlist
router.get('/', auth, async (req, res, next) => {
  try {
    const entries = await Waitlist.find({ user: req.userId })
      .populate('artist', 'name')
      .populate('service', 'name')
      .sort({ createdAt: -1 });

    res.json(apiResponse(entries));
  } catch (err) {
    next(err);
  }
});

// DELETE /waitlist/:id
router.delete('/:id', auth, async (req, res, next) => {
  try {
    await Waitlist.findOneAndDelete({ _id: req.params.id, user: req.userId });
    res.json(apiResponse(null, 'Removed from waitlist'));
  } catch (err) {
    next(err);
  }
});

module.exports = router;
