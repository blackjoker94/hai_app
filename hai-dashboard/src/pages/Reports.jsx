import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { collection, getDocs, doc, updateDoc, query, orderBy } from 'firebase/firestore';
import { db } from '../firebase';

const Reports = () => {
  const [reportsData, setReportsData] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [selectedTitle, setSelectedTitle] = useState('الكل'); 
  const navigate = useNavigate();

  useEffect(() => {
    const fetchReports = async () => {
      try {
        const q = query(collection(db, 'posts'), orderBy('createdAt', 'desc'));
        const snapshot = await getDocs(q);
        const posts = snapshot.docs.map(d => ({
          ...d.data(),
          _id: d.id,
          id: d.id
        }));
        setReportsData(posts);
      } catch (err) {
        console.error('Error fetching reports:', err);
      } finally {
        setIsLoading(false);
      }
    };

    fetchReports();
  }, []); 

  if (isLoading) return <p style={{ textAlign: 'center', padding: '20px' }}>جاري تحميل البيانات...</p>;

  const updateStatus = async (postId, newStatus) => {
    try {
      await updateDoc(doc(db, 'posts', postId), { status: newStatus });
      setReportsData(prev => prev.map(p => p._id === postId ? { ...p, status: newStatus } : p));
    } catch (err) {
      console.error('فشل تحديث الحالة:', err);
    }
  };

  const uniqueTitles = ['الكل', ...new Set(reportsData.map(report => report.title || 'بدون عنوان'))];
  const filteredReports = selectedTitle === 'الكل' 
    ? reportsData 
    : reportsData.filter(report => (report.title || 'بدون عنوان') === selectedTitle);

  return (
    <>
      <header className="top-header">
        <div className="header-titles">
          <h2>صفحة البلاغات</h2>
          <p>لوحة متابعة مركزية لعرض جميع البلاغات.</p>
        </div>
        <div className="header-actions">          
          <div className="user-avatar">
            <i className="fas fa-user avatar-icon"></i>
          </div>
        </div>
      </header>
      <div className="modern-filter-container">
        <div className="filter-scroll-area">
          {uniqueTitles.map((title, index) => (
            <button
              key={index}
              onClick={() => setSelectedTitle(title)}
              className={`modern-filter-btn ${selectedTitle === title ? 'active' : ''}`}
            >
              {title}
              {selectedTitle === title && (
                 <span className="badge">
                   {title === 'الكل' ? reportsData.length : reportsData.filter(r => (r.title || 'بدون عنوان') === title).length}
                 </span>
              )}
            </button>
          ))}
        </div>
      </div>

      <div className="section-title">
        <h3>الجدول الرئيسي {selectedTitle !== 'الكل' && `( البلاغات بعنوان: ${selectedTitle})`}</h3>
      </div>

      <div className="table-container">
        <table className="reports-table">
          <thead>
            <tr>
              <th>رقم البلاغ</th>
              <th>صورة البلاغ</th>
              <th>عنوان المشكله</th>
              <th>الحاله</th>
              <th>المزيد</th>
            </tr>
          </thead>
          <tbody>
            {filteredReports.map((report, index) => (
              <tr 
                key={report._id || index} 
                onClick={() => navigate('/details', { state: { report: report } })}
                style={{ cursor: 'pointer' }}
              >
                <td className="text-muted">
                  #{report._id ? report._id.toString().slice(-9) : '0000'}
                </td>

                <td>
                  <div className="report-image-placeholder">
                    {report.imageUrl ? (
  <img
    src={report.imageUrl}
    alt="بلاغ"
    onError={(e) => {
      e.target.onerror = null;
      e.target.remove();
    }}
  />
) : null}
                  </div>
                </td>

                <td className="text-muted">
                  {report.title || "بدون عنوان"} 
                </td>

                <td>
                  <div className="status-cell">
                    <span className={`status-dot ${
                      report.status === 'تم التصليح' ? 'success' :
                      report.status === 'تحت التصليح' ? 'warning' : 'danger'
                    }`}></span>
                    <span className="status-text">{report.status || 'جديد'}</span>
                  </div>
                </td>

                <td>
                  <select
  id={`status-${report._id}`}
  name={`status-${report._id}`}
  className="status-select-input"
  value={report.status || 'قيد المراجعه'}
  onClick={(e) => e.stopPropagation()}
  onChange={(e) => updateStatus(report._id, e.target.value)}
>
                    <option value="قيد المراجعه">قيد المراجعه</option>
                    <option value="تحت التصليح">تحت التصليح</option>
                    <option value="تم التصليح">تم التصليح</option>
                  </select>
                </td>
              </tr>
            ))}
            
            {filteredReports.length === 0 && (
              <tr>
                <td colSpan="5" style={{ textAlign: 'center', padding: '30px', color: '#888' }}>
                  لا توجد بلاغات تندرج تحت هذا العنوان حالياً.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </>
  );
};

export default Reports;