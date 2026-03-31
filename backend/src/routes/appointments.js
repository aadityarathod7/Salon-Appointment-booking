const express = require('express');
const mongoose = require('mongoose');
const Appointment = require('../models/Appointment');
const Artist = require('../models/Artist');
const Service = require('../models/Service');
const { Coupon, CouponUsage } = require('../models/Coupon');
const Waitlist = require('../models/Waitlist');
const Notification = require('../models/Notification');
const { notify, notifyAllAdmins } = require('../services/notificationService');
const { auth } = require('../middleware/auth');
const { apiResponse, generateBookingRef, timeToMinutes } = require('../utils/helpers');

const router = express.Router();

// POST /appointments - Create booking
router.post('/', auth, async (req, res, next) => {
  try {
    const { serviceId, artistId, date, startTime, paymentMethod, couponCode, notes } = req.body;

    const artist = await Artist.findById(artistId);
    if (!artist || !artist.isActive) {
      return res.status(400).json({ success: false, message: 'Artist not available' });
    }

    const service = await Service.findById(serviceId);
    if (!service || !service.isActive) {
      return res.status(400).json({ success: false, message: 'Service not available' });
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
      return res.status(400).json({ success: false, message: 'Cannot book in the past' });
    }

    // Check for overlapping appointments (artist conflict)
    const startOfDay = new Date(date);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(date);
    endOfDay.setHours(23, 59, 59, 999);

    const existing = await Appointment.find({
      artist: artistId,
      appointmentDate: { $gte: startOfDay, $lte: endOfDay },
      status: { $nin: ['CANCELLED', 'NO_SHOW'] },
    });

    const hasConflict = existing.some((apt) => {
      const aptStart = timeToMinutes(apt.startTime);
      const aptEnd = timeToMinutes(apt.endTime);
      return aptStart < endMins && aptEnd > startMins;
    });

    if (hasConflict) {
      return res.status(409).json({ success: false, message: 'The selected slot is no longer available' });
    }

    // Check if same user already has a booking at overlapping time (any artist)
    const userExisting = await Appointment.find({
      user: req.userId,
      appointmentDate: { $gte: startOfDay, $lte: endOfDay },
      status: { $nin: ['CANCELLED', 'NO_SHOW'] },
    });

    const userConflict = userExisting.some((apt) => {
      const aptStart = timeToMinutes(apt.startTime);
      const aptEnd = timeToMinutes(apt.endTime);
      return aptStart < endMins && aptEnd > startMins;
    });

    if (userConflict) {
      return res.status(409).json({ success: false, message: 'You already have a booking at this time' });
    }

    // Apply coupon
    let finalPrice = price;
    let couponDoc = null;

    if (couponCode) {
      couponDoc = await Coupon.findOne({ code: couponCode.toUpperCase() });
      if (couponDoc) {
        const validation = validateCoupon(couponDoc, req.userId, price);
        if (validation.valid) {
          finalPrice = price - validation.discount;
          if (finalPrice < 0) finalPrice = 0;
          couponDoc.usedCount += 1;
          await couponDoc.save();
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
      status: 'PENDING',
      notes,
      originalPrice: price,
      finalPrice,
      coupon: couponDoc?._id,
      paymentMethod,
      paymentStatus: 'PENDING',
    });

    await appointment.save();

    if (couponDoc) {
      await new CouponUsage({
        coupon: couponDoc._id,
        user: req.userId,
        appointment: appointment._id,
      }).save();
    }

    const populated = await Appointment.findById(appointment._id)
      .populate('artist', 'name phone email profileImageUrl bio experienceYears avgRating totalReviews isActive')
      .populate('service', 'name description durationMinutes price category imageUrl');

    // Notify customer — booking received
    notify(req.userId, {
      title: 'Booking Received',
      body: `Your booking for ${service.name} on ${date} at ${startTime} has been received. Waiting for confirmation.`,
      type: 'NEW_BOOKING',
      referenceId: appointment._id,
    });

    // Notify all admins — new booking
    notifyAllAdmins({
      title: 'New Booking',
      body: `New booking for ${service.name} with ${artist.name} on ${date} at ${startTime}. Ref: ${bookingRef}`,
      type: 'NEW_BOOKING',
      referenceId: appointment._id,
    });

    res.status(201).json(apiResponse(formatAppointment(populated), 'Booking created'));
  } catch (err) {
    next(err);
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
      filter.status = { $in: ['COMPLETED', 'CANCELLED', 'REJECTED', 'NO_SHOW'] };
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

    const dateStr = appointment.appointmentDate?.toISOString?.()?.slice(0, 10) || '';

    // Notify admins about cancellation
    notifyAllAdmins({
      title: 'Booking Cancelled',
      body: `Booking ${appointment.bookingRef} for ${appointment.service.name} on ${dateStr} at ${appointment.startTime} was cancelled by customer.`,
      type: 'BOOKING_CANCELLED',
      referenceId: appointment._id,
    });

    // Notify waitlisted users for this artist/date
    const startOfDay = new Date(appointment.appointmentDate);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(appointment.appointmentDate);
    endOfDay.setHours(23, 59, 59, 999);

    const waitlistEntries = await Waitlist.find({
      artist: appointment.artist._id || appointment.artist,
      preferredDate: { $gte: startOfDay, $lte: endOfDay },
      status: 'WAITING',
    }).populate('user');

    for (const entry of waitlistEntries) {
      entry.status = 'NOTIFIED';
      entry.notifiedAt = new Date();
      await entry.save();

      await new Notification({
        user: entry.user._id,
        title: 'Slot Available!',
        body: `A slot has opened up on ${appointment.appointmentDate.toISOString().slice(0, 10)}. Book now before it fills up!`,
        type: 'WAITLIST_AVAILABLE',
        referenceId: appointment._id,
        sentAt: new Date(),
      }).save();
    }

    res.json(apiResponse(formatAppointment(appointment), 'Appointment cancelled'));
  } catch (err) {
    next(err);
  }
});

// PUT /appointments/:id/reschedule
router.put('/:id/reschedule', auth, async (req, res, next) => {
  try {
    const { date, startTime } = req.body;

    // Validate date not in past
    const newDate = new Date(date);
    if (newDate < new Date().setHours(0, 0, 0, 0)) {
      return res.status(400).json({ success: false, message: 'Cannot reschedule to a past date' });
    }

    const appointment = await Appointment.findOne({ _id: req.params.id, user: req.userId });
    if (!appointment) return res.status(404).json({ success: false, message: 'Appointment not found' });

    if (!['CONFIRMED', 'PENDING'].includes(appointment.status)) {
      return res.status(400).json({ success: false, message: 'Can only reschedule pending or confirmed appointments' });
    }

    const duration = timeToMinutes(appointment.endTime) - timeToMinutes(appointment.startTime);
    const newStartMins = timeToMinutes(startTime);
    const newEndMins = newStartMins + duration;
    const newEndTime = `${String(Math.floor(newEndMins / 60)).padStart(2, '0')}:${String(newEndMins % 60).padStart(2, '0')}`;

    // Validate within salon hours
    const SalonTiming = require('../models/SalonTiming');
    const dayOfWeek = newDate.getDay();
    const salonTiming = await SalonTiming.findOne({ dayOfWeek });
    if (!salonTiming || salonTiming.isClosed) {
      return res.status(400).json({ success: false, message: 'Salon is closed on that day' });
    }
    const salonOpen = timeToMinutes(salonTiming.openTime);
    const salonClose = timeToMinutes(salonTiming.closeTime);
    if (newStartMins < salonOpen || newEndMins > salonClose) {
      return res.status(400).json({ success: false, message: 'Time slot is outside salon hours' });
    }

    // Check overlap with other appointments
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
      return aptStart < newEndMins && aptEnd > newStartMins;
    });

    if (hasConflict) {
      return res.status(409).json({ success: false, message: 'The selected slot is no longer available' });
    }

    appointment.appointmentDate = newDate;
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
