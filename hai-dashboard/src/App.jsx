import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import Sidebar from './components/Sidebar';
import Reports from './pages/Reports';
import Home from './pages/home';
import Profile from './pages/Profile';
import Login from './pages/Login'; 
import './pages/Dashboard.css';

const ProtectedRoute = ({ children }) => {
  const { user, isAdmin, loading } = useAuth();

  if (loading) {
    return (
      <div style={{
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        height: '100vh',
        backgroundColor: 'var(--bg-body, #e6e2dd)',
        fontFamily: "'Tajawal', sans-serif"
      }}>
        <div style={{ textAlign: 'center' }}>
          <i className="fas fa-spinner fa-spin" style={{ fontSize: '32px', color: 'var(--primary-orange, #ed6b1f)', marginBottom: '12px' }}></i>
          <p style={{ fontSize: '16px', color: '#555' }}>جاري التحقق من الجلسة...</p>
        </div>
      </div>
    );
  }

  if (!user || !isAdmin) {
    return <Navigate to="/login" replace />;
  }

  return children;
};

const PublicRoute = ({ children }) => {
  const { user, isAdmin, loading } = useAuth();
  if (loading) return null;
  if (user && isAdmin) {
    return <Navigate to="/" replace />;
  }
  return children;
};

const DashboardLayout = ({ children }) => (
  <div className="dashboard-wrapper" dir="rtl">
    <Sidebar />
    <main className="main-content">
      {children}
    </main>
  </div>
);

function App() {
  return (
    <AuthProvider>
      <Router>
        <Routes>
          <Route path="/login" element={
            <PublicRoute>
              <Login />
            </PublicRoute>
          } />

          <Route path="/" element={
            <ProtectedRoute>
              <DashboardLayout> <Home /> </DashboardLayout>
            </ProtectedRoute>
          } />

          <Route path="/reports" element={
            <ProtectedRoute>
              <DashboardLayout> <Reports /> </DashboardLayout>
            </ProtectedRoute>
          } />

          <Route path="/details" element={
            <ProtectedRoute>
              <DashboardLayout> <Profile /> </DashboardLayout>
            </ProtectedRoute>
          } />

          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </Router>
    </AuthProvider>
  );
} 
export default App;