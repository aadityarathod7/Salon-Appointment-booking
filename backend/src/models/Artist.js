const mongoose = require('mongoose');

const artistSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    phone: { type: String, trim: true },
    email: { type: String, trim: true },
    profileImageUrl: { type: String },
    bio: { type: String },
    experienceYears: { type: Number, default: 0 },
    avgRating: { type: Number, default: 0, min: 0, max: 5 },
    totalReviews: { type: Number, default: 0 },
    isActive: { type: Boolean, default: true },
    sortOrder: { type: Number, default: 0 },

    // Weekly availability
    availability: [
      {
        dayOfWeek: { type: Number, required: true, min: 0, max: 6 }, // 0=Sunday
        startTime: { type: String, required: true }, // "09:00"
        endTime: { type: String, required: true },   // "18:00"
      },
    ],

    // Daily breaks
    breaks: [
      {
        dayOfWeek: { type: Number, required: true, min: 0, max: 6 },
        breakStart: { type: String, required: true },
        breakEnd: { type: String, required: true },
        label: { type: String },
      },
    ],

    // Services this artist offers
    services: [
      {
        service: { type: mongoose.Schema.Types.ObjectId, ref: 'Service', required: true },
        customPrice: { type: Number },
        customDuration: { type: Number },
      },
    ],
  },
  { timestamps: true }
);

artistSchema.index({ isActive: 1, sortOrder: 1 });

module.exports = mongoose.model('Artist', artistSchema);
