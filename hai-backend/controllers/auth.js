const { validationResult } = require('express-validator');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/user');

exports.signup = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    const error = new Error('Validation failed.');
    error.statusCode = 422;
    error.data = errors.array();
    throw error;
  }

  const email = req.body.email;
  const name = req.body.name;
  const password = req.body.password;
  const nationalId = req.body.nationalId; 
  const address = req.body.address;
  bcrypt
    .hash(password, 12)
    .then(hashedPw => {
      const user = new User({
        email: email,
        password: hashedPw,
        name: name,
        nationalId: nationalId,  
        address: address,
        isAdmin: false 
      });
      return user.save();
    })
    .then(result => {
      res.status(201).json({ message: 'User created!', userId: result._id });
    })
    .catch(err => {
      if (!err.statusCode) err.statusCode = 500;
      next(err);
    });
};


exports.login = (req, res, next) => {
  const email = req.body.email;
  const password = req.body.password;
  let loadedUser;
  User.findOne({ email: email })
    .then(user => {
      if (!user) {
        const error = new Error('A user with this email could not be found.');
        error.statusCode = 401;
        throw error;
      }
      loadedUser = user;
      return bcrypt.compare(password, user.password);
    })
    .then(isEqual => {
      if (!isEqual) {
        const error = new Error('Wrong password!');
        error.statusCode = 401;
        throw error;
      }
      const token = jwt.sign(
        {
          email: loadedUser.email,
          userId: loadedUser._id.toString()
        },
        'somesupersecretsecret',
        { expiresIn: '7h' }
      );
      res.status(200).json({ token: token, userId: loadedUser._id.toString(),isAdmin: loadedUser.isAdmin,name: loadedUser.name,
  nationalId: loadedUser.nationalId,
  address: loadedUser.address,points:loadedUser.points  });
    })
    .catch(err => {
      if (!err.statusCode) {
        err.statusCode = 500;
      }
      next(err);
    });
};


exports.changePassword = (req, res, next) => {
  const oldPassword = req.body.oldPassword;
  const newPassword = req.body.newPassword;

  let loadedUser;

  User.findById(req.userId)
    .then(user => {
      if (!user) {
        const error = new Error('User not found.');
        error.statusCode = 404;
        throw error;
      }

      loadedUser = user;
      return bcrypt.compare(oldPassword, user.password);
    })
    .then(isEqual => {
      if (!isEqual) {
        const error = new Error('Old password is incorrect.');
        error.statusCode = 401;
        throw error;
      }

      return bcrypt.hash(newPassword, 12);
    })
    .then(hashedPassword => {
      loadedUser.password = hashedPassword;
      return loadedUser.save();
    })
    .then(() => {
      res.status(200).json({ message: 'Password updated successfully.' });
    })
    .catch(err => {
      if (!err.statusCode) {
        err.statusCode = 500;
      }
      next(err);
    });
};