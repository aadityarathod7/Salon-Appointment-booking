const Artist = require('../models/Artist');
const ArtistLeave = require('../models/ArtistLeave');
const SalonTiming = require('../models/SalonTiming');
const Appointment = require('../models/Appointment');
const Service = require('../models/Service');
const { timeToMinutes, minutesToTime } = require('../utils/helpers');

const SLOT_INTERVAL = 30; // minutes

async function getAvailableSlots(artistId, serviceId, dateStr) {
  const artist = await Artist.findById(artistId);
  if (!artist) throw new Error('Artist not found');

  const service = await Service.findById(serviceId);
  if (!service) throw new Error('Service not found');

  // Check custom duration for this artist-service pair
  const artistService = artist.services.find(
    (s) => s.service.toString() === serviceId
  );
  const duration = artistService?.customDuration || service.durationMinutes;

  const date = new Date(dateStr + 'T00:00:00');
  const dayOfWeek = date.getDay(); // 0=Sunday

  // 1. Check salon timing
  const salonTiming = await SalonTiming.findOne({ dayOfWeek });
  if (!salonTiming || salonTiming.isClosed) {
    return { date: dateStr, artistId, serviceId, serviceDuration: duration, slots: [] };
  }

  const salonOpen = timeToMinutes(salonTiming.openTime);
  const salonClose = timeToMinutes(salonTiming.closeTime);

  // 2. Check artist leave
  const startOfDay = new Date(dateStr);
  startOfDay.setHours(0, 0, 0, 0);
  const endOfDay = new Date(dateStr);
  endOfDay.setHours(23, 59, 59, 999);

  const hasLeave = await ArtistLeave.findOne({
    artist: artistId,
    leaveDate: { $gte: startOfDay, $lte: endOfDay },
  });
  if (hasLeave) {
    return { date: dateStr, artistId, serviceId, serviceDuration: duration, slots: [] };
  }

  // 3. Get artist availability for this day
  const availabilities = artist.availability.filter((a) => a.dayOfWeek === dayOfWeek);
  if (availabilities.length === 0) {
    return { date: dateStr, artistId, serviceId, serviceDuration: duration, slots: [] };
  }

  // 4. Get artist breaks for this day
  const breaks = artist.breaks.filter((b) => b.dayOfWeek === dayOfWeek);

  // 5. Get existing appointments
  const existingAppointments = await Appointment.find({
    artist: artistId,
    appointmentDate: { $gte: startOfDay, $lte: endOfDay },
    status: { $nin: ['CANCELLED', 'REJECTED', 'NO_SHOW'] },
  });

  // 6. Compute available windows
  const availableWindows = [];

  for (const avail of availabilities) {
    const windowStart = Math.max(timeToMinutes(avail.startTime), salonOpen);
    const windowEnd = Math.min(timeToMinutes(avail.endTime), salonClose);

    if (windowStart >= windowEnd) continue;

    // Subtract breaks
    const windows = subtractBreaks(windowStart, windowEnd, breaks);
    availableWindows.push(...windows);
  }

  // 7. Filter out past slots if date is today
  const now = new Date();
  const isToday = date.toDateString() === now.toDateString();
  const currentMinutes = isToday ? now.getHours() * 60 + now.getMinutes() : 0;

  // 8. Generate slots
  const slots = [];
  for (const [wStart, wEnd] of availableWindows) {
    let slotStart = wStart;
    while (slotStart + duration <= wEnd) {
      const slotEnd = slotStart + duration;

      // Skip past slots for today
      if (isToday && slotStart <= currentMinutes) {
        slotStart += SLOT_INTERVAL;
        continue;
      }

      // Check overlap with existing appointments
      const isBooked = existingAppointments.some((apt) => {
        const aptStart = timeToMinutes(apt.startTime);
        const aptEnd = timeToMinutes(apt.endTime);
        return aptStart < slotEnd && aptEnd > slotStart;
      });

      slots.push({
        startTime: minutesToTime(slotStart),
        endTime: minutesToTime(slotEnd),
        available: !isBooked,
      });

      slotStart += SLOT_INTERVAL;
    }
  }

  return { date: dateStr, artistId, serviceId, serviceDuration: duration, slots };
}

function subtractBreaks(windowStart, windowEnd, breaks) {
  if (breaks.length === 0) return [[windowStart, windowEnd]];

  const relevantBreaks = breaks
    .filter((b) => {
      const bs = timeToMinutes(b.breakStart);
      const be = timeToMinutes(b.breakEnd);
      return bs < windowEnd && be > windowStart;
    })
    .sort((a, b) => timeToMinutes(a.breakStart) - timeToMinutes(b.breakStart));

  const windows = [];
  let current = windowStart;

  for (const brk of relevantBreaks) {
    const bs = Math.max(timeToMinutes(brk.breakStart), windowStart);
    const be = Math.min(timeToMinutes(brk.breakEnd), windowEnd);

    if (current < bs) {
      windows.push([current, bs]);
    }
    current = be;
  }

  if (current < windowEnd) {
    windows.push([current, windowEnd]);
  }

  return windows;
}

module.exports = { getAvailableSlots };
