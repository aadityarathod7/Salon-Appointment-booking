const mongoose = require('mongoose');

const appointmentSchema = new mongoose.Schema(
  {
    bookingRef: { type: String, required: true, unique: true },
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    artist: { type: mongoose.Schema.Types.ObjectId, ref: 'Artist', required: true },
    service: { type: mongoose.Schema.Types.ObjectId, ref: 'Service', required: true },
    appointmentDate: { type: Date, required: true },
    startTime: { type: String, required: true }, // "14:00"
    endTime: { type: String, required: true },   // "14:45"
    status: {
      type: String,
      enum: ['PENDING', 'CONFIRMED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'NO_SHOW'],
      default: 'PENDING',
    },
    cancellationReason: { type: String },
    cancelledBy: { type: String, enum: ['CUSTOMER', 'ADMIN'] },
    cancelledAt: { type: Date },
    notes: { type: String },
    originalPrice: { type: Number, required: true },
    finalPrice: { type: Number, required: true },
    coupon: { type: mongoose.Schema.Types.ObjectId, ref: 'Coupon' },
    recurringBooking: { type: mongoose.Schema.Types.ObjectId, ref: 'RecurringBooking' },
    paymentMethod: { type: String, enum: ['UPI', 'CARD', 'PAY_AT_SALON'], required: true },
    paymentStatus: { type: String, enum: ['PENDING', 'COMPLETED', 'FAILED', 'REFUNDED'], default: 'PENDING' },
    transactionId: { type: String },
  },
  { timestamps: true }
);

appointmentSchema.index({ artist: 1, appointmentDate: 1, status: 1 });
appointmentSchema.index({ user: 1, status: 1 });
appointmentSchema.index({ appointmentDate: 1, status: 1 });

module.exports = mongoose.model('Appointment', appointmentSchema);
