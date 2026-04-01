const express = require('express');
const Address = require('../models/Address');
const { auth } = require('../middleware/auth');
const { apiResponse } = require('../utils/helpers');

const router = express.Router();

// GET /addresses
router.get('/', auth, async (req, res, next) => {
  try {
    const addresses = await Address.find({ user: req.userId }).sort({ isDefault: -1, createdAt: -1 });
    res.json(apiResponse(addresses));
  } catch (err) {
    next(err);
  }
});

// POST /addresses
router.post('/', auth, async (req, res, next) => {
  try {
    const { label, addressLine1, addressLine2, city, state, pincode, isDefault } = req.body;
    if (!addressLine1 || !city || !state || !pincode) {
      return res.status(400).json({ success: false, message: 'Address, city, state and pincode are required' });
    }

    if (isDefault) {
      await Address.updateMany({ user: req.userId }, { isDefault: false });
    }

    const address = await Address.create({
      user: req.userId, label, addressLine1, addressLine2, city, state, pincode, isDefault: isDefault || false,
    });
    res.status(201).json(apiResponse(address, 'Address saved'));
  } catch (err) {
    next(err);
  }
});

// PUT /addresses/:id
router.put('/:id', auth, async (req, res, next) => {
  try {
    if (req.body.isDefault) {
      await Address.updateMany({ user: req.userId }, { isDefault: false });
    }
    const address = await Address.findOneAndUpdate(
      { _id: req.params.id, user: req.userId },
      req.body,
      { new: true }
    );
    if (!address) return res.status(404).json({ success: false, message: 'Address not found' });
    res.json(apiResponse(address, 'Address updated'));
  } catch (err) {
    next(err);
  }
});

// DELETE /addresses/:id
router.delete('/:id', auth, async (req, res, next) => {
  try {
    await Address.findOneAndDelete({ _id: req.params.id, user: req.userId });
    res.json(apiResponse(null, 'Address deleted'));
  } catch (err) {
    next(err);
  }
});

module.exports = router;
