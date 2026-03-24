require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../models/User');
const Artist = require('../models/Artist');
const Service = require('../models/Service');
const SalonTiming = require('../models/SalonTiming');

async function seed() {
  await mongoose.connect(process.env.MONGODB_URI);
  console.log('Connected to MongoDB');

  // Clear existing data
  await Promise.all([
    User.deleteMany({}),
    Artist.deleteMany({}),
    Service.deleteMany({}),
    SalonTiming.deleteMany({}),
  ]);

  // Create admin user (password: admin123)
  const admin = await User.create({
    name: 'Admin',
    email: 'admin@salon.com',
    passwordHash: 'admin123',
    role: 'ADMIN',
  });
  console.log('Admin created: admin@salon.com / admin123');

  // Create test customer (password: test123)
  const customer = await User.create({
    name: 'Test Customer',
    email: 'customer@test.com',
    phone: '9876543210',
    passwordHash: 'test123',
    role: 'CUSTOMER',
  });
  console.log('Customer created: customer@test.com / test123');

  // Create services
  const services = await Service.insertMany([
    { name: 'Haircut', description: 'Professional haircut and styling with precision cutting techniques. Includes wash, cut, and blow dry.', durationMinutes: 30, price: 500, category: 'Hair', sortOrder: 1, imageUrl: 'haircut' },
    { name: 'Hair Coloring', description: 'Full hair coloring with premium ammonia-free products. Includes consultation and aftercare tips.', durationMinutes: 90, price: 2000, category: 'Hair', sortOrder: 2, imageUrl: 'hair_coloring' },
    { name: 'Hair Spa', description: 'Deep conditioning hair spa treatment with hot oil massage. Repairs damage and adds shine.', durationMinutes: 60, price: 1500, category: 'Hair', sortOrder: 3, imageUrl: 'hair_spa' },
    { name: 'Facial', description: 'Refreshing facial treatment with cleansing, exfoliation, mask, and moisturizing. Leaves skin glowing.', durationMinutes: 45, price: 1000, category: 'Skin', sortOrder: 4, imageUrl: 'facial' },
    { name: 'Cleanup', description: 'Quick skin cleanup with deep cleansing and blackhead removal. Perfect for a fresh look.', durationMinutes: 30, price: 600, category: 'Skin', sortOrder: 5, imageUrl: 'cleanup' },
    { name: 'Manicure', description: 'Professional nail care for hands including shaping, cuticle care, and polish application.', durationMinutes: 30, price: 400, category: 'Nails', sortOrder: 6, imageUrl: 'manicure' },
    { name: 'Pedicure', description: 'Relaxing pedicure with foot soak, scrub, nail shaping, and polish. Includes foot massage.', durationMinutes: 45, price: 500, category: 'Nails', sortOrder: 7, imageUrl: 'pedicure' },
    { name: 'Beard Trim', description: 'Precise beard trimming and shaping with hot towel treatment. Clean lines guaranteed.', durationMinutes: 20, price: 200, category: 'Hair', sortOrder: 8, imageUrl: 'beard_trim' },
  ]);
  console.log(`${services.length} services created`);

  // Create artists
  const artists = await Artist.insertMany([
    {
      name: 'Priya Sharma',
      phone: '9876500001',
      email: 'priya@salon.com',
      profileImageUrl: 'priya',
      bio: 'Expert in hair styling and coloring with 8 years of experience. Specializes in balayage, highlights, and trendy cuts.',
      experienceYears: 8,
      sortOrder: 1,
      availability: [
        { dayOfWeek: 1, startTime: '09:00', endTime: '18:00' },
        { dayOfWeek: 2, startTime: '09:00', endTime: '18:00' },
        { dayOfWeek: 3, startTime: '09:00', endTime: '18:00' },
        { dayOfWeek: 4, startTime: '09:00', endTime: '18:00' },
        { dayOfWeek: 5, startTime: '09:00', endTime: '18:00' },
        { dayOfWeek: 6, startTime: '10:00', endTime: '16:00' },
      ],
      breaks: [
        { dayOfWeek: 1, breakStart: '13:00', breakEnd: '14:00', label: 'Lunch' },
        { dayOfWeek: 2, breakStart: '13:00', breakEnd: '14:00', label: 'Lunch' },
        { dayOfWeek: 3, breakStart: '13:00', breakEnd: '14:00', label: 'Lunch' },
        { dayOfWeek: 4, breakStart: '13:00', breakEnd: '14:00', label: 'Lunch' },
        { dayOfWeek: 5, breakStart: '13:00', breakEnd: '14:00', label: 'Lunch' },
      ],
      services: [
        { service: services[0]._id },
        { service: services[1]._id },
        { service: services[2]._id },
      ],
    },
    {
      name: 'Rahul Verma',
      phone: '9876500002',
      email: 'rahul@salon.com',
      profileImageUrl: 'rahul',
      bio: 'Skin care specialist with expertise in facials, cleanups, and grooming. Known for his attention to detail.',
      experienceYears: 5,
      sortOrder: 2,
      availability: [
        { dayOfWeek: 1, startTime: '10:00', endTime: '19:00' },
        { dayOfWeek: 2, startTime: '10:00', endTime: '19:00' },
        { dayOfWeek: 3, startTime: '10:00', endTime: '19:00' },
        { dayOfWeek: 4, startTime: '10:00', endTime: '19:00' },
        { dayOfWeek: 5, startTime: '10:00', endTime: '19:00' },
        { dayOfWeek: 6, startTime: '10:00', endTime: '17:00' },
      ],
      breaks: [
        { dayOfWeek: 1, breakStart: '13:30', breakEnd: '14:30', label: 'Lunch' },
        { dayOfWeek: 2, breakStart: '13:30', breakEnd: '14:30', label: 'Lunch' },
        { dayOfWeek: 3, breakStart: '13:30', breakEnd: '14:30', label: 'Lunch' },
        { dayOfWeek: 4, breakStart: '13:30', breakEnd: '14:30', label: 'Lunch' },
        { dayOfWeek: 5, breakStart: '13:30', breakEnd: '14:30', label: 'Lunch' },
      ],
      services: [
        { service: services[3]._id },
        { service: services[4]._id },
        { service: services[0]._id },
        { service: services[7]._id },
      ],
    },
    {
      name: 'Anita Patel',
      phone: '9876500003',
      email: 'anita@salon.com',
      profileImageUrl: 'anita',
      bio: 'Nail art specialist and all-round beauty expert. Creates stunning nail designs and relaxing spa experiences.',
      experienceYears: 6,
      sortOrder: 3,
      availability: [
        { dayOfWeek: 1, startTime: '09:00', endTime: '17:00' },
        { dayOfWeek: 2, startTime: '09:00', endTime: '17:00' },
        { dayOfWeek: 3, startTime: '09:00', endTime: '17:00' },
        { dayOfWeek: 5, startTime: '09:00', endTime: '17:00' },
        { dayOfWeek: 6, startTime: '09:00', endTime: '15:00' },
      ],
      breaks: [
        { dayOfWeek: 1, breakStart: '12:30', breakEnd: '13:30', label: 'Lunch' },
        { dayOfWeek: 2, breakStart: '12:30', breakEnd: '13:30', label: 'Lunch' },
        { dayOfWeek: 3, breakStart: '12:30', breakEnd: '13:30', label: 'Lunch' },
        { dayOfWeek: 5, breakStart: '12:30', breakEnd: '13:30', label: 'Lunch' },
      ],
      services: [
        { service: services[5]._id },
        { service: services[6]._id },
        { service: services[3]._id },
      ],
    },
  ]);
  console.log(`${artists.length} artists created`);

  // Create salon timings (All days open)
  const timings = [
    { dayOfWeek: 0, openTime: '10:00', closeTime: '20:00', isClosed: false },
    { dayOfWeek: 1, openTime: '09:00', closeTime: '21:00', isClosed: false },
    { dayOfWeek: 2, openTime: '09:00', closeTime: '21:00', isClosed: false },
    { dayOfWeek: 3, openTime: '09:00', closeTime: '21:00', isClosed: false },
    { dayOfWeek: 4, openTime: '09:00', closeTime: '21:00', isClosed: false },
    { dayOfWeek: 5, openTime: '09:00', closeTime: '21:00', isClosed: false },
    { dayOfWeek: 6, openTime: '09:00', closeTime: '21:00', isClosed: false },
  ];
  await SalonTiming.insertMany(timings);
  console.log('Salon timings created');

  console.log('\nSeed completed successfully!');
  process.exit(0);
}

seed().catch((err) => {
  console.error('Seed error:', err);
  process.exit(1);
});
