const express = require("express");
const router = express.Router();
const validateToken = require("../middleware/tokenValidationMiddleware");

const {
  getUser,
  userRegister,
  loginUser,
} = require("../controllers/usercontroller");

// Register new user
router.post("/", userRegister);

// Login user
router.post("/login", loginUser);

// Get current logged-in user profile
router.get("/profile", validateToken, getUser);

console.log({ getUser, userRegister, loginUser });

module.exports = router;
