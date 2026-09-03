import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { signInWithEmailAndPassword } from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';
import { auth, db } from '../firebase';
import './Login.css';

const Login = () => {
  const [identifier, setIdentifier] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const navigate = useNavigate();

  const handleLogin = async (e) => {
    e.preventDefault();
    setError('');
    setIsLoading(true);

    try {
      const credential = await signInWithEmailAndPassword(auth, identifier.trim(), password);
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
      console.error('Login error:', err);
      if (
        err.code === 'auth/user-not-found' ||
        err.code === 'auth/wrong-password' ||
        err.code === 'auth/invalid-credential'
      ) {
        setError('بيانات الدخول غير صحيحة');
      } else if (err.code === 'auth/invalid-email') {
        setError('صيغة البريد الإلكتروني غير صحيحة');
      } else if (err.code === 'auth/too-many-requests') {
        setError('تم حظر المحاولات مؤقتاً لكثرة المحاولات الخاطئة. حاول لاحقاً');
      } else {
        setError('بيانات الدخول غير صحيحة');
      }
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="login-page-wrapper">
      <div className="login-card">
        <h1>مرحباً بك !</h1>
        <p>يرجى تسجيل الدخول في نظام حي لتتمكن من العمل في النظام</p>

        {error && <p style={{ color: 'red', marginBottom: '10px', fontSize: '14px' }}>{error}</p>}

        <form onSubmit={handleLogin}>
          <div className="field-container">
            <label>البريد الإلكتروني</label>
            <input 
              type="email" 
              placeholder="ادخل البريد الإلكتروني الخاص بك...." 
              value={identifier}
              onChange={(e) => setIdentifier(e.target.value)}
              required
            />
          </div>

          <div className="field-container">
            <label>ادخل كلمه السر الخاصه بك....</label>
            <input 
              type="password" 
              placeholder="ادخل كلمه السر الخاصه بك...." 
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </div>

          <button type="submit" className="login-action-btn" disabled={isLoading}>
            {isLoading ? 'جاري التحقق...' : 'تسجيل الدخول'}
          </button>

          <div className="remember-option">
             <label htmlFor="remember">تذكرني لاحقاً</label>
             <input type="checkbox" id="remember" />
          </div>
        </form>
      </div>
    </div>
  );
};

export default Login;