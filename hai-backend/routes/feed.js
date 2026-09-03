const express = require('express');
const { body } = require('express-validator');
const feedController = require('../controllers/feed');
const isAuth = require('../middleware/is-auth');

const router = express.Router();

router.get('/posts', isAuth, feedController.getPosts);

router.post(
  '/post',
  isAuth,
  [
    body('title').trim().optional({ checkFalsy: true }).isLength({ min: 3 }),
    body('content').trim().optional({ checkFalsy: true }).isLength({ min: 5 })
  ],
  feedController.createPost
);

router.get('/post/:postId', isAuth, feedController.getPost);

router.put(
  '/post/:postId',
  isAuth,
  [
    body('title').trim().optional({ checkFalsy: true }).isLength({ min: 5 }),
    body('content').trim().optional({ checkFalsy: true }).isLength({ min: 5 })
  ],
  feedController.updatePost
);

router.delete('/post/:postId', isAuth, feedController.deletePost);

router.get('/user-posts', isAuth, feedController.getUserPosts);

module.exports = router;
