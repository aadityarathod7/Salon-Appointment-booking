const mongoose = require('mongoose');

const recurringBookingSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    artist: { type: mongoose.Schema.Types.ObjectId, ref: 'Artist', required: true },
    service: { type: mongoose.Schema.Types.ObjectId, ref: 'Service', required: true },
    dayOfWeek: { type: Number, required: true, min: 0, max: 6 },
    startTime: { type: String, required: true },
    frequency: { type: String, enum: ['WEEKLY', 'BIWEEKLY', 'MONTHLY'], required: true },
    startDate: { type: Date, required: true },
    endDate: { type: Date },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

module.exports = mongoose.model('RecurringBooking', recurringBookingSchema);
