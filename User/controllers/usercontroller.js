const userModel = require('../models/userModel');
const UserModel = require('../models/userModel');
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
require("dotenv").config();

// const getUsers = async (req, res) => {
//     // const allusers = await userModel.find();
//     res.json(req.user)
// }

// controllers/usercontroller.js
const getUser = async (req, res) => {
  try {
    if (!req.user) {
      return res.status(401).json({ message: "Not authorized" });
    }

    res.status(200).json({
      id: req.user.id,
      email: req.user.email,
      firstName: req.user.firstName,
      lastName: req.user.lastName,
      age: req.user.age,
      phone: req.user.phone,
      gender: req.user.gender,
    });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};


const userRegister = async (req, res) => {

    const { email, password } = req.body;
    const hashedPassword = await bcrypt.hash(password, 10);
    const foundUser = await userModel.findOne({ email: email });
    if (foundUser) {
        res.status(400).json({ message: "user already exists" })
    } else {
        const user = await UserModel.create({
            email,
            password: hashedPassword,
            firstName: req.body.firstName,
            lastName: req.body.lastName,
            age: req.body.age,
            phone: req.body.phone,
            gender: req.body.gender
        })
        res.json(user.id)
    }
}

const loginUser = async (req, res) => {
    const { email, password } = req.body;
    const user = await userModel.findOne({ email });
  
    if (user && (await bcrypt.compare(password, user.password))) {
      const accessToken = jwt.sign(
        {
          user: {
            email: user.email,
            id: user._id,
            firstName: user.firstName,
            lastName: user.lastName,
            age: user.age,
            phone: user.phone,
            gender: user.gender
          },
        },
        process.env.ACCESS_TOKEN,
        { expiresIn: "1h" }
      );
      res.status(200).json({
        token: accessToken,
        user: {
          id: user._id,
          email: user.email,
          firstName: user.firstName,
          lastName: user.lastName,
          age: user.age,
          phone: user.phone,
          gender: user.gender
        }
      });
    } else {
      res.status(401).json({ message: "Wrong email or password" });
    }
    // res.json({message: "user logged in" })
  };
  

module.exports = {
    getUser,
    userRegister,
    loginUser
}