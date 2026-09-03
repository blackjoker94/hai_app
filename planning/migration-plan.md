# HAI App — Backend Migration Plan (Local → Firebase)

> **Goal**: Replace the local Express.js + MongoDB backend (`hai-backend/`) with Firebase services, staying within **free-tier** (Spark plan) limits as much as possible.

---

## Table of Contents

1. [Current Architecture Summary](#1-current-architecture-summary)
2. [Why Firebase (and Alternatives Considered)](#2-why-firebase-and-alternatives-considered)
3. [Firebase Services Mapping](#3-firebase-services-mapping)
4. [Dashboard Data Note](#4-dashboard-data-note)
5. [Phase 0 — Firebase Project Setup](#phase-0--firebase-project-setup)
6. [Phase 1 — Authentication Migration](#phase-1--authentication-migration)
7. [Phase 2 — Database Migration (Firestore)](#phase-2--database-migration-firestore)
8. [Phase 3 — Image Storage Migration](#phase-3--image-storage-migration)
9. [Phase 4 — Server Logic Migration (Security Rules)](#phase-4--server-logic-migration-security-rules)
10. [Phase 5 — Flutter App Rewiring](#phase-5--flutter-app-rewiring)
11. [Phase 6 — Admin / Dashboard APIs](#phase-6--admin--dashboard-apis)
12. [Phase 7 — Cleanup & Go-Live](#phase-7--cleanup--go-live)
13. [Cost Breakdown (Spark Free Tier)](#cost-breakdown-spark-free-tier)
14. [Risk & Rollback Strategy](#risk--rollback-strategy)

---

## 1. Current Architecture Summary

### Backend (`hai-backend/`)
- **Runtime**: Node.js + Express 5
- **Database**: MongoDB (local, `mongodb://localhost:27017/test_project`)
- **Auth**: Custom JWT (`jsonwebtoken`) + bcrypt password hashing
- **Image Upload**: Multer → saves to local `images/` folder, served via `express.static`
- **Hardcoded secret**: `'somesupersecretsecret'` (JWT signing key)
- **Hardcoded admin**: `admin@example.com` / `admin123` created on startup

### Backend Data Models (MongoDB)

| Collection   | Key Fields |
|-------------|------------|
| **User**     | `email`, `password` (hashed), `name`, `nationalId` (14 digits), `address`, `points` (number), `posts[]` (refs), `isAdmin` (bool) |
| **Post**     | `title`, `imageUrl`, `content`, `location: {lat, long}`, `district` (default "معادي"), `status` (default "قيد المراجعه"), `creator` (ref→User), `timestamps` |
| **Employee** | `name`, `displayId`, `district`, `role`, `status`, `statusType`, `phone`, `email`, `joinDate`, `workHours`, `tasks[]` — **seeded with 7 initial records on startup** |

### Backend API Endpoints

| Method | Route | Auth | Purpose |
|--------|-------|------|---------|
| POST | `/auth/signup` | ✗ | Register user (email, password, name, nationalId, address) |
| POST | `/auth/login` | ✗ | Login → returns JWT + user profile |
| PATCH | `/auth/change-password` | ✓ JWT | Change password |
| GET | `/feed/posts` | ✓ JWT | Get all posts (with populated creator) |
| POST | `/feed/post` | ✓ JWT | Create post (multipart image + lat/long/title/content/district) — awards 25 points |
| GET | `/feed/post/:postId` | ✓ JWT | Get single post |
| PUT | `/feed/post/:postId` | ✓ JWT | Update post (only by creator) |
| DELETE | `/feed/post/:postId` | ✓ JWT | Delete post (only by creator) |
| GET | `/feed/user-posts` | ✓ JWT | Get current user's posts |
| GET | `/admin/posts` | ✓ JWT + Admin | Get all posts (admin) |
| DELETE | `/admin/post/:postId` | ✓ JWT + Admin | Delete any post (admin) |
| PATCH | `/admin/post-status/:postId` | ✓ JWT + Admin | Update post status (admin) |
| GET | `/employees/` | ✗ | Get all employees |
| GET | `/employees/:id` | ✗ | Get employee by ID |
| POST | `/employees/add` | ✗ | Add new employee |

### Flutter App (Front-End)
- **State management**: Cubit/Bloc
- **DI**: get_it + injectable (code-gen)
- **Network**: Dio with `BASE_URL` from `.env`, JWT interceptor from `FlutterSecureStorage`
- **On-device ML**: TFLite classification (flood/road/trash/other) + face detection/comparison (ML Kit + MobileFaceNet)
- **Local storage**: Hive (cached, authBox), FlutterSecureStorage (tokens, user data)
- **Features**: auth, post (create report), report (view reports), home, chat, leaderboard, profile, coupons, worker, notifications, welcomeboard, splash
- **Features with empty data layer**: chat, leaderboard, coupons, profile (reads from secure storage only), worker

### Key Observations
- The `Employee` collection is **dashboard data** — seeded at startup, CRUD routes have no auth protection
- Posts are essentially **citizen reports** (not social media posts) — classified by ML into flood/road/trash
- The points/gamification system (`+25 per post`) drives a rank ladder: مبتدئ → مساعد → بطل → الكبير
- Image URLs are stored as relative paths (e.g., `images/...`) and served from the Express static folder
- The app constructs full image URLs by prepending `BASE_URL`

---

## 2. Why Firebase (and Alternatives Considered)

| Option | Pros | Cons | Cost |
|--------|------|------|------|
| **Firebase (Spark)** ✅ | Auth built-in, Firestore NoSQL (matches MongoDB structure), Storage for images, Flutter SDK excellent, rules-based security, generous free tier | Cloud Functions require Blaze plan for outbound network calls; Spark plan has limits | **Free** (Spark plan for Auth + Firestore + Storage). Blaze plan only needed for Cloud Functions with pay-as-you-go |
| Supabase | PostgreSQL, auth built-in, storage | Relational DB = schema migration effort, different query patterns | Free tier available but smaller storage |
| Appwrite | Self-hosted or cloud, full BaaS | Smaller community, less Flutter ecosystem support | Free self-host, cloud free tier limited |
| Railway / Render | Deploy current Express app as-is | Still need hosted MongoDB (Atlas free 512MB), not truly serverless | Free tier has cold starts, sleep after inactivity |

### Recommendation: **Firebase (Spark → Blaze when needed)**

**Why**: 
- Your MongoDB document structure maps 1:1 to Firestore collections
- Firebase Auth replaces your entire JWT + bcrypt auth system out of the box
- Firebase Storage replaces Multer + static file serving
- The Flutter `cloud_firestore`, `firebase_auth`, and `firebase_storage` packages are official and well-maintained
- You eliminate the entire `hai-backend/` folder — no server to maintain
- The Spark (free) plan covers: 50K auth/month, 1 GiB Firestore storage, 50K reads/day, 20K writes/day, 5 GB Storage
- When you eventually add the dashboard, it can use the same Firebase project directly

---

## 3. Firebase Services Mapping

| Current Backend Component | Firebase Replacement | Free Tier Limit |
|--------------------------|---------------------|-----------------|
| JWT Auth + bcrypt | **Firebase Authentication** (Email/Password) | 50K MAU |
| MongoDB `users` collection | **Firestore** `users` collection | 1 GiB total storage |
| MongoDB `posts` collection | **Firestore** `posts` collection | 20K writes/day, 50K reads/day |
| MongoDB `employees` collection | **Firestore** `employees` collection | Same as above |
| Multer image upload + static serving | **Cloudinary** (Unsigned direct upload via Dio) | 25 GB free storage / 25 credits/mo (No CC required) |
| Admin check middleware (`isAdmin`) | **Firestore Security Rules** + Custom Claims | Free |
| Points increment (+25 on post create) | **Firestore Security Rules** or Client Batch | Free |
| Validation (express-validator) | **Firestore Security Rules** + client-side | Free |
| Seed data (employees) | **One-time Firestore import script** | Free |

---

## 4. Dashboard Data Note

> ⚠️ You mentioned the dashboard isn't ready yet but there is related data in the backend.

Based on my analysis, the **dashboard-related data** is:

1. **`employees` collection** — The 7 seeded employees with Arabic names, districts, roles, statuses, and tasks. These are displayed/managed from a dashboard (not from the mobile app currently).
2. **Admin API routes** (`/admin/*`) — Get all posts, delete any post, update post status. These are dashboard operations for admins to review/approve citizen reports.
3. **`isAdmin` flag on User** — Determines admin access. The hardcoded admin (`admin@example.com`) is a dashboard user.

**Migration approach**: All this data migrates cleanly to Firestore. When the dashboard arrives later, it will connect to the **same Firebase project** using Firestore directly (web SDK) or the Admin SDK. No additional backend needed.

---

## Phase 0 — Firebase Project Setup ✅ [COMPLETED]

**Status**: Completed
**Project ID**: `hai-app-eg` (Project Number: `30750315561`)
**Account**: `youssefeslam94@gmail.com`

### Steps Completed
- [x] **Create Firebase project**: `hai-app-eg` provisioned on Spark plan.
- [x] **Add Android app**:
  - Package name: `com.example.hai_app`
  - Downloaded `google-services.json` → placed in `android/app/`
  - Added Google Services plugin to `android/settings.gradle.kts` and `android/app/build.gradle.kts`
- [x] **Add iOS app**:
  - Bundle ID: `com.example.haiApp`
  - Downloaded `GoogleService-Info.plist` → placed in `ios/Runner/`
- [x] **Enable Firebase services in console**:
  - **Authentication**: Enabled Email/Password provider.
  - **Cloud Firestore**: Database `(default)` created in test mode.
- [x] **Flutter Configuration & Dependencies**:
  - Added `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, and `flutter_localizations` to `pubspec.yaml`
  - Generated `lib/firebase_options.dart` with platform options
  - Initialized Firebase in `lib/main.dart`
  - Verified `flutter pub get` and `flutter analyze` passing cleanly.

---

## Phase 1 — Authentication Migration ✅ [COMPLETED]

**Status**: Completed

### What Changed

| Current | Firebase |
|---------|----------|
| POST `/auth/signup` with email, password, name, nationalId, address | `FirebaseAuth.createUserWithEmailAndPassword()` → profile saved to Firestore `users/{uid}` with `points: 0`, `isAdmin: false` |
| POST `/auth/login` → server verifies password, returns JWT token | `FirebaseAuth.signInWithEmailAndPassword()` → profile fetched from Firestore `users/{uid}` |
| JWT stored in FlutterSecureStorage, sent via Dio interceptor | Firebase SDK manages auth state & tokens automatically. Offline profile cached in `FlutterSecureStorage`. |
| PATCH `/auth/change-password` → verify old, set new | Reauthenticate with `EmailAuthProvider.credential` → `currentUser.updatePassword()` |
| `isAdmin` flag in MongoDB User | `isAdmin` boolean field in Firestore `users/{uid}` |

### Steps Completed
- [x] **Firebase Auth Service**: Created `lib/core/services/firebase_auth_service.dart` with comprehensive Arabic error mapping.
- [x] **Firebase DI Module**: Created `lib/core/di/firebase_module.dart` providing `FirebaseAuth` and `FirebaseFirestore` singletons.
- [x] **User Model Enhanced**: Updated `lib/features/auth/data/model/user.dart` with `fromFirestore` and `toFirestore`.
- [x] **Auth Repository**: Rewrote `lib/features/auth/data/repo/auth_repo.dart` to use `FirebaseAuthService` & `FirebaseFirestore`.
- [x] **Dio Cleaned for External APIs**: Updated `lib/core/network/networkservice.dart` to keep Dio clean and ready for Groq, Gemini, and Cloudinary.
- [x] **Session Persistence**: App launch via `AppStartWrapper` checks `FirebaseAuth.instance.currentUser != null`.
- [x] **DI Configuration**: Regenerated `injection.config.dart` with `build_runner`.

---

## Phase 2 — Database Migration (Firestore)

**Time estimate**: 3-4 hours

### Firestore Collection Design

```
Firestore Root
├── users/
│   └── {uid}          (doc per user — uid comes from Firebase Auth)
│       ├── email: string
│       ├── name: string
│       ├── nationalId: string
│       ├── address: string
│       ├── points: number (default 0)
│       ├── isAdmin: boolean (default false)
│       └── createdAt: timestamp
│
├── posts/
│   └── {postId}       (auto-generated doc ID)
│       ├── title: string         (classification label: trash/road/flood)
│       ├── imageUrl: string      (Firebase Storage download URL)
│       ├── content: string
│       ├── location: map {lat: number, long: number}
│       ├── district: string
│       ├── status: string        (default "قيد المراجعه")
│       ├── creatorId: string     (uid reference)
│       ├── creatorName: string   (denormalized for easy display)
│       ├── createdAt: timestamp
│       └── updatedAt: timestamp
│
├── employees/
│   └── {employeeId}   (auto-generated doc ID)
│       ├── name: string
│       ├── displayId: string
│       ├── district: string
│       ├── role: string
│       ├── status: string
│       ├── statusType: string
│       ├── phone: string
│       ├── email: string
│       ├── joinDate: string
│       ├── workHours: string
│       └── tasks: array<string>
```

### Step-by-Step

1. **Create Firestore data service files** for each collection:
   - `lib/core/services/firestore_service.dart` (generic Firestore wrapper, optional)
   - Or feature-specific: `lib/features/post/data/remote/post_firestore_service.dart`

## Phase 2 — Database Migration (Firestore) ✅ [COMPLETED]

**Status**: Completed

### What Changed

| Current API Call | Firestore Equivalent | Status |
|-----------------|---------------------|--------|
| `POST /feed/post` (create + 25 points) | `posts.add({...})` + `users/{uid}.update({points: FieldValue.increment(25)})` (Atomic Batch Write) | ✅ Migrated |
| `GET /feed/posts` | `posts.orderBy('createdAt', descending: true).get()` | ✅ Migrated |
| `GET /feed/user-posts` | `posts.where('creatorId', isEqualTo: uid).get()` + in-memory sort | ✅ Migrated |
| Employee initial records | Seeded 7 employee records into `employees` collection | ✅ Seeded |

### Steps Completed
- [x] **Post Repository**: Rewrote `lib/features/post/data/repo/post_repo.dart` to execute atomic batch writes (Post creation + +25 points increment in `users/{uid}`).
- [x] **Reports Data Source**: Rewrote `lib/features/report/data/remote/report_remote.dart` with Firestore queries.
- [x] **Models**: Updated `PostModel` and `Report` with `fromFirestore` and resilient image URL resolution.
- [x] **Employee Seeding**: Seeded all 7 municipal records into Firestore `employees` collection via MCP tools.
- [x] **Cleanup**: Removed obsolete `lib/core/services/post_service.dart`.

---

## Phase 3 — Image Storage Migration (Cloudinary) ✅ [COMPLETED]

**Status**: Completed
**Cloud Name**: `kf03vky3`
**Upload Preset**: `hai_preset` (Unsigned)

### Steps Completed
- [x] **Cloudinary Service**: Created `lib/core/services/cloudinary_service.dart` uploading directly via `Dio` multipart request.
- [x] **Post Repo Integration**: Injected into `PostRepo.createPost()` to upload picked report image before saving Firestore document.
- [x] **Direct CDN URLs**: Public HTTPS CDN image URLs saved directly in `posts` collection, eliminating need for `BASE_URL` concatenation.
- [x] **Environment Config**: Cloud name and preset stored in `.env`.

---

2. **Update Post Creation Flow**
   - In `PostRepo.createPost()`:
     1. Upload image using `CloudinaryService.uploadImage(file)` → receive `secure_url`.
     2. Create Firestore document in `posts` collection storing `imageUrl: secure_url`.
     3. Increment user points (+25) in the same batched write.

3. **Update Data Models**
   - Remove `fullImageUrl` getter from `PostModel` and `Report` — `imageUrl` is already a full HTTPS URL from Cloudinary CDN.
   - Any widget referencing `fullImageUrl` will simply use `imageUrl`.

### Files to Modify
- [NEW] `lib/core/services/cloudinary_service.dart`
- `lib/features/post/data/repo/post_repo.dart` → inject `CloudinaryService` and use during post creation
- `lib/features/post/data/models/post_model.dart` → simplify `imageUrl`
- `lib/features/home/data/models/report_model.dart` → simplify `imageUrl`
- UI widgets displaying reports → use `imageUrl` directly with `CachedNetworkImage`

---

## Phase 4 — Server Logic Migration (Security Rules)

**Time estimate**: 1-2 hours

### Firestore Security Rules

This replaces all your Express middleware (`is-auth.js`, `is-admin.js`) and validation (`express-validator`).

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ── USERS ─────────────────────────────────────────
    match /users/{userId} {
      // Any authenticated user can read their own profile
      allow read: if request.auth != null && request.auth.uid == userId;
      // Only the user can update their own profile
      allow update: if request.auth != null && request.auth.uid == userId;
      // User doc is created during signup (from client)
      allow create: if request.auth != null && request.auth.uid == userId;
      // Admin can read any user (for dashboard)
      allow read: if request.auth != null && 
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }

    // ── POSTS ─────────────────────────────────────────
    match /posts/{postId} {
      // Any authenticated user can read all posts
      allow read: if request.auth != null;
      // Any authenticated user can create a post (must set creatorId to their uid)
      allow create: if request.auth != null && 
                       request.resource.data.creatorId == request.auth.uid;
      // Only the creator can update their post
      allow update: if request.auth != null && 
                       resource.data.creatorId == request.auth.uid;
      // Creator can delete their own post; admins can delete any post
      allow delete: if request.auth != null && (
                       resource.data.creatorId == request.auth.uid ||
                       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true
                     );
    }

    // ── EMPLOYEES ─────────────────────────────────────
    match /employees/{empId} {
      // Any authenticated user can read (for the mobile app display)
      allow read: if request.auth != null;
      // Only admins can write (for the dashboard)
      allow write: if request.auth != null && 
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
  }
}
```

### Admin Post Status Update (Dashboard Operation)

Currently: `PATCH /admin/post-status/:postId` — admin updates `status` field.

With Firestore: The dashboard will directly call:
```dart
FirebaseFirestore.instance.collection('posts').doc(postId).update({'status': newStatus});
```
Security rules need a special case to allow admins to update any post status. Update the posts rule:
```javascript
// Admins can also update any post (for status changes)
allow update: if request.auth != null && (
                 resource.data.creatorId == request.auth.uid ||
                 get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true
               );
```

## Phase 4 — Server Logic Migration (Security Rules) ✅ [COMPLETED]

**Status**: Completed & Deployed to Firebase

### What Changed
- [x] **Production Security Rules**: Created `firestore.rules` defining strict access controls for `users/{userId}`, `posts/{postId}`, and `employees/{empId}`.
- [x] **Admin Role & Permissions**: Enabled admins to read all user profiles, update post statuses, delete posts, and manage employee records.
- [x] **Composite Query Index**: Configured and deployed `firestore.indexes.json` with composite index for `posts` (`creatorId ASC`, `createdAt DESC`).
- [x] **Live Deployment**: Validated with `firebase_validate_security_rules` and deployed via Firebase MCP tools with 100% success.

---

## Phase 5 — Flutter App Rewiring ✅ [COMPLETED]

**Status**: Completed

### What Changed
- [x] **Auth Layer Rewired**: Splash (`AppStartWrapper`), Login, Signup, and Logout (`ProfileScreen`) seamlessly integrated with `FirebaseAuthService` & Firestore user profiles.
- [x] **Home & Gamification Rewired**: `HomeCubit` synchronizes authoritative points and user details from Firestore with offline fallback.
- [x] **Post Creation Rewired**: `PostRepo` executes Cloudinary CDN upload + Firestore atomic batch writes (+25 points) and syncs local storage.
- [x] **Reports Directory Rewired**: `PostsRemoteDataSource` queries `posts/` from Firestore with category and user filters.
- [x] **Profile & Session Management**: `ProfileCubit` reads and updates profile points and ranks; logout cleans local storage and signs out of Firebase.
- [x] **Legacy Cleanup**: Removed obsolete `post_service.dart`, `auth_service.dart`, local `BASE_URL` dependencies, and dead code paths.
- [x] **Dependency Injection**: Fully configured and regenerated with `injectable` and `build_runner`.

---

> **Note**: Keep `dio` and `pretty_dio_logger` if you still need them for Gemini/Groq API calls (you have those API keys in `.env`). Remove only if no external HTTP calls remain.

### Step-by-Step File Changes

#### 1. `lib/main.dart`
- Add `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);`
- Keep `await dotenv.load()` if you still use Gemini/Groq keys from `.env`

#### 2. `lib/core/network/networkservice.dart`
- **If keeping Dio for Gemini/Groq**: Remove `_AuthInterceptor` (Firebase handles auth). Keep Dio for external APIs only.
- **If removing Dio entirely**: Delete this file and update DI.

#### 3. `lib/core/di/injection.config.dart` + `injection.dart`
- Re-run `dart run build_runner build` after changing service annotations
- Or manually update registrations to replace `AuthService`, `PostService`, `NetworkService` with new Firebase-based services

#### 4. `lib/features/auth/` (full rewrite of data layer)
- `data/remote/auth_service.dart` → `FirebaseAuthService` using `firebase_auth`
- `data/repo/auth_repo.dart` → Use `FirebaseAuthService` + Firestore for profile
- `data/model/user.dart` → Update `fromJson` to handle Firestore data (use `doc.id` instead of `_id`)
- `presentation/cubits/auth_cubit/` → Minimal changes (repo interface stays)

#### 5. `lib/features/post/` (rewrite data layer)
- `data/repo/post_repo.dart` → Firestore + Firebase Storage
- Remove `lib/core/services/post_service.dart` (was Dio-based)

#### 6. `lib/features/report/data/remote/report_remote.dart`
- Replace Dio call with Firestore query

#### 7. `lib/features/home/presentation/cubit/home_cubit.dart`
- May need to update how points refresh works (read from Firestore instead of only secure storage)
- Consider reading points from Firestore on each home load for accuracy

#### 8. `.env` file
- Remove `BASE_URL` (no more local backend)
- Keep `GEMINI_API_KEY`, `GROQ_API_KEY`, `GROQ_API_KEY2` if still used

#### 9. Update all `fullImageUrl` references in widgets
- Search for `fullImageUrl` across the codebase and replace with `imageUrl`

### DI Registration Changes

| Current Registration | New Registration |
|---------------------|------------------|
| `NetworkService` (Dio) | Keep for Gemini/Groq **OR** remove |
| `AuthService` (Dio-based) | `FirebaseAuthService` (firebase_auth) |
| `PostService` (Dio-based) | `FirestorePostService` (cloud_firestore) |
| `PostsRemoteDataSource` (Dio-based) | `FirestorePostsDataSource` (cloud_firestore) |
| `AuthRepo` (uses AuthService) | `AuthRepo` (uses FirebaseAuthService + Firestore) |
| `PostRepo` (uses PostService) | `PostRepo` (uses FirestorePostService + StorageService) |

---

## Phase 6 — Admin / Dashboard APIs

**Time estimate**: Planning only (implementation when dashboard arrives)

### What the Dashboard Will Need

When your dashboard arrives, it will need these operations (all currently in `hai-backend/controllers/admin.js` and `routes/admin.js`):

1. **Get all posts** — `Firestore.collection('posts').orderBy('createdAt').get()`
2. **Delete any post** — `Firestore.collection('posts').doc(id).delete()`
3. **Update post status** — `Firestore.collection('posts').doc(id).update({status: 'new_status'})`
4. **Get all employees** — `Firestore.collection('employees').get()`
5. **Add employee** — `Firestore.collection('employees').add({...})`
6. **Get all users** — `Firestore.collection('users').get()` (for admin user management)

### Dashboard Architecture Options

| Option | How | Cost |
|--------|-----|------|
| **Web app with Firebase JS SDK** ✅ | Dashboard reads/writes Firestore directly using web SDK. Security rules enforce admin-only access. | **Free** |
| **Flutter Web dashboard** | Same Firebase Dart packages, deploy to Firebase Hosting | **Free** (Hosting on Spark plan) |
| **Firebase Admin SDK (Node.js)** | Server-side scripts or Cloud Functions for admin operations | **Free** (if using Spark), needs Blaze for Functions |

### Recommendation
When the dashboard arrives, have it use the **Firebase Web SDK directly** (JavaScript or Flutter Web). Security rules already enforce admin-only access to admin operations. No additional backend needed.

---

## Phase 7 — Cleanup & Go-Live ✅ [COMPLETED]

**Status**: Completed

### Steps Completed
- [x] **Production Security Rules**: Deployed live to Firebase (`firestore.rules`).
- [x] **Composite Index**: Deployed live to Firebase (`firestore.indexes.json`).
- [x] **Cloudinary Free Tier CDN**: Connected with unsigned preset `hai_preset` and cloud name `kf03vky3`.
- [x] **Environment Config**: Cleaned `.env` (removed local `BASE_URL`).
- [x] **Verification**: Static analysis and code generation completed with 0 errors.

---

## Cost Breakdown (Spark Free Tier + Cloudinary)

| Service | Free Tier Limit | Your Expected Usage |
|---------|----------------|-------------------|
| **Authentication** | 50,000 MAU | Well within limits for a city/district app |
| **Firestore Storage** | 1 GiB | Small documents — far under limit |
| **Firestore Reads** | 50,000/day | Moderate — well within limits |
| **Firestore Writes** | 20,000/day | Low — well within limits |
| **Firestore Deletes** | 20,000/day | Very low |
| **Cloudinary Storage** | 25 GB / 25 credits/mo | ~80 reports × 60KB/image ≈ 5MB. Very far from limit |
| **CDN Bandwidth** | 25 GB/mo | Fast CDN image delivery |
| **Hosting** (if using) | 10 GB storage, 360 MB/day transfer | Only if you host dashboard |

**Total estimated cost: $0/month (100% Free, No Credit Card Required)** for the entire application.

---

## Quick Reference: Migration Order

```
Phase 0: Firebase Project Setup              ██████████  (COMPLETED ✅)
Phase 1: Authentication Migration            ██████████  (COMPLETED ✅)
Phase 2: Database Migration (Firestore)      ██████████  (COMPLETED ✅)
Phase 3: Image Storage (Cloudinary)          ██████████  (COMPLETED ✅)
Phase 4: Security Rules                      ██████████  (COMPLETED ✅)
Phase 5: Flutter App Rewiring                ██████████  (COMPLETED ✅)
Phase 6: Dashboard APIs                      ░░░░░░░░░░  (deferred for web)
Phase 7: Cleanup & Go-Live                   ██████████  (COMPLETED ✅)
                                             ─────────────
                                    Status:  Production Ready 🚀
```

> **Phases 1-3 can be done in parallel** if you work feature-by-feature (auth first, then posts, then images).
> **Phase 4 should come after 1-3** to lock everything down.
> **Phase 5 is the integration phase** — wire everything together.
> **Phase 6 is deferred** until the dashboard is ready.
