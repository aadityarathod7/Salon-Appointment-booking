const mongoose = require('mongoose');

const salonTimingSchema = new mongoose.Schema({
  dayOfWeek: { type: Number, required: true, unique: true, min: 0, max: 6 },
  openTime: { type: String }, // "09:00"
  closeTime: { type: String }, // "21:00"
  isClosed: { type: Boolean, default: false },
});

module.exports = mongoose.model('SalonTiming', salonTimingSchema);
