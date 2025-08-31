const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const connectDB = require('./config/db_conn');
const seedProducts = require('./seed');

dotenv.config();
const app = express();
const port = process.env.PORT || 9000;

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use("/products", require("./routes/productRouter"));
app.use("/filter", require("./routes/filterRouter"));

async function startServer() {
  try {
    await connectDB();
    console.log("✅ MongoDB connected");

    await seedProducts(); // safe seeding

    app.listen(port, () => {
      console.log(`🚀 Products service running on port ${port}`);
    });
  } catch (err) {
    console.error("❌ Startup failed:", err.message);
    process.exit(1);
  }
}

startServer();
