const express = require('express');
const { Coupon, CouponUsage } = require('../models/Coupon');
const { auth } = require('../middleware/auth');
const { apiResponse } = require('../utils/helpers');

const router = express.Router();

// POST /coupons/validate
router.post('/validate', auth, async (req, res, next) => {
  try {
    const { code, serviceId } = req.body;
    const coupon = await Coupon.findOne({ code: code.toUpperCase() });

    if (!coupon) {
      return res.json(apiResponse({ valid: false, discountAmount: null, message: 'Invalid coupon code' }));
    }

    const now = new Date();
    if (!coupon.isActive) {
      return res.json(apiResponse({ valid: false, discountAmount: null, message: 'Coupon is not active' }));
    }
    if (now < coupon.validFrom) {
      return res.json(apiResponse({ valid: false, discountAmount: null, message: 'Coupon is not yet valid' }));
    }
    if (now > coupon.validUntil) {
      return res.json(apiResponse({ valid: false, discountAmount: null, message: 'Coupon has expired' }));
    }
    if (coupon.maxUses && coupon.usedCount >= coupon.maxUses) {
      return res.json(apiResponse({ valid: false, discountAmount: null, message: 'Coupon usage limit reached' }));
    }

    const userUsageCount = await CouponUsage.countDocuments({ coupon: coupon._id, user: req.userId });
    if (userUsageCount >= coupon.perUserLimit) {
      return res.json(apiResponse({ valid: false, discountAmount: null, message: 'You have already used this coupon' }));
    }

    // We don't know the exact order amount here, so we return the discount info
    res.json(
      apiResponse({
        valid: true,
        discountAmount: coupon.discountValue,
        discountType: coupon.discountType,
        maxDiscount: coupon.maxDiscount,
        message: 'Coupon is valid',
      })
    );
  } catch (err) {
    next(err);
  }
});

module.exports = router;
