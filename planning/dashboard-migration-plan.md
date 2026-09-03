# Dashboard Migration Plan — Local Express → Firebase

> **Goal**: Migrate the `hai-dashboard/` React dashboard from the local Express.js backend (`http://localhost:8080`) to the same Firebase project (`hai-app-eg`) used by the mobile app. **Zero cost** — everything stays on Firebase Spark free tier + Firebase Hosting.

---

## 1. Current Dashboard Architecture

### Tech Stack
- **Framework**: React 19 + Vite 7
- **Routing**: react-router-dom 7
- **Icons**: Font Awesome 6.5 (CDN)
- **Styling**: Vanilla CSS (4 CSS files)
- **State**: Local `useState`/`useEffect` (no state library)

### Pages & What They Do

| Page | File | Purpose |
|------|------|---------|
| **Login** | `pages/Login.jsx` | Admin login via `POST http://localhost:8080/auth/login` → stores JWT in `localStorage` |
| **Home** | `pages/home.jsx` | Dashboard overview: report stats (new/fixed/review), urgent reports list, leader board, geo-clustering alerts |
| **Reports** | `pages/Reports.jsx` | All reports table with filtering by title, status update dropdown (`PATCH /admin/post-status/:id`) |
| **Details** | `pages/Profile.jsx` | Single report detail view with image, status, reverse geocoding (Nominatim), embedded OpenStreetMap |
| **Sidebar** | `components/Sidebar.jsx` | Navigation links: الرئيسية, تفاصيل البلاغ, جداول البلاغات |

### How It Works Currently

```
[Dashboard React App]
    │
    ├── Login: POST /auth/login → gets JWT token → stores in localStorage
    │
    ├── Home: GET /admin/posts (JWT Bearer) → counts statuses, finds urgent, calculates leaders
    │
    ├── Reports: GET /admin/posts (JWT Bearer) → table display
    │         └── PATCH /admin/post-status/:id (JWT Bearer) → update status
    │
    └── Details: Shows report data passed via router state
              ├── Image: http://localhost:8080/{imageUrl}  (local static files)
              └── Map: Nominatim reverse geocoding + OpenStreetMap embed
```

---

## 2. Every Hardcoded `localhost:8080` Reference

These are ALL the places that call the old backend — every single one must change:

| File | Line | Current Code | What It Does |
|------|------|-------------|--------------|
| `Login.jsx` | 16 | `fetch('http://localhost:8080/auth/login', ...)` | Admin login via Express |
| `home.jsx` | 19 | `fetch('http://localhost:8080/admin/posts', ...)` | Fetch all posts for stats |
| `Reports.jsx` | 12 | `fetch('http://localhost:8080/admin/posts', ...)` | Fetch all posts for table |
| `Reports.jsx` | 31 | `fetch('http://localhost:8080/admin/post-status/${postId}', ...)` | Update report status |
| `Reports.jsx` | 119 | `src={http://localhost:8080/${report.imageUrl}}` | Display report image |
| `Profile.jsx` | 72 | `src={http://localhost:8080/${reportData.imageUrl}}` | Display report image in details |

**Total: 6 references to kill.**

---

## 3. Data Shape Differences (MongoDB → Firestore)

The dashboard expects MongoDB-shaped data. Firestore data is different:

| Field | MongoDB (current dashboard) | Firestore (your new data) | Action Needed |
|-------|---------------------------|--------------------------|---------------|
| **ID** | `report._id` | `doc.id` (Firestore doc ID) | Map `doc.id` → `_id` OR update all `_id` references to `id` |
| **Creator** | `report.creator` (populated object: `{_id, name, ...}`) | `report.creatorId` (string) + `report.creatorName` (string) | Change `p.creator._id` → `p.creatorId`, `p.creator.name` → `p.creatorName` |
| **Image URL** | `report.imageUrl` = `"images/1234.jpg"` (relative path, needs `localhost:8080/` prefix) | `report.imageUrl` = `"https://res.cloudinary.com/..."` (full CDN URL) | Use `report.imageUrl` directly — no prefix needed |
| **Timestamps** | `report.createdAt` = ISO string | `report.createdAt` = Firestore `Timestamp` object | Convert with `.toDate()` |
| **Location** | `report.location.long` | `report.location.long` | ✅ Same field name |
| **Status values** | `"قيد المراجعه"`, `"تحت التصليح"`, `"تم التصليح"` | `"قيد المراجعه"` (default from mobile app) | May need to verify the mobile app uses the same status strings the dashboard expects |

---

## 4. Migration Phases

### Phase D-0 — Install Firebase SDK & Configure Project ✅ [COMPLETED]

**Time estimate**: 15 minutes

**Steps**:
1. `cd hai-dashboard`
2. `npm install firebase`
3. Create `src/firebase.js` — initialize Firebase with your project config:
   ```javascript
   import { initializeApp } from 'firebase/app';
   import { getAuth } from 'firebase/auth';
   import { getFirestore } from 'firebase/firestore';

   const firebaseConfig = {
     apiKey: "AIzaSyAAg-EcagMDE7lnBz3LAYtVwsqPz2JwK1I",
     authDomain: "hai-app-eg.firebaseapp.com",
     projectId: "hai-app-eg",
     storageBucket: "hai-app-eg.firebasestorage.app",
     messagingSenderId: "30750315561",
     appId: "1:30750315561:web:ac3c3f769492e3cbc9b838"
   };

   const app = initializeApp(firebaseConfig);
   export const auth = getAuth(app);
   export const db = getFirestore(app);
   ```

> **Note**: Web app `hai-dashboard` (`1:30750315561:web:ac3c3f769492e3cbc9b838`) was registered in project `hai-app-eg` and configured.

---

### Phase D-1 — Replace Login Authentication ✅ [COMPLETED]

**Time estimate**: 30 minutes

**Current** (`Login.jsx` line 16):
```javascript
const response = await fetch('http://localhost:8080/auth/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ email: identifier, password: password }),
});
const data = await response.json();
if (response.ok) {
  if (data.isAdmin === true) {
    localStorage.setItem('adminToken', data.token);
    navigate('/');
  }
}
```

**Replace with**:
```javascript
import { signInWithEmailAndPassword } from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';
import { auth, db } from '../firebase';

const handleLogin = async (e) => {
  e.preventDefault();
  setError('');
  try {
    const credential = await signInWithEmailAndPassword(auth, identifier, password);
    const uid = credential.user.uid;

    // Check isAdmin in Firestore
    const userDoc = await getDoc(doc(db, 'users', uid));
    if (userDoc.exists() && userDoc.data().isAdmin === true) {
      navigate('/');
    } else {
      await auth.signOut();
      setError('عفواً، ليس لديك صلاحية الوصول للوحة التحكم');
    }
  } catch (err) {
    setError('بيانات الدخول غير صحيحة');
  }
};
```

**Also update `App.jsx` ProtectedRoute** (line 10-16):
```javascript
// Current: checks localStorage token
const token = localStorage.getItem('adminToken');

// Replace with: check Firebase auth state
import { auth } from './firebase';
const ProtectedRoute = ({ children }) => {
  const user = auth.currentUser;
  if (!user) {
    return <Navigate to="/login" replace />;
  }
  return children;
};
```

> **Important**: You'll also need to handle Firebase auth state persistence. Consider using `onAuthStateChanged` to listen for auth state and storing it in React context or state.

**Files to change**:
- `src/pages/Login.jsx` — replace fetch with `signInWithEmailAndPassword` + Firestore admin check
- `src/App.jsx` — replace `localStorage.adminToken` check with `auth.currentUser`
- Remove all `localStorage.getItem('adminToken')` references from `home.jsx` and `Reports.jsx`

---

### Phase D-2 — Replace Data Fetching (Home Page) ✅ [COMPLETED]

**Time estimate**: 30 minutes

**Current** (`home.jsx` line 19):
```javascript
fetch('http://localhost:8080/admin/posts', {
  headers: { 'Authorization': 'Bearer ' + ADMIN_TOKEN }
})
```

**Replace with**:
```javascript
import { collection, getDocs, query, orderBy } from 'firebase/firestore';
import { db } from '../firebase';

useEffect(() => {
  const fetchPosts = async () => {
    const q = query(collection(db, 'posts'), orderBy('createdAt', 'desc'));
    const snapshot = await getDocs(q);
    const allPosts = snapshot.docs.map(doc => ({
      ...doc.data(),
      _id: doc.id,   // Map Firestore doc ID to _id for compatibility
      id: doc.id,
    }));

    // ... rest of your stats calculation stays the same
  };
  fetchPosts();
}, []);
```

**Key data shape changes in `home.jsx`**:
- Line 43: `p.creator._id || p.creator.id` → change to `p.creatorId`
- Line 48: `p.creator.name` → change to `p.creatorName`
- Line 36: `new Date(b.updatedAt || b.createdAt)` → Firestore Timestamps need `.toDate()`:
  ```javascript
  const getDate = (ts) => ts?.toDate ? ts.toDate() : new Date(ts);
  .sort((a, b) => getDate(b.updatedAt || b.createdAt) - getDate(a.updatedAt || a.createdAt))
  ```
- Remove `ADMIN_TOKEN` variable (line 16) — Firebase auth handles security via rules

---

### Phase D-3 — Replace Data Fetching (Reports Page) ✅ [COMPLETED]

**Time estimate**: 30 minutes

**Current** (`Reports.jsx`):
- Line 12: `fetch('http://localhost:8080/admin/posts', ...)` — fetch all reports
- Line 31: `fetch('http://localhost:8080/admin/post-status/${postId}', ...)` — update status
- Line 119: `src={http://localhost:8080/${report.imageUrl}}` — display image

**Replace with**:

1. **Fetch all posts** (same pattern as Phase D-2):
   ```javascript
   import { collection, getDocs, doc, updateDoc, query, orderBy } from 'firebase/firestore';
   import { db } from '../firebase';

   const snapshot = await getDocs(query(collection(db, 'posts'), orderBy('createdAt', 'desc')));
   const posts = snapshot.docs.map(d => ({ ...d.data(), _id: d.id }));
   setReportsData(posts);
   ```

2. **Update status** (replace the PATCH call):
   ```javascript
   const updateStatus = async (postId, newStatus) => {
     try {
       await updateDoc(doc(db, 'posts', postId), { status: newStatus });
       // Update local state
       setReportsData(prev => prev.map(p => p._id === postId ? { ...p, status: newStatus } : p));
     } catch (err) {
       console.error('فشل تحديث الحالة:', err);
     }
   };
   ```

3. **Image URL** (line 119):
   ```jsx
   // OLD: src={`http://localhost:8080/${report.imageUrl}`}
   // NEW: Cloudinary URLs are already full HTTPS URLs
   src={report.imageUrl}
   ```

4. **Timestamps**: `report.createdAt` from Firestore is a `Timestamp` — convert when displaying:
   ```javascript
   report.createdAt?.toDate ? report.createdAt.toDate().toLocaleDateString('ar-EG') : report.createdAt
   ```

---

### Phase D-4 — Fix Report Details Page ✅ [COMPLETED]

**Time estimate**: 15 minutes

**Current** (`Profile.jsx`):
- Line 72: `src={http://localhost:8080/${reportData.imageUrl}}` — image display
- Line 95: `reportData._id?.slice(-9)` — ticket number
- Line 100: `new Date(reportData.createdAt).toLocaleDateString('ar-EG')` — date display

**Changes needed**:

1. **Image** (line 72): Remove `localhost:8080/` prefix — Cloudinary URLs are already full:
   ```jsx
   src={reportData.imageUrl}
   ```

2. **Ticket number** (line 95): Firestore doc IDs are different format than MongoDB ObjectIDs, but `slice(-9)` still works fine. **No change needed**.

3. **Date** (line 100): Handle Firestore Timestamp:
   ```javascript
   {reportData.createdAt?.toDate
     ? reportData.createdAt.toDate().toLocaleDateString('ar-EG')
     : new Date(reportData.createdAt).toLocaleDateString('ar-EG')}
   ```

4. **Note**: The report data is passed via `router state` from Home/Reports pages. Since you'll already be mapping Firestore data in those pages (adding `_id: doc.id`), the data shape arriving at Profile should be compatible.

---

### Phase D-5 — Deploy to Firebase Hosting (Free) ✅ [COMPLETED]

**Time estimate**: 20 minutes

Firebase Hosting serves your built Vite app as a static site — **completely free**.

**Steps**:

1. **Add Firebase Hosting to firebase.json** (in project root):
   ```json
   {
     "firestore": { ... },
     "hosting": {
       "public": "hai-dashboard/dist",
       "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
       "rewrites": [
         { "source": "**", "destination": "/index.html" }
       ]
     }
   }
   ```
   > The `rewrites` rule is essential for React Router — all paths serve `index.html`.

2. **Build the dashboard**:
   ```bash
   cd hai-dashboard
   npm run build
   ```
   This creates a `dist/` folder with the production bundle.

3. **Deploy**:
   ```bash
   npx firebase-tools deploy --only hosting
   ```

4. **Your dashboard is live at**: `https://hai-app-eg.web.app` ✅

**Cost**: Free — Spark plan includes 10 GB hosting storage and 360 MB/day transfer.

---

## 5. Security Considerations

### ✅ Already Done (from your Firestore rules)
- Only admin users can read all posts (`isAdmin == true` check)
- Only admin users can update post status
- Only admin users can write to employees collection

### ⚠️ Dashboard-Specific Security Notes

1. **Firebase config is public**: The `firebaseConfig` object in `src/firebase.js` is meant to be public — it's not a secret. Firestore Security Rules enforce the actual security, not the API key.

2. **Admin check happens twice**: 
   - In `Login.jsx` — check `isAdmin` from Firestore before allowing navigation
   - In Firestore Rules — enforce admin-only access at the database level (already done)
   
   Both layers are needed. The Login check provides UX (shows error to non-admins). The Rules provide actual security (blocks data access even if someone bypasses the UI).

3. **Remove `localStorage.adminToken`**: The old JWT approach is replaced by Firebase's built-in auth persistence. Firebase Auth automatically persists the session in `indexedDB` — you don't need to manually store tokens.

---

## 6. Complete File Change List

| File | Changes | Status |
|------|---------|--------|
| **[NEW]** `src/firebase.js` | Firebase initialization & exports | ✅ Done |
| `src/context/AuthContext.jsx` | Auth state persistence & session verification | ✅ Done |
| `src/App.jsx` | Replace `localStorage.adminToken` with `AuthContext` + `ProtectedRoute` | ✅ Done |
| `src/pages/Login.jsx` | Replace `fetch('/auth/login')` with `signInWithEmailAndPassword` + Firestore admin check | ✅ Done |
| `src/pages/home.jsx` | Replace `fetch('/admin/posts')` with Firestore query; fix `creatorId`/`creatorName`; handle Timestamps | ✅ Done |
| `src/pages/Reports.jsx` | Replace fetch with Firestore query; replace PATCH with `updateDoc`; fix image URLs | ✅ Done |
| `src/pages/Profile.jsx` | Fix image URL (remove `localhost:8080/` prefix); handle Timestamp dates | ✅ Done |
| `src/components/Sidebar.jsx` | Added logout button integrated with `AuthContext` | ✅ Done |
| `package.json` | Renamed to `hai-dashboard` & added `firebase` dependency | ✅ Done |
| `firebase.json` (project root) | Added `hosting` section pointing to `hai-dashboard/dist` | ✅ Done |

---

## 7. Migration Order

```
Phase D-0: Install Firebase SDK & Config        ██████████  (COMPLETED)
Phase D-1: Replace Login Auth                   ██████████  (COMPLETED)
Phase D-2: Replace Home Data Fetching           ██████████  (COMPLETED)
Phase D-3: Replace Reports Data Fetching        ██████████  (COMPLETED)
Phase D-4: Fix Report Details Page              ██████████  (COMPLETED)
Phase D-5: Build & Deploy to Firebase Hosting   ██████████  (COMPLETED)
                                                ─────────────
                                       Status:  ALL PHASES COMPLETE
                                       Cost:    $0 (Firebase Spark free tier)
```

---

## 8. Testing Checklist

After each phase, verify:

- [x] **Login**: Admin can log in; non-admin users see error and can't access dashboard
- [x] **Home stats**: New/fixed/review counts match actual Firestore data
- [x] **Urgent reports**: Shows the 4 most recent "قيد المراجعه" reports
- [x] **Leaders board**: Correctly calculates users with 4+ reports
- [x] **Geo clustering**: Correctly identifies reports in same geographic area
- [x] **Reports table**: All reports load with correct images (Cloudinary CDN URLs)
- [x] **Status update**: Changing dropdown updates Firestore AND the mobile app sees the change
- [x] **Report details**: Image loads, map shows correct location, reverse geocoding works
- [x] **Firebase Hosting**: Dashboard accessible at `https://hai-app-eg.web.app`

---

## 9. Cost Summary

| Service | Usage | Cost |
|---------|-------|------|
| Firebase Hosting | Static React app (~1 MB build) | **Free** (10 GB storage, 360 MB/day) |
| Firebase Auth | Admin login (1-5 users) | **Free** (50K MAU limit) |
| Firestore Reads | Dashboard loads (~50-200 reads/session) | **Free** (50K reads/day) |
| Firestore Writes | Status updates (~10-50/day) | **Free** (20K writes/day) |
| **Total** | | **$0/month** |
