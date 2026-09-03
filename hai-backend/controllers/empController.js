const Employee = require('../models/Employee');

exports.getAllEmployees = (req, res) => {
  Employee.find()
    .then(employees => {
      res.json(employees);
    })
    .catch(err => {
      res.status(500).json({ message: err.message });
    });
};

exports.getEmployeeById = (req, res) => {
  Employee.findById(req.params.id)
    .then(employee => {
      if (!employee) return res.status(404).json({ message: "Employee not found" });
      res.json(employee);
    })
    .catch(err => {
      res.status(500).json({ message: err.message });
    });
};

exports.createEmployee = (req, res) => {
  const newEmployee = new Employee(req.body);
  newEmployee.save()
    .then(savedEmployee => {
      res.status(201).json(savedEmployee);
    })
    .catch(err => {
      res.status(400).json({ message: err.message });
    });
};