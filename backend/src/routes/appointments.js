const express = require('express');
const mongoose = require('mongoose');
const Appointment = require('../models/Appointment');
const Artist = require('../models/Artist');
const Service = require('../models/Service');
const { Coupon, CouponUsage } = require('../models/Coupon');
const { auth } = require('../middleware/auth');
const { apiResponse, generateBookingRef, timeToMinutes } = require('../utils/helpers');

const router = express.Router();

// POST /appointments - Create booking
router.post('/', auth, async (req, res, next) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const { serviceId, artistId, date, startTime, paymentMethod, couponCode, notes } = req.body;

    const artist = await Artist.findById(artistId).session(session);
    if (!artist || !artist.isActive) {
      throw Object.assign(new Error('Artist not available'), { statusCode: 400 });
    }

    const service = await Service.findById(serviceId).session(session);
    if (!service || !service.isActive) {
      throw Object.assign(new Error('Service not available'), { statusCode: 400 });
    }

    // Get duration (check custom)
    const artistService = artist.services.find((s) => s.service.toString() === serviceId);
    const duration = artistService?.customDuration || service.durationMinutes;
    const price = artistService?.customPrice || service.price;

    const startMins = timeToMinutes(startTime);
    const endMins = startMins + duration;
    const endTime = `${String(Math.floor(endMins / 60)).padStart(2, '0')}:${String(endMins % 60).padStart(2, '0')}`;

    // Validate date not in past
    const appointmentDate = new Date(date);
    if (appointmentDate < new Date().setHours(0, 0, 0, 0)) {
      throw Object.assign(new Error('Cannot book in the past'), { statusCode: 400 });
    }

    // Check for overlapping appointments (within transaction for atomicity)
    const startOfDay = new Date(date);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(date);
    endOfDay.setHours(23, 59, 59, 999);

    const overlapping = await Appointment.find({
      artist: artistId,
      appointmentDate: { $gte: startOfDay, $lte: endOfDay },
      status: { $ne: 'CANCELLED' },
    }).session(session);

    const hasConflict = overlapping.some((apt) => {
      const aptStart = timeToMinutes(apt.startTime);
      const aptEnd = timeToMinutes(apt.endTime);
      return aptStart < endMins && aptEnd > startMins;
    });

    if (hasConflict) {
      throw Object.assign(new Error('The selected slot is no longer available'), { statusCode: 409 });
    }

    // Apply coupon
    let finalPrice = price;
    let couponDoc = null;

    if (couponCode) {
      couponDoc = await Coupon.findOne({ code: couponCode.toUpperCase() }).session(session);
      if (couponDoc) {
        const validation = validateCoupon(couponDoc, req.userId, price);
        if (validation.valid) {
          finalPrice = price - validation.discount;
          if (finalPrice < 0) finalPrice = 0;
          couponDoc.usedCount += 1;
          await couponDoc.save({ session });
        }
      }
    }

    const bookingRef = generateBookingRef(date);

    const appointment = new Appointment({
      bookingRef,
      user: req.userId,
      artist: artistId,
      service: serviceId,
      appointmentDate,
      startTime,
      endTime,
      status: paymentMethod === 'PAY_AT_SALON' ? 'CONFIRMED' : 'PENDING',
      notes,
      originalPrice: price,
      finalPrice,
      coupon: couponDoc?._id,
      paymentMethod,
      paymentStatus: 'PENDING',
    });

    await appointment.save({ session });

    if (couponDoc) {
      await new CouponUsage({
        coupon: couponDoc._id,
        user: req.userId,
        appointment: appointment._id,
      }).save({ session });
    }

    await session.commitTransaction();

    const populated = await Appointment.findById(appointment._id)
      .populate('artist', 'name phone email profileImageUrl bio experienceYears avgRating totalReviews isActive')
      .populate('service', 'name description durationMinutes price category imageUrl');

    res.status(201).json(apiResponse(formatAppointment(populated), 'Booking created'));
  } catch (err) {
    await session.abortTransaction();
    next(err);
  } finally {
    session.endSession();
  }
});

// GET /appointments
router.get('/', auth, async (req, res, next) => {
  try {
    const { status, page = 0, size = 20 } = req.query;

    const filter = { user: req.userId };
    if (status === 'UPCOMING') {
      filter.status = { $in: ['PENDING', 'CONFIRMED'] };
    } else if (status === 'PAST') {
      filter.status = { $in: ['COMPLETED', 'CANCELLED', 'NO_SHOW'] };
    }

    const [appointments, total] = await Promise.all([
      Appointment.find(filter)
        .populate('artist', 'name phone email profileImageUrl bio experienceYears avgRating totalReviews isActive')
        .populate('service', 'name description durationMinutes price category imageUrl')
        .sort({ appointmentDate: -1, startTime: -1 })
        .skip(parseInt(page) * parseInt(size))
        .limit(parseInt(size)),
      Appointment.countDocuments(filter),
    ]);

    res.json(
      apiResponse({
        content: appointments.map(formatAppointment),
        totalElements: total,
        totalPages: Math.ceil(total / parseInt(size)),
        number: parseInt(page),
        size: parseInt(size),
      })
    );
  } catch (err) {
    next(err);
  }
});

// GET /appointments/:id
router.get('/:id', auth, async (req, res, next) => {
  try {
    const appointment = await Appointment.findOne({ _id: req.params.id, user: req.userId })
      .populate('artist', 'name phone email profileImageUrl bio experienceYears avgRating totalReviews isActive')
      .populate('service', 'name description durationMinutes price category imageUrl');

    if (!appointment) return res.status(404).json({ success: false, message: 'Appointment not found' });
    res.json(apiResponse(formatAppointment(appointment)));
  } catch (err) {
    next(err);
  }
});

// PUT /appointments/:id/cancel
router.put('/:id/cancel', auth, async (req, res, next) => {
  try {
    const appointment = await Appointment.findOne({ _id: req.params.id, user: req.userId })
      .populate('artist', 'name phone email profileImageUrl bio experienceYears avgRating totalReviews isActive')
      .populate('service', 'name description durationMinutes price category imageUrl');

    if (!appointment) return res.status(404).json({ success: false, message: 'Appointment not found' });

    if (appointment.status === 'CANCELLED') {
      return res.status(400).json({ success: false, message: 'Already cancelled' });
    }
    if (appointment.status === 'COMPLETED') {
      return res.status(400).json({ success: false, message: 'Cannot cancel a completed appointment' });
    }

    appointment.status = 'CANCELLED';
    appointment.cancellationReason = req.body.reason || null;
    appointment.cancelledBy = 'CUSTOMER';
    appointment.cancelledAt = new Date();
    await appointment.save();

    res.json(apiResponse(formatAppointment(appointment), 'Appointment cancelled'));
  } catch (err) {
    next(err);
  }
});

// PUT /appointments/:id/reschedule
router.put('/:id/reschedule', auth, async (req, res, next) => {
  try {
    const { date, startTime } = req.body;
    const appointment = await Appointment.findOne({ _id: req.params.id, user: req.userId });

    if (!appointment) return res.status(404).json({ success: false, message: 'Appointment not found' });

    if (!['CONFIRMED', 'PENDING'].includes(appointment.status)) {
      return res.status(400).json({ success: false, message: 'Can only reschedule pending or confirmed appointments' });
    }

    const duration = timeToMinutes(appointment.endTime) - timeToMinutes(appointment.startTime);
    const newEndMins = timeToMinutes(startTime) + duration;
    const newEndTime = `${String(Math.floor(newEndMins / 60)).padStart(2, '0')}:${String(newEndMins % 60).padStart(2, '0')}`;

    // Check overlap
    const startOfDay = new Date(date);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(date);
    endOfDay.setHours(23, 59, 59, 999);

    const overlapping = await Appointment.find({
      _id: { $ne: appointment._id },
      artist: appointment.artist,
      appointmentDate: { $gte: startOfDay, $lte: endOfDay },
      status: { $ne: 'CANCELLED' },
    });

    const hasConflict = overlapping.some((apt) => {
      const aptStart = timeToMinutes(apt.startTime);
      const aptEnd = timeToMinutes(apt.endTime);
      return aptStart < newEndMins && aptEnd > timeToMinutes(startTime);
    });

    if (hasConflict) {
      return res.status(409).json({ success: false, message: 'The selected slot is no longer available' });
    }

    appointment.appointmentDate = new Date(date);
    appointment.startTime = startTime;
    appointment.endTime = newEndTime;
    await appointment.save();

    const populated = await Appointment.findById(appointment._id)
      .populate('artist', 'name phone email profileImageUrl bio experienceYears avgRating totalReviews isActive')
      .populate('service', 'name description durationMinutes price category imageUrl');

    res.json(apiResponse(formatAppointment(populated), 'Appointment rescheduled'));
  } catch (err) {
    next(err);
  }
});

function validateCoupon(coupon, userId, orderAmount) {
  const now = new Date();
  if (!coupon.isActive) return { valid: false };
  if (now < coupon.validFrom || now > coupon.validUntil) return { valid: false };
  if (coupon.maxUses && coupon.usedCount >= coupon.maxUses) return { valid: false };
  if (coupon.minOrderAmount && orderAmount < coupon.minOrderAmount) return { valid: false };

  let discount;
  if (coupon.discountType === 'FLAT') {
    discount = coupon.discountValue;
  } else {
    discount = (orderAmount * coupon.discountValue) / 100;
  }
  if (coupon.maxDiscount) discount = Math.min(discount, coupon.maxDiscount);

  return { valid: true, discount };
}

function formatAppointment(apt) {
  const obj = apt.toObject ? apt.toObject() : apt;
  return {
    id: obj._id,
    bookingRef: obj.bookingRef,
    artist: {
      id: obj.artist._id || obj.artist,
      name: obj.artist.name,
      phone: obj.artist.phone,
      email: obj.artist.email,
      profileImageUrl: obj.artist.profileImageUrl,
      bio: obj.artist.bio,
      experienceYears: obj.artist.experienceYears,
      avgRating: obj.artist.avgRating,
      totalReviews: obj.artist.totalReviews,
      isActive: obj.artist.isActive,
    },
    service: {
      id: obj.service._id || obj.service,
      name: obj.service.name,
      description: obj.service.description,
      durationMinutes: obj.service.durationMinutes,
      price: obj.service.price,
      category: obj.service.category,
      imageUrl: obj.service.imageUrl,
    },
    appointmentDate: obj.appointmentDate?.toISOString?.()?.slice(0, 10) || obj.appointmentDate,
    startTime: obj.startTime,
    endTime: obj.endTime,
    status: obj.status,
    originalPrice: obj.originalPrice,
    finalPrice: obj.finalPrice,
    notes: obj.notes,
    couponCode: null,
    paymentMethod: obj.paymentMethod,
    paymentStatus: obj.paymentStatus,
    createdAt: obj.createdAt,
  };
}

module.exports = router;
