import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { collection, getDocs, query, orderBy } from 'firebase/firestore';
import { db } from '../firebase';
import './Home.css';

const getDate = (ts) => {
  if (!ts) return new Date(0);
  if (typeof ts?.toDate === 'function') return ts.toDate();
  return new Date(ts);
};

const Home = () => {
  const [counts, setCounts] = useState({
    newCount: 0,
    fixedCount: 0,
    reviewCount: 0
  });

  const [urgentReports, setUrgentReports] = useState([]);
  const [leaders, setLeaders] = useState([]);
  const [reportsInSamePoint, setReportsInSamePoint] = useState("");
  const [weeklyChange, setWeeklyChange] = useState({
    percent: '0%',
    isUp: true
  });
  const [areaManagers, setAreaManagers] = useState([]);
  const navigate = useNavigate();

  useEffect(() => {
    const fetchPosts = async () => {
      try {
        const q = query(collection(db, 'posts'), orderBy('createdAt', 'desc'));
        const snapshot = await getDocs(q);
        const allPosts = snapshot.docs.map(doc => ({
          ...doc.data(),
          _id: doc.id,
          id: doc.id,
        }));

        setCounts({
          newCount: allPosts.filter(p => p.status?.trim() === 'قيد المراجعه' || p.status?.trim() === 'جديد').length,
          fixedCount: allPosts.filter(p => p.status?.trim() === 'تم التصليح').length,
          reviewCount: allPosts.filter(p => p.status?.trim() === 'تحت التصليح').length
        });

        // Calculate week-over-week change for new reports using createdAt (last 7 days vs prior 7 days)
        const now = Date.now();
        const sevenDaysMs = 7 * 24 * 60 * 60 * 1000;
        const fourteenDaysMs = 14 * 24 * 60 * 60 * 1000;

        const currentWeekCount = allPosts.filter(p => {
          const t = getDate(p.createdAt).getTime();
          return t >= (now - sevenDaysMs) && t <= now;
        }).length;

        const previousWeekCount = allPosts.filter(p => {
          const t = getDate(p.createdAt).getTime();
          return t >= (now - fourteenDaysMs) && t < (now - sevenDaysMs);
        }).length;

        let calculatedPercent = '0%';
        let calculatedIsUp = true;

        if (previousWeekCount === 0) {
          if (currentWeekCount > 0) {
            calculatedPercent = '100%';
            calculatedIsUp = true;
          } else {
            calculatedPercent = '0%';
            calculatedIsUp = true;
          }
        } else {
          const diff = currentWeekCount - previousWeekCount;
          const changeRatio = Math.round((Math.abs(diff) / previousWeekCount) * 100);
          calculatedPercent = `${changeRatio}%`;
          calculatedIsUp = diff >= 0;
        }

        setWeeklyChange({
          percent: calculatedPercent,
          isUp: calculatedIsUp
        });

        const urgent = allPosts
          .filter(p => p.status?.trim() === 'قيد المراجعه')
          .sort((a, b) => getDate(b.updatedAt || b.createdAt) - getDate(a.updatedAt || a.createdAt))
          .slice(0, 4);

        setUrgentReports(urgent);

        const creatorMap = {};
        allPosts.forEach(p => {
          const creatorId = p.creatorId || p.creator?._id || p.creator?.id;
          if (creatorId) {
            if (!creatorMap[creatorId]) {
              creatorMap[creatorId] = {
                _id: creatorId,
                name: p.creatorName || p.creator?.name || 'قائد ميداني',
                postCount: 0
              };
            }
            creatorMap[creatorId].postCount += 1;
          }
        });

        const calculatedLeaders = Object.values(creatorMap)
          .filter(user => user.postCount >= 4)
          .map(user => ({
            _id: user._id,
            name: user.name,
            stars: Math.min(5, user.postCount)
          }));

        setLeaders(calculatedLeaders);

        const activePosts = allPosts.filter(p => p.status?.trim() !== 'تم التصليح');
        const locationMap = {};

        activePosts.forEach(post => {
          const lat = post.location?.lat;
          const long = post.location?.long;

          if (lat && long) {
            const latRounded = Number(lat).toFixed(2);
            const longRounded = Number(long).toFixed(2);
            const key = `${latRounded},${longRounded}`;

            if (!locationMap[key]) {
              locationMap[key] = {
                count: 0,
                title: post.title || 'بلاغ في منطقة تكدس'
              };
            }
            locationMap[key].count += 1;
          }
        });

        const sortedLocations = Object.values(locationMap).sort((a, b) => b.count - a.count);

        let reportsInSamePointMessage = "الأمور مستقرة حالياً، ولا توجد مناطق بها تكدس ملحوظ للبلاغات في نفس النطاق الجغرافي.";
        if (sortedLocations.length > 0 && sortedLocations[0].count > 1) {
          const topReportsInSamePoint = sortedLocations[0];
          reportsInSamePointMessage = `تنبيه عاجل: تم رصد تكدس عالٍ للبلاغات! يوجد حالياً (${topReportsInSamePoint.count} بلاغات) في نفس النطاق الجغرافي (نوع البلاغ: "${topReportsInSamePoint.title}"). يُنصح بتوجيه فرقة صيانة موحدة لهذه المنطقة لإنهاء كافة المشاكل دفعة واحدة.`;
        }

        setReportsInSamePoint(reportsInSamePointMessage);

        try {
          const empSnapshot = await getDocs(collection(db, 'employees'));
          const managers = empSnapshot.docs.map(d => {
            const data = d.data();
            const task = Array.isArray(data.tasks) && data.tasks.length > 0
              ? data.tasks[0]
              : (data.role || 'متابعة ميدانية');

            let statusClass = 'offline';
            if (data.statusType === 'success' || data.status === 'نشط' || data.status === 'في جولة') {
              statusClass = 'success';
            } else if (data.statusType === 'warning' || data.status === 'راحه') {
              statusClass = 'warning';
            } else if (data.statusType === 'danger' || data.status === 'موقوف' || data.status === 'اجازه' || data.status === 'غير متاح') {
              statusClass = 'danger';
            }

            return {
              _id: d.id,
              name: data.name || 'موظف',
              area: data.district || 'غير محدد',
              task,
              status: data.status || 'غير متاح',
              statusClass
            };
          });
          setAreaManagers(managers);
        } catch (empErr) {
          console.error("Error fetching employees:", empErr);
        }
      } catch (err) {
        console.error("Error fetching data:", err);
      }
    };

    fetchPosts();
  }, []);

  const statsData = [
    {
      title: 'عدد البلاغات الجديدة',
      count: counts.newCount,
      suffix: 'بلاغ',
      percent: weeklyChange.percent,
      isUp: weeklyChange.isUp,
      color: '#f84b4b',
      path: weeklyChange.isUp
        ? 'M0,30 Q15,10 30,25 T60,15 T100,25'
        : 'M0,15 Q15,5 30,25 T60,10 T100,30'
    },
    {
      title: 'بلاغات تم اصلاحها',
      count: counts.fixedCount,
      suffix: 'بلاغ',
      percent: null,
      isUp: true,
      color: '#28c76f',
      path: 'M0,25 Q15,35 30,10 T60,20 T100,5'
    },
    {
      title: 'بلاغات قيد المراجعة',
      count: counts.reviewCount,
      suffix: 'بلاغ',
      percent: null,
      isUp: false,
      color: '#ff9f43',
      path: 'M0,15 Q15,5 30,25 T60,10 T100,30'
    },
  ];

  const renderStars = (count) => {
    return Array.from({ length: 5 }).map((_, i) => (
      <i key={i} className={i < count ? "fas fa-star star-filled" : "far fa-star star-empty"}></i>
    ));
  };

  return (
    <div className="home-page-container" dir="rtl">
      <header className="top-header">
        <div className="header-titles">
          <h2>الصفحة الرئيسية</h2>
          <p>لوحة متابعة مركزية لعرض مؤشرات بلاغات ومستوى الاستجابة.</p>
        </div>
        <div className="header-actions">
          <div className="user-avatar">
            <i className="fas fa-user avatar-icon"></i>
          </div>
        </div>
      </header>

      <div className="dashboard-grid custom-scrollbar">  
        <div className="main-column">
          <h3 className="section-title-home">مؤشرات أداء منظومة البلاغات</h3>
          <div className="stats-cards-row">
            {statsData.map((stat, index) => (
              <div className="stat-card" key={index}>
                <p className="stat-title">{stat.title}</p>
                <div className="stat-numbers">
                  <h2>{stat.count}</h2>
                  <span>{stat.suffix}</span>
                </div>
                <div className="mini-chart">
                  <svg viewBox="0 0 100 40" preserveAspectRatio="none">
                    <path d={stat.path} fill="none" stroke={stat.color} strokeWidth="2.5" />
                  </svg>
                </div>
                {stat.percent !== null && stat.percent !== undefined ? (
                  <div className={`stat-percent ${stat.isUp ? 'up' : 'down'}`} style={{ color: stat.color }}>
                    <i className={`fas ${stat.isUp ? 'fa-arrow-trend-up' : 'fa-arrow-trend-down'}`}></i>
                    {' '}{stat.percent} عن الأسبوع الماضي
                  </div>
                ) : (
                  <div className="stat-percent stat-percent-placeholder" style={{ minHeight: '18px' }} aria-hidden="true"></div>
                )}
              </div>
            ))}
          </div>

          <h3 className="section-title-home">المشاكل التي تقع في نطاق جغرافي واحد</h3>
          <div style={{ 
            background: '#f8fafc', 
            borderRight: '5px solid #475569', 
            borderRadius: '12px', 
            padding: '22px', 
            marginBottom: '25px', 
            boxShadow: '0 2px 12px rgba(0, 0, 0, 0.02)' 
          }}>
            <p style={{ 
              fontSize: '15px', 
              color: '#334155', 
              lineHeight: '1.8', 
              margin: '0 0 14px 0', 
              textAlign: 'justify' 
            }}>
              {reportsInSamePoint.includes('تنبيه عاجل') ? (
                <span style={{ color: '#f84b4b', fontWeight: 'bold' }}>
                  <i className="fas fa-triangle-exclamation" style={{ marginLeft: '5px' }}></i> 
                  {reportsInSamePoint}
                </span>
              ) : (
                <span style={{ color: '#28c76f', fontWeight: 'bold' }}>
                  <i className="fas fa-check-circle" style={{ marginLeft: '5px' }}></i> 
                  {reportsInSamePoint}
                </span>
              )}
            </p>
            
          </div>

          <div className="section-header-row">
            <h3 className="section-title-home">مديرو المناطق</h3>
            <span className="show-more-link">عرض المزيد</span>
          </div>

          <div className="managers-table-card">
            <table className="simple-table">
              <thead>
                <tr>
                  <th>اسم المدير</th>
                  <th>المنطقة</th>
                  <th>المهمة</th>
                  <th>الحالة</th>
                </tr>
              </thead>
              <tbody>
                {areaManagers.length > 0 ? (
                  areaManagers.map((manager, idx) => (
                    <tr key={manager._id || idx}>
                      <td className="manager-name-cell">
                        <i className="fas fa-user manager-icon"></i> {manager.name}
                      </td>
                      <td>{manager.area}</td>
                      <td>{manager.task}</td>
                      <td>
                        <span className={`status-badge ${manager.statusClass}`}>{manager.status}</span>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan="4" style={{ padding: '20px', color: '#888' }}>
                      لا توجد بيانات مديرين حالياً.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>

        <div className="side-column">
          <div className="side-card urgent-card">
            <div className="card-header">
              <h3>
                <i className="fas fa-clipboard-list urgent-icon"></i> بلاغات عاجلة
              </h3>
            </div>
            <div className="urgent-list">
              <div className="urgent-list-header">
                <span>نوع البلاغ</span>
                <span>التفاصيل</span>
              </div>
              {urgentReports.map((report, idx) => (
                <div className="urgent-item" key={report._id || idx}>
                  <span className="type-badge">{report.title || 'بلاغ'}</span>
                  <button 
                    className="btn-details"
                    onClick={() => navigate(`/details`, { state: { report } })}
                    style={{
                      background: '#ed6b1fec',
                      color: '#fff',
                      border: 'none',
                      padding: '5px 12px',
                      borderRadius: '8px',
                      cursor: 'pointer',
                      fontSize: '11px',
                      fontWeight: 'bold'
                    }}
                  >
                    التفاصيل
                  </button>
                </div>
              ))}
            </div>
          </div>

          <div className="side-card leaders-card">
            <div className="card-header">
              <h3>القادة الميدانيون</h3>
            </div>
            <div className="leaders-list">
              {leaders.length > 0 ? (
                leaders.map((leader, idx) => (
                  <div className="leader-item" key={leader._id || idx}>
                    <div className="leader-info">
                      <div className="avatar-circle">
                        <i className="fas fa-user"></i>
                      </div>
                      <span className="leader-name">{leader.name}</span>
                    </div>
                    <div className="stars">
                      {renderStars(leader.stars)}
                    </div>
                  </div>
                ))
              ) : (
                <p style={{ textAlign: 'center', fontSize: '12px', color: '#888', padding: '10px' }}>
                  لا يوجد قادة لديهم 4 بلاغات أو أكثر حالياً.
                </p>
              )}
            </div>
          </div>

        </div>
      </div>
    </div>
  );
};

export default Home;