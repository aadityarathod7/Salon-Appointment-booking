const express = require('express');
const Review = require('../models/Review');
const Appointment = require('../models/Appointment');
const Artist = require('../models/Artist');
const { auth, adminOnly } = require('../middleware/auth');
const { apiResponse } = require('../utils/helpers');

const router = express.Router();

// POST /reviews
router.post('/', auth, async (req, res, next) => {
  try {
    const { appointmentId, rating, comment } = req.body;

    if (!appointmentId || !rating) {
      return res.status(400).json({ success: false, message: 'appointmentId and rating are required' });
    }
    if (!Number.isInteger(rating) || rating < 1 || rating > 5) {
      return res.status(400).json({ success: false, message: 'Rating must be between 1 and 5' });
    }

    const appointment = await Appointment.findOne({ _id: appointmentId, user: req.userId });
    if (!appointment) return res.status(404).json({ success: false, message: 'Appointment not found' });

    if (appointment.status !== 'COMPLETED') {
      return res.status(400).json({ success: false, message: 'Can only review completed appointments' });
    }

    const existing = await Review.findOne({ appointment: appointmentId });
    if (existing) {
      return res.status(400).json({ success: false, message: 'Already reviewed this appointment' });
    }

    const review = new Review({
      appointment: appointmentId,
      user: req.userId,
      artist: appointment.artist,
      service: appointment.service,
      rating,
      comment,
    });
    await review.save();

    // Update artist rating
    await updateArtistRating(appointment.artist);

    const populated = await Review.findById(review._id)
      .populate('user', 'name profileImageUrl')
      .populate('service', 'name');

    res.status(201).json(apiResponse(formatReview(populated), 'Review submitted'));
  } catch (err) {
    next(err);
  }
});

// PUT /reviews/:id
router.put('/:id', auth, async (req, res, next) => {
  try {
    const review = await Review.findOne({ _id: req.params.id, user: req.userId });
    if (!review) return res.status(404).json({ success: false, message: 'Review not found' });

    if (req.body.rating) review.rating = req.body.rating;
    if (req.body.comment !== undefined) review.comment = req.body.comment;
    await review.save();

    await updateArtistRating(review.artist);

    const populated = await Review.findById(review._id)
      .populate('user', 'name profileImageUrl')
      .populate('service', 'name');

    res.json(apiResponse(formatReview(populated), 'Review updated'));
  } catch (err) {
    next(err);
  }
});

// PUT /reviews/:id/reply (admin only)
router.put('/:id/reply', auth, adminOnly, async (req, res, next) => {
  try {
    const { reply } = req.body;
    if (!reply) return res.status(400).json({ success: false, message: 'Reply is required' });

    const review = await Review.findById(req.params.id);
    if (!review) return res.status(404).json({ success: false, message: 'Review not found' });

    review.adminReply = reply;
    await review.save();

    const populated = await Review.findById(review._id)
      .populate('user', 'name profileImageUrl')
      .populate('service', 'name');

    res.json(apiResponse(formatReview(populated), 'Reply added'));
  } catch (err) {
    next(err);
  }
});

// DELETE /reviews/:id
router.delete('/:id', auth, async (req, res, next) => {
  try {
    const review = await Review.findOne({ _id: req.params.id, user: req.userId });
    if (!review) return res.status(404).json({ success: false, message: 'Review not found' });

    const artistId = review.artist;
    await review.deleteOne();
    await updateArtistRating(artistId);

    res.json(apiResponse(null, 'Review deleted'));
  } catch (err) {
    next(err);
  }
});

async function updateArtistRating(artistId) {
  const result = await Review.aggregate([
    { $match: { artist: artistId } },
    { $group: { _id: null, avg: { $avg: '$rating' }, count: { $sum: 1 } } },
  ]);

  const avgRating = result.length > 0 ? Math.round(result[0].avg * 10) / 10 : 0;
  const totalReviews = result.length > 0 ? result[0].count : 0;

  await Artist.findByIdAndUpdate(artistId, { avgRating, totalReviews });
}

function formatReview(r) {
  return {
    id: r._id,
    userName: r.user?.name ?? 'Deleted User',
    userProfileImage: r.user?.profileImageUrl ?? null,
    rating: r.rating,
    comment: r.comment,
    adminReply: r.adminReply,
    serviceName: r.service?.name ?? 'Unknown Service',
    createdAt: r.createdAt,
  };
}

module.exports = router;
