const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const postSchema = new Schema({
  title: { type: String, required: false },
  imageUrl: { type: String, required: true },
  content: { type: String, required: false },
  location: {
    lat: { type: Number, required: true },
    long: { type: Number, required: true }
  },
  district: { type: String,default:"معادي", required: true },
  status: {
  type: String,
  default: 'قيد المراجعه'
},
  creator: { type: Schema.Types.ObjectId, ref: 'User', required: true }
}, { timestamps: true });

module.exports = mongoose.model('Post', postSchema);
