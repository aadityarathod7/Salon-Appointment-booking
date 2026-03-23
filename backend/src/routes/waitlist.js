const express = require('express');
const Waitlist = require('../models/Waitlist');
const { auth } = require('../middleware/auth');
const { apiResponse } = require('../utils/helpers');

const router = express.Router();

// POST /waitlist
router.post('/', auth, async (req, res, next) => {
  try {
    const { artistId, serviceId, preferredDate, preferredTimeStart, preferredTimeEnd } = req.body;

    const entry = new Waitlist({
      user: req.userId,
      artist: artistId,
      service: serviceId,
      preferredDate: new Date(preferredDate),
      preferredTimeStart,
      preferredTimeEnd,
    });
    await entry.save();

    res.status(201).json(apiResponse(entry, 'Added to waitlist'));
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

    const formatted = entries.map((e) => ({
      id: e._id,
      artistName: e.artist.name,
      serviceName: e.service.name,
      preferredDate: e.preferredDate.toISOString().slice(0, 10),
      status: e.status,
      createdAt: e.createdAt,
    }));

    res.json(apiResponse(formatted));
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
