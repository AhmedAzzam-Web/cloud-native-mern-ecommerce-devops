const mongoose = require('mongoose');
const redis = require('redis');
require('dotenv').config();

// Redis client configuration
let redisClient;
try {
  if (process.env.REDIS_URL) {
    redisClient = redis.createClient({ url: process.env.REDIS_URL });
  } else {
    redisClient = redis.createClient();
  }
} catch (error) {
  console.log('Redis connection failed:', error.message);
}

const mongo_username = process.env.MONGO_USERNAME;
const mongo_password = process.env.MONGO_PASSWORD;
const mongo_cluster = process.env.MONGO_CLUSTER;
const mongo_database = process.env.MONGO_DBNAME;

// Build connection string
let mongoConnectionString;
if (process.env.NODE_ENV === 'production' && mongo_cluster && mongo_cluster.includes('mongodb.net')) {
  mongoConnectionString = `mongodb+srv://${mongo_username}:${mongo_password}@${mongo_cluster}/${mongo_database}?retryWrites=true&w=majority`;
} else {
  mongoConnectionString = `mongodb://${mongo_username}:${mongo_password}@${mongo_cluster}/${mongo_database}?authSource=admin`;
}

async function connectDB() {
  try {
    await mongoose.connect(mongoConnectionString, { 
      useNewUrlParser: true, 
      useUnifiedTopology: true 
    });
    console.log(`✅ Connected to MongoDB: ${mongoose.connection.name}`);
  } catch (err) {
    console.error("❌ MongoDB connection error:", err.message);
    throw err;
  }
}

module.exports = connectDB;
