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
