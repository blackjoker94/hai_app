const express = require('express');
const adminController = require('../controllers/admin');
const isAuth = require('../middleware/is-auth');
const isAdmin = require('../middleware/is-admin');

const router = express.Router();
router.patch('/post-status/:postId', isAuth,isAdmin, adminController.updatePostStatus);
router.get('/posts', isAuth, isAdmin, adminController.getAllPosts);
router.delete('/post/:postId', isAuth, isAdmin, adminController.deleteAnyPost);

module.exports = router;
