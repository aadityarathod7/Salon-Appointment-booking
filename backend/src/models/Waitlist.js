const mongoose = require('mongoose');

const waitlistSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    artist: { type: mongoose.Schema.Types.ObjectId, ref: 'Artist', required: true },
    service: { type: mongoose.Schema.Types.ObjectId, ref: 'Service', required: true },
    preferredDate: { type: Date, required: true },
    preferredTimeStart: { type: String },
    preferredTimeEnd: { type: String },
    status: { type: String, enum: ['WAITING', 'NOTIFIED', 'BOOKED', 'EXPIRED'], default: 'WAITING' },
    notifiedAt: { type: Date },
  },
  { timestamps: true }
);

waitlistSchema.index({ artist: 1, preferredDate: 1, status: 1 });

module.exports = mongoose.model('Waitlist', waitlistSchema);
