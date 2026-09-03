import React, { useState, useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import './Profile.css';

const Profile = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const reportData = location.state?.report;
  const [geoDistrict, setGeoDistrict] = useState("جاري تحديد الموقع...");
  const lat = reportData?.location?.lat;
  const long = reportData?.location?.long;

  useEffect(() => {
    const fetchAddress = async () => {
      if (lat && long) {
        try {
          const response = await fetch(
            `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${long}&accept-language=ar`
          );
          const data = await response.json();
          
          if (data && data.display_name) {
            const addressParts = data.display_name.split(',');
            const filteredParts = addressParts.filter(part => isNaN(part.trim()));
            const cleanAddress = filteredParts.slice(0, 3).join('، ');
            setGeoDistrict(cleanAddress); 
          }
        } catch (error) {
          console.error("Error:", error);
          setGeoDistrict("تعذر جلب العنوان التفصيلي");
        }
      } else {
        setGeoDistrict("لم يتم تحديد إحداثيات");
      }
    };
    fetchAddress();
  }, [lat, long]);

  if (!reportData) {
    return (
      <div className="profile-error-page" dir="rtl" style={{ textAlign: 'center', padding: '100px' }}>
        <h2>عفواً، لا توجد بيانات لعرضها!</h2>
        <button onClick={() => navigate(-1)} style={{ marginTop: '20px', padding: '10px 20px', cursor: 'pointer' }}>
          العودة للخلف
        </button>
      </div>
    );
  }

  const mapUrl = `https://www.openstreetmap.org/export/embed.html?bbox=${long - 0.005}%2C${lat - 0.005}%2C${long + 0.005}%2C${lat + 0.005}&layer=mapnik&marker=${lat}%2C${long}`;

  return (
    <div className="profile-wrapper-fullscreen" dir="rtl">
      <header className="profile-header-clean">
        <div className="header-titles">
          <h2>تفاصيل البلاغ</h2>
          <p>بيانات البلاغ المختار والموقع الجغرافي.</p>
        </div>
        <div className="header-actions-clean">
          <div className="user-avatar">
            <i className="fas fa-user avatar-icon"></i>
          </div>
        </div>
      </header>

      <div className="profile-content-grid">
        <div className="card-orange-info">
          <div className="avatar-large-wrapper">
            <div className="avatar-large-clean">
              {reportData.imageUrl ? (
                <img 
                  src={reportData.imageUrl} 
                  alt="متابعة البلاغ" 
                  style={{ width: '100%', maxHeight: '180px', borderRadius: '12px', objectFit: 'cover' }}
                  onError={(e) => { e.target.style.display = 'none'; e.target.nextSibling.style.display = 'block'; }}
                />
              ) : null}
              <i className="fas fa-file-alt avatar-icon" style={{ display: reportData.imageUrl ? 'none' : 'block', fontSize: '4rem', color: '#ffffff', opacity: 0.7 }}></i>
            </div>
          </div>

          <h2 className="emp-name">{geoDistrict}</h2>

          <div className="emp-details-grid">
            <div className="detail-item">
              <span className="label">حالة البلاغ:</span> 
              <span className="value">{reportData.status || "قيد المراجعه"}</span>
            </div>
            <div className="detail-item">
              <span className="label">الحي / المنطقة:</span> 
              <span className="value">{geoDistrict}</span>
            </div>
            <div className="detail-item">
              <span className="label">رقم البلاغ:</span> 
              <span className="value">#{reportData._id?.slice(-9)}</span>
            </div>
            {reportData.createdAt && (
              <div className="detail-item">
                <span className="label">تاريخ البلاغ:</span> 
                <span className="value">
                  {reportData.createdAt?.toDate
                    ? reportData.createdAt.toDate().toLocaleDateString('ar-EG')
                    : new Date(reportData.createdAt).toLocaleDateString('ar-EG')}
                </span>
              </div>
            )}
          </div>

          <div className="emp-tasks-clean">
            <h3>عنوان المشكلة</h3>
            <p style={{ padding: '10px', color: '#444' }}>
              {reportData.title || "لا يوجد وصف مفصل للبلاغ."}
            </p>
          </div>
        </div>

        <div className="card-map-container">
          <div className="map-wrapper">
            {lat && long ? (
              <iframe
                title="موقع البلاغ الجغرافي"
                width="100%"
                height="100%"
                frameBorder="0"
                scrolling="no"
                marginHeight="0"
                marginWidth="0"
                src={mapUrl}
              ></iframe>
            ) : (
              <div className="no-map-data">لا توجد إحداثيات متوفرة لعرض الخريطة</div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default Profile;