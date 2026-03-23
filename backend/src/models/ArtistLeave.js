const mongoose = require('mongoose');

const artistLeaveSchema = new mongoose.Schema(
  {
    artist: { type: mongoose.Schema.Types.ObjectId, ref: 'Artist', required: true },
    leaveDate: { type: Date, required: true },
    reason: { type: String },
  },
  { timestamps: true }
);

artistLeaveSchema.index({ artist: 1, leaveDate: 1 });

module.exports = mongoose.model('ArtistLeave', artistLeaveSchema);
