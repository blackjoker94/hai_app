# ⚠️ Legacy Backend (No Longer Active)

This folder contains the **original backend** built with **Node.js / Express / MongoDB** during early development.

The app has since **migrated to Firebase** (Firestore, Firebase Auth, Firebase Storage) as the production backend. This code is kept here for reference and historical purposes only.

### What was here
- Express REST API with JWT authentication
- MongoDB (Mongoose) models for users, posts, employees
- Multer file upload handling
- Admin seeding script

### What replaced it
- **Firebase Auth** — user authentication
- **Cloud Firestore** — database (users, posts/reports, employees)
- **Firebase Storage** — image uploads
- **Firestore Security Rules** — access control

> This code is **not required** to run the app. See the main [README](../README.md) for setup instructions.
