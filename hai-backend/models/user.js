const mongoose = require('mongoose');
const Schema = mongoose.Schema;
const userSchema = new Schema({
  email: { type: String, required: true },
  password: { type: String, required: true },
  name: { type: String, required: true },
  nationalId: { type: String, required: true }, 
  address: { type: String, required: true },  
  points:{type:Number,default:0},  
  posts: [{ type: Schema.Types.ObjectId, ref: 'Post' }],
  isAdmin: { type: Boolean, default: false }
});
module.exports = mongoose.model('User', userSchema);
