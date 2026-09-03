const Post = require('../models/post');
const User = require('../models/user');

exports.getAllPosts = (req, res, next) => {
  Post.find()
    .populate('creator')
    .then(posts => {
      res.status(200).json({ posts: posts });
    })
    .catch(err => next(err));
};

exports.deleteAnyPost = (req, res, next) => {
  Post.findById(req.params.postId)
    .then(post => {
      if (!post) {
        return res.status(404).json({ message: 'Post not found.' });
      }
      return Post.findByIdAndDelete(req.params.postId).then(() => post);
    })
    .then(post => {
      return User.findById(post.creator).then(user => {
        user.posts.pull(post._id);
        return user.save();
      });
    })
    .then(() => {
      res.status(200).json({ message: 'Post deleted by admin.' });
    })
    .catch(err => next(err));
};

exports.updatePostStatus = (req, res, next) => {
  const postId = req.params.postId;
  const newStatus = req.body.status;

  Post.findById(postId)
    .then(post => {
      if (!post) {
        const error = new Error('Could not find post.');
        error.statusCode = 404;
        throw error;
      }
      post.status = newStatus;
      return post.save();
    })
    .then(result => {
      res.status(200).json({ message: 'Status updated!', post: result });
    })
    .catch(err => {
      if (!err.statusCode) {
        err.statusCode = 500;
      }
      next(err);
    });
};
