const express = require('express');
const router = express.Router();
const empController = require('../controllers/empController');

router.get('/', empController.getAllEmployees);
router.get('/:id', empController.getEmployeeById);
router.post('/add', empController.createEmployee);

module.exports = router;