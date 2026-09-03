const User = require('../models/user');

module.exports = (req, res, next) => {
  User.findById(req.userId)
    .then(user => {
      if (!user || !user.isAdmin) {
        return res.status(403).json({ message: 'Not authorized as admin.' });
      }
      next();
    })
    .catch(err => {
      res.status(500).json({ message: 'Server error.' });
    });
};
