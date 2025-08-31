const Product = require("./models/productModel");
const products = require("./products.json");

async function seedProducts() {
  try {
    const count = await Product.countDocuments();
    if (count === 0) {
      await Product.insertMany(products);
      console.log("🌱 Products seeded successfully");
    } else {
      console.log("✅ Products already exist, skipping seeding");
    }
  } catch (err) {
    console.error("❌ Error seeding products:", err.message);
    // do NOT throw, just continue
  }
}

module.exports = seedProducts;
