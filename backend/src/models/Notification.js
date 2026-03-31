const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    title: { type: String, required: true },
    body: { type: String, required: true },
    type: {
      type: String,
      enum: [
        'NEW_BOOKING', 'BOOKING_CONFIRMED', 'BOOKING_REJECTED', 'BOOKING_CANCELLED',
        'BOOKING_STARTED', 'BOOKING_COMPLETED', 'BOOKING_RESCHEDULED',
        'BOOKING_REMINDER', 'WAITLIST_AVAILABLE', 'PROMOTION',
      ],
      required: true,
    },
    referenceId: { type: mongoose.Schema.Types.ObjectId },
    isRead: { type: Boolean, default: false },
    channel: { type: String, enum: ['PUSH', 'SMS', 'EMAIL'], default: 'PUSH' },
    sentAt: { type: Date },
  },
  { timestamps: true }
);

notificationSchema.index({ user: 1, isRead: 1, createdAt: -1 });

module.exports = mongoose.model('Notification', notificationSchema);
