import React from 'react';
import { NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const Sidebar = () => {
  const { logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = async () => {
    try {
      await logout();
      navigate('/login');
    } catch (err) {
      console.error('Logout error:', err);
    }
  };

  return (
    <aside className="sidebar">
      <div className="logo-section">
        <i className="fas fa-house logo-icon"></i>
        <h1 className="logo-text">حي</h1>
      </div>

      <nav className="nav-menu">
        <NavLink to="/" className={({ isActive }) => isActive ? "nav-link active" : "nav-link"}>
          <i className="fas fa-house icon"></i>
          <span>الرئيسية</span>
        </NavLink>

        <NavLink to="/details" className={({ isActive }) => isActive ? "nav-link active" : "nav-link"}>
          <i className="fas fa-map-location-dot icon"></i>
          <span>تفاصيل البلاغ</span>
        </NavLink>
        
        <NavLink to="/reports" className={({ isActive }) => isActive ? "nav-link active" : "nav-link"}>
          <i className="fas fa-clipboard-list icon"></i>
          <span>جداول البلاغات</span>
        </NavLink>
      </nav>

      <div className="sidebar-footer">
        <button
          type="button"
          onClick={handleLogout}
          className="nav-link"
          style={{
            background: 'none',
            border: 'none',
            width: '100%',
            cursor: 'pointer',
            textAlign: 'right',
            fontFamily: 'inherit',
            color: '#e53935'
          }}
        >
          <i className="fas fa-right-from-bracket icon" style={{ color: '#e53935' }}></i>
          <span>تسجيل الخروج</span>
        </button>
      </div>
    </aside>
  );
};

export default Sidebar;