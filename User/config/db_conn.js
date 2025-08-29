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

// Determine MongoDB connection string based on environment
let mongoConnectionString;
if (process.env.NODE_ENV === 'production' && mongo_cluster && mongo_cluster.includes('mongodb.net')) {
  // Production: MongoDB Atlas
  mongoConnectionString = `mongodb+srv://${mongo_username}:${mongo_password}@${mongo_cluster}/${mongo_database}?retryWrites=true&w=majority`;
} else {
  // Development: Local MongoDB
  mongoConnectionString = `mongodb://${mongo_username}:${mongo_password}@${mongo_cluster}/${mongo_database}?authSource=admin`;
}

mongoose.connect(mongoConnectionString, { 
  useNewUrlParser: true, 
  useUnifiedTopology: true 
})
.then(() => console.log(`Connected to MongoDB: ${mongoose.connection.name}`))
.catch(err => console.log('MongoDB connection error:', err));



// async function getDataFromDatabase(id) {
//     // Check if the data is already cached
//     const cachedData = await getAsync(id);
//     if (cachedData) {
//       console.log('Fetching data from cache');
//       return JSON.parse(cachedData);
//     }
  
//     // If not cached, fetch data from the database
//     console.log('Fetching data from the database');
//     const data = await MyModel.findById(id).exec();
  
//     // Cache the fetched data
//     await setAsync(id, JSON.stringify(data));
  
//     return data;
//   }



//   async function main() {
//     const data1 = await getDataFromDatabase();
//     console.log(data1);
  
//     // Fetch the same data again to demonstrate caching
//     const data2 = await getDataFromDatabase();
//     console.log(data2);
//   }
  
//   main().catch(console.error);


// mongoose.connect(`mongodb://localhost:27017`
// , { useNewUrlParser: true, useUnifiedTopology: true })
// .then(() => console.log(`Connected to: DB`))
// .catch(err => console.log(err));


module.exports = mongoose;