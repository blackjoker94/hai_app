const express = require('express');
const { body } = require('express-validator');
const User = require('../models/user');
const authController = require('../controllers/auth');
const isAuth = require('../middleware/is-auth');
const router = express.Router();

router.post(
  '/signup',
  [
    body('email')
      .isEmail()
      .withMessage('Please enter a valid email.')
      .custom(value => {
        return User.findOne({ email: value }).then(userDoc => {
          if (userDoc) {
            return Promise.reject('E-Mail address already exists!');
          }
        });
      })
      .normalizeEmail(),
    body('password').trim().isLength({ min: 5 }),
    body('name').trim().not().isEmpty(),
    body('nationalId')
  .trim()
  .isLength({ min: 14, max: 14 })
  .withMessage('National ID must be 14 digits.')
  .isNumeric()
  .withMessage('National ID must contain only numbers.'),
body('address')
  .trim()
  .not()
  .isEmpty()
  .withMessage('Address is required.')
  ],
  authController.signup
);

router.post('/login', authController.login);


router.patch(
  '/change-password',
  isAuth,
  [
    body('oldPassword').trim().not().isEmpty(),
    body('newPassword').trim().isLength({ min: 5 })
  ],
  authController.changePassword
);

module.exports = router;
