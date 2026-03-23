const express = require('express');
const Service = require('../models/Service');
const Artist = require('../models/Artist');
const { apiResponse } = require('../utils/helpers');

const router = express.Router();

// GET /services
router.get('/', async (req, res, next) => {
  try {
    const filter = { isActive: true };
    if (req.query.category) filter.category = req.query.category;

    const services = await Service.find(filter).sort({ sortOrder: 1 });
    res.json(apiResponse(services));
  } catch (err) {
    next(err);
  }
});

// GET /services/:id
router.get('/:id', async (req, res, next) => {
  try {
    const service = await Service.findById(req.params.id);
    if (!service) return res.status(404).json({ success: false, message: 'Service not found' });
    res.json(apiResponse(service));
  } catch (err) {
    next(err);
  }
});

// GET /services/:id/artists
router.get('/:id/artists', async (req, res, next) => {
  try {
    const artists = await Artist.find({
      isActive: true,
      'services.service': req.params.id,
    })
      .populate('services.service')
      .select('-availability -breaks')
      .sort({ sortOrder: 1 });

    res.json(apiResponse(artists));
  } catch (err) {
    next(err);
  }
});

module.exports = router;
