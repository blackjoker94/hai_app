 const express = require('express');
const bodyParser = require('body-parser');
const mongoose = require('mongoose');
const path = require('path');
const multer = require('multer');

const feedRoutes = require('./routes/feed');
const authRoutes = require('./routes/auth');
const bcrypt = require('bcryptjs');
const User = require('./models/user');
const Employee=require('./models/Employee')
const adminRoutes = require('./routes/admin');
const empRoutes=require('./routes/empRoutes');
const app = express();

const fileStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'images');
  },
  filename: (req, file, cb) => {
    cb(null, new Date().toISOString().replace(/:/g, '-') + '-' + file.originalname);
  }
});

const fileFilter = (req, file, cb) => {
  if (
    file.mimetype === 'image/png' ||
    file.mimetype === 'image/jpg' ||
    file.mimetype === 'image/jpeg'
  ) {
    cb(null, true);
  } else {
    cb(null, false);
  }
};

app.use(bodyParser.json());
app.use(multer({ storage: fileStorage, fileFilter }).single('image'));
app.use('/images', express.static(path.join(__dirname, 'images')));

 app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  next();
}); 

function seedInitialData() {
  return Employee.countDocuments()
    .then(count => {
      if (count === 0) {
        const initialEmployees = [
          { name: 'علي حسن علي', displayId: '#21094445454', district: 'عابدين', role: 'مشرف حي', status: 'نشط', statusType: 'success', tasks: ['متابعة بلاغات المنطقة'] },
          { name: 'سامي احمد عبدالله', displayId: '#21046445454', district: 'مدينة نصر', role: 'فني صيانه', status: 'موقوف', statusType: 'danger', tasks: ['صيانة كبائن الكهرباء'] },
          { name: 'عبدالرحمن حمدان', displayId: '#21345645454', district: 'مدينة الشروق', role: 'دعم', status: 'راحه', statusType: 'warning', tasks: ['الرد على استفسارات المواطنين'] },
          { name: 'يوسف اسلام الجوهري', displayId: '#21987645454', district: 'شمال سيناء', role: 'كول سنتر', status: 'نشط', statusType: 'success', tasks: ['الاشراف علي بلاغات حي عابدين', 'توزيع البلاغات علي الفنين', 'متابعة التنفيذ', 'اعتماد اغلاق البلاغ'] },
          { name: 'ابراهيم اسامه محمد', displayId: '#21324445454', district: 'شبرا', role: 'فني صيانه', status: 'اجازه', statusType: 'danger', tasks: ['صيانة الطرق'] },
          { name: 'علاء اسماعيل شريف', displayId: '##21094445454', district: 'مدينة نصر', role: 'مشرف حي', status: 'نشط', statusType: 'success', tasks: ['معاينة المواقع الميدانية'] },
          { name: 'مروان ايمن حجاج', displayId: '#21324445454', district: 'المطريه', role: 'دعم', status: 'موقوف', statusType: 'danger', tasks: ['الدعم الفني للنظام'] }
        ];
        return Employee.insertMany(initialEmployees);
      }
    })
    .then(result => {
      if (result) {
        console.log('DONE');
      }
    })
    .catch(err => {
      console.log("error");
    });
}


app.use('/employees', empRoutes);
app.use('/feed', feedRoutes);
app.use('/auth', authRoutes);
app.use('/admin', adminRoutes);

app.use((error, req, res, next) => {
  console.log(error);
  const status = error.statusCode || 500;
  const message = error.message;
  const data = error.data;
  res.status(status).json({ message: message, data: data });
});


const createAdmin = () => {
  const adminEmail = 'admin@example.com';
  const adminPassword = 'admin123';

  User.findOne({ email: adminEmail })
    .then(user => {
      if (!user) {
        return bcrypt.hash(adminPassword, 12).then(hashedPw => {
          const admin = new User({
            email: adminEmail,
            password: hashedPw,
            name: 'Admin',
            isAdmin: true,
            nationalId:"00000000000000",
            address:"admin address",
            points:"0"
          });
          return admin.save();
        });
      }
    })
    .then(result => {
      if (result) {
        console.log('Admin account created');
      }
    })
    .catch(err => console.log(err));
};


mongoose
  .connect('mongodb://localhost:27017/test_project')
  .then(result => {
    createAdmin();
    seedInitialData();

    app.listen(8080);
    console.log('Server is running on port 8080');
  })
  .catch(err => console.log(err));