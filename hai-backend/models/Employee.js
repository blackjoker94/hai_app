const mongoose = require('mongoose');

const EmployeeSchema = new mongoose.Schema({
  name: { type: String, required: true },
  displayId: { type: String, required: true },
  district: String,
  role: String,
  status: { type: String, default: 'نشط' },
  statusType: { type: String, default: 'success' },
  phone: String,
  email: String,
  joinDate: String,
  workHours: String,
  tasks: [String]
});

module.exports = mongoose.model('Employee', EmployeeSchema);