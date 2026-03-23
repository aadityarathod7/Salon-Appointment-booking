const express = require('express');
const Artist = require('../models/Artist');
const Review = require('../models/Review');
const { apiResponse } = require('../utils/helpers');

const router = express.Router();

// GET /artists
router.get('/', async (req, res, next) => {
  try {
    const artists = await Artist.find({ isActive: true })
      .populate('services.service')
      .sort({ sortOrder: 1 });
    res.json(apiResponse(artists));
  } catch (err) {
    next(err);
  }
});

// GET /artists/:id
router.get('/:id', async (req, res, next) => {
  try {
    const artist = await Artist.findById(req.params.id).populate('services.service');
    if (!artist) return res.status(404).json({ success: false, message: 'Artist not found' });
    res.json(apiResponse(artist));
  } catch (err) {
    next(err);
  }
});

// GET /artists/:id/reviews
router.get('/:id/reviews', async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 0;
    const size = parseInt(req.query.size) || 20;

    const [reviews, total] = await Promise.all([
      Review.find({ artist: req.params.id })
        .populate('user', 'name profileImageUrl')
        .populate('service', 'name')
        .sort({ createdAt: -1 })
        .skip(page * size)
        .limit(size),
      Review.countDocuments({ artist: req.params.id }),
    ]);

    const content = reviews.map((r) => ({
      id: r._id,
      userName: r.user.name,
      userProfileImage: r.user.profileImageUrl,
      rating: r.rating,
      comment: r.comment,
      adminReply: r.adminReply,
      serviceName: r.service.name,
      createdAt: r.createdAt,
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

// GET /artists/:id/services
router.get('/:id/services', async (req, res, next) => {
  try {
    const artist = await Artist.findById(req.params.id).populate('services.service');
    if (!artist) return res.status(404).json({ success: false, message: 'Artist not found' });

    const services = artist.services.map((as) => ({
      id: as.service._id,
      name: as.service.name,
      description: as.service.description,
      durationMinutes: as.customDuration || as.service.durationMinutes,
      price: as.customPrice || as.service.price,
      category: as.service.category,
      imageUrl: as.service.imageUrl,
    }));

    res.json(apiResponse(services));
  } catch (err) {
    next(err);
  }
});

module.exports = router;
