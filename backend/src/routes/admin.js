const express = require('express');
const Artist = require('../models/Artist');
const ArtistLeave = require('../models/ArtistLeave');
const Service = require('../models/Service');
const Appointment = require('../models/Appointment');
const SalonTiming = require('../models/SalonTiming');
const { Coupon } = require('../models/Coupon');
const User = require('../models/User');
const { auth, adminOnly } = require('../middleware/auth');
const { apiResponse } = require('../utils/helpers');

const router = express.Router();
router.use(auth, adminOnly);

// ── Dashboard ──
router.get('/dashboard', async (req, res, next) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const [todayBookings, todayRevenue, activeArtists, totalCustomers, recentBookings, peakHours] =
      await Promise.all([
        Appointment.countDocuments({
          appointmentDate: { $gte: today, $lt: tomorrow },
          status: { $ne: 'CANCELLED' },
        }),
        Appointment.aggregate([
          {
            $match: {
              appointmentDate: { $gte: today, $lt: tomorrow },
              status: 'COMPLETED',
            },
          },
          { $group: { _id: null, total: { $sum: '$finalPrice' } } },
        ]),
        Artist.countDocuments({ isActive: true }),
        User.countDocuments({ isActive: true, role: 'CUSTOMER' }),
        Appointment.find({
          appointmentDate: { $gte: today, $lt: tomorrow },
          status: { $in: ['CONFIRMED', 'PENDING', 'IN_PROGRESS'] },
        })
          .populate('artist', 'name')
          .populate('service', 'name')
          .limit(10)
          .sort({ startTime: 1 }),
        Appointment.aggregate([
          {
            $match: {
              appointmentDate: {
                $gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
              },
              status: { $ne: 'CANCELLED' },
            },
          },
          {
            $group: {
              _id: { $substr: ['$startTime', 0, 2] },
              count: { $sum: 1 },
            },
          },
          { $sort: { count: -1 } },
        ]),
      ]);

    res.json(
      apiResponse({
        todayBookings,
        todayRevenue: todayRevenue[0]?.total || 0,
        activeArtists,
        totalCustomers,
        recentBookings,
        peakHours: peakHours.map((p) => ({ hour: parseInt(p._id), bookingCount: p.count })),
      })
    );
  } catch (err) {
    next(err);
  }
});

// ── Artist Management ──
router.post('/artists', async (req, res, next) => {
  try {
    const artist = new Artist(req.body);
    await artist.save();
    res.status(201).json(apiResponse(artist, 'Artist created'));
  } catch (err) {
    next(err);
  }
});

router.put('/artists/:id', async (req, res, next) => {
  try {
    const artist = await Artist.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!artist) return res.status(404).json({ success: false, message: 'Artist not found' });
    res.json(apiResponse(artist, 'Artist updated'));
  } catch (err) {
    next(err);
  }
});

router.delete('/artists/:id', async (req, res, next) => {
  try {
    await Artist.findByIdAndUpdate(req.params.id, { isActive: false });
    res.json(apiResponse(null, 'Artist deactivated'));
  } catch (err) {
    next(err);
  }
});

// Set artist availability
router.put('/artists/:id/availability', async (req, res, next) => {
  try {
    const artist = await Artist.findById(req.params.id);
    if (!artist) return res.status(404).json({ success: false, message: 'Artist not found' });
    artist.availability = req.body.schedules;
    await artist.save();
    res.json(apiResponse(null, 'Availability updated'));
  } catch (err) {
    next(err);
  }
});

// Set artist breaks
router.put('/artists/:id/breaks', async (req, res, next) => {
  try {
    const artist = await Artist.findById(req.params.id);
    if (!artist) return res.status(404).json({ success: false, message: 'Artist not found' });
    artist.breaks = req.body.breaks;
    await artist.save();
    res.json(apiResponse(null, 'Breaks updated'));
  } catch (err) {
    next(err);
  }
});

// Add artist leave
router.post('/artists/:id/leaves', async (req, res, next) => {
  try {
    const leave = new ArtistLeave({
      artist: req.params.id,
      leaveDate: new Date(req.body.leaveDate),
      reason: req.body.reason,
    });
    await leave.save();
    res.status(201).json(apiResponse(leave, 'Leave added'));
  } catch (err) {
    next(err);
  }
});

router.delete('/artists/:id/leaves/:leaveId', async (req, res, next) => {
  try {
    await ArtistLeave.findByIdAndDelete(req.params.leaveId);
    res.json(apiResponse(null, 'Leave removed'));
  } catch (err) {
    next(err);
  }
});

// Assign services to artist
router.post('/artists/:id/services', async (req, res, next) => {
  try {
    const artist = await Artist.findById(req.params.id);
    if (!artist) return res.status(404).json({ success: false, message: 'Artist not found' });

    artist.services = req.body.services.map((s) => ({
      service: s.serviceId,
      customPrice: s.customPrice,
      customDuration: s.customDuration,
    }));
    await artist.save();
    res.json(apiResponse(null, 'Services assigned'));
  } catch (err) {
    next(err);
  }
});

// ── Service Management ──
router.post('/services', async (req, res, next) => {
  try {
    const service = new Service(req.body);
    await service.save();
    res.status(201).json(apiResponse(service, 'Service created'));
  } catch (err) {
    next(err);
  }
});

router.put('/services/:id', async (req, res, next) => {
  try {
    const service = await Service.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!service) return res.status(404).json({ success: false, message: 'Service not found' });
    res.json(apiResponse(service, 'Service updated'));
  } catch (err) {
    next(err);
  }
});

router.delete('/services/:id', async (req, res, next) => {
  try {
    await Service.findByIdAndUpdate(req.params.id, { isActive: false });
    res.json(apiResponse(null, 'Service deactivated'));
  } catch (err) {
    next(err);
  }
});

// ── Appointment Management ──
router.get('/appointments', async (req, res, next) => {
  try {
    const { date, status, page = 0, size = 20 } = req.query;
    const filter = {};

    if (date) {
      const d = new Date(date);
      d.setHours(0, 0, 0, 0);
      const next = new Date(d);
      next.setDate(next.getDate() + 1);
      filter.appointmentDate = { $gte: d, $lt: next };
    }
    if (status) filter.status = status;

    const [appointments, total] = await Promise.all([
      Appointment.find(filter)
        .populate('user', 'name email phone')
        .populate('artist', 'name')
        .populate('service', 'name price durationMinutes')
        .sort({ appointmentDate: -1, startTime: -1 })
        .skip(parseInt(page) * parseInt(size))
        .limit(parseInt(size)),
      Appointment.countDocuments(filter),
    ]);

    res.json(
      apiResponse({
        content: appointments,
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

router.put('/appointments/:id/status', async (req, res, next) => {
  try {
    const { status } = req.body;

    // Validate status transition
    const appointment = await Appointment.findById(req.params.id);
    if (!appointment) return res.status(404).json({ success: false, message: 'Appointment not found' });

    const validTransitions = {
      PENDING: ['CONFIRMED', 'CANCELLED'],
      CONFIRMED: ['IN_PROGRESS', 'CANCELLED', 'NO_SHOW'],
      IN_PROGRESS: ['COMPLETED', 'CANCELLED', 'NO_SHOW'],
      COMPLETED: [],
      CANCELLED: [],
      NO_SHOW: [],
    };

    const allowed = validTransitions[appointment.status] || [];
    if (!allowed.includes(status)) {
      return res.status(400).json({
        success: false,
        message: `Cannot change status from ${appointment.status} to ${status}`,
      });
    }

    appointment.status = status;
    if (status === 'CANCELLED') {
      appointment.cancelledBy = 'ADMIN';
      appointment.cancelledAt = new Date();
    }
    await appointment.save();

    const populated = await Appointment.findById(appointment._id)
      .populate('artist', 'name')
      .populate('service', 'name');
    res.json(apiResponse(populated, 'Status updated'));
  } catch (err) {
    next(err);
  }
});

// ── Coupon Management ──
router.get('/coupons', async (req, res, next) => {
  try {
    const coupons = await Coupon.find().sort({ createdAt: -1 });
    res.json(apiResponse(coupons));
  } catch (err) {
    next(err);
  }
});

router.post('/coupons', async (req, res, next) => {
  try {
    const coupon = new Coupon(req.body);
    await coupon.save();
    res.status(201).json(apiResponse(coupon, 'Coupon created'));
  } catch (err) {
    next(err);
  }
});

router.put('/coupons/:id', async (req, res, next) => {
  try {
    const coupon = await Coupon.findByIdAndUpdate(req.params.id, req.body, { new: true });
    res.json(apiResponse(coupon, 'Coupon updated'));
  } catch (err) {
    next(err);
  }
});

router.delete('/coupons/:id', async (req, res, next) => {
  try {
    await Coupon.findByIdAndDelete(req.params.id);
    res.json(apiResponse(null, 'Coupon deleted'));
  } catch (err) {
    next(err);
  }
});

// ── Salon Timings ──
router.get('/settings/timings', async (req, res, next) => {
  try {
    const timings = await SalonTiming.find().sort({ dayOfWeek: 1 });
    res.json(apiResponse(timings));
  } catch (err) {
    next(err);
  }
});

router.put('/settings/timings', async (req, res, next) => {
  try {
    for (const t of req.body.timings) {
      await SalonTiming.findOneAndUpdate(
        { dayOfWeek: t.dayOfWeek },
        { openTime: t.openTime, closeTime: t.closeTime, isClosed: t.isClosed },
        { upsert: true }
      );
    }
    res.json(apiResponse(null, 'Timings updated'));
  } catch (err) {
    next(err);
  }
});

// ── Reports ──
router.get('/reports/revenue', async (req, res, next) => {
  try {
    const { startDate, endDate } = req.query;
    const start = startDate ? new Date(startDate) : new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const end = endDate ? new Date(endDate) : new Date();

    const revenue = await Appointment.aggregate([
      {
        $match: {
          appointmentDate: { $gte: start, $lte: end },
          status: 'COMPLETED',
        },
      },
      {
        $group: {
          _id: { $dateToString: { format: '%Y-%m-%d', date: '$appointmentDate' } },
          revenue: { $sum: '$finalPrice' },
          bookingCount: { $sum: 1 },
        },
      },
      { $sort: { _id: 1 } },
    ]);

    const totalRevenue = revenue.reduce((sum, r) => sum + r.revenue, 0);
    res.json(
      apiResponse({
        totalRevenue,
        period: `${start.toISOString().slice(0, 10)} to ${end.toISOString().slice(0, 10)}`,
        breakdown: revenue.map((r) => ({
          date: r._id,
          revenue: r.revenue,
          bookingCount: r.bookingCount,
        })),
      })
    );
  } catch (err) {
    next(err);
  }
});

router.get('/reports/artists', async (req, res, next) => {
  try {
    const artistStats = await Appointment.aggregate([
      { $match: { status: 'COMPLETED' } },
      {
        $group: {
          _id: '$artist',
          totalBookings: { $sum: 1 },
          totalRevenue: { $sum: '$finalPrice' },
        },
      },
      {
        $lookup: { from: 'artists', localField: '_id', foreignField: '_id', as: 'artist' },
      },
      { $unwind: '$artist' },
      {
        $project: {
          name: '$artist.name',
          avgRating: '$artist.avgRating',
          totalBookings: 1,
          totalRevenue: 1,
        },
      },
      { $sort: { totalRevenue: -1 } },
    ]);

    res.json(apiResponse(artistStats));
  } catch (err) {
    next(err);
  }
});

router.get('/reports/services', async (req, res, next) => {
  try {
    const serviceStats = await Appointment.aggregate([
      { $match: { status: { $ne: 'CANCELLED' } } },
      {
        $group: {
          _id: '$service',
          totalBookings: { $sum: 1 },
          totalRevenue: { $sum: '$finalPrice' },
        },
      },
      {
        $lookup: { from: 'services', localField: '_id', foreignField: '_id', as: 'service' },
      },
      { $unwind: '$service' },
      {
        $project: {
          name: '$service.name',
          category: '$service.category',
          totalBookings: 1,
          totalRevenue: 1,
        },
      },
      { $sort: { totalBookings: -1 } },
    ]);

    res.json(apiResponse(serviceStats));
  } catch (err) {
    next(err);
  }
});

module.exports = router;
