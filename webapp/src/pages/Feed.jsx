import { useState, useEffect } from 'react'

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000'

function Feed() {
  const [feed, setFeed] = useState([])
  const [stats, setStats] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    loadData()
  }, [])

  const loadData = async () => {
    try {
      const [feedRes, statsRes] = await Promise.all([
        fetch(`${API_URL}/api/feed?limit=20`),
        fetch(`${API_URL}/api/stats`)
      ])
      const feedData = await feedRes.json()
      const statsData = await statsRes.json()
      setFeed(feedData.reports)
      setStats(statsData)
    } catch (err) {
      console.error('Errore caricamento feed:', err)
    } finally {
      setLoading(false)
    }
  }

  const getScoreClass = (score) => {
    if (score >= 70) return 'danger'
    if (score >= 40) return 'warning'
    return 'safe'
  }

  if (loading) {
    return <div className="loading">Caricamento...</div>
  }

  return (
    <div>
      {stats && (
        <div className="stats-bar">
          <div className="stat-chip">
            <div className="stat-value">{stats.total_numbers_tracked}</div>
            <div className="stat-label">Numeri tracciati</div>
          </div>
          <div className="stat-chip">
            <div className="stat-value">{stats.total_reports}</div>
            <div className="stat-label">Segnalazioni</div>
          </div>
          <div className="stat-chip">
            <div className="stat-value">{stats.high_risk_numbers}</div>
            <div className="stat-label">Alto rischio</div>
          </div>
        </div>
      )}

      <h2 className="section-title">
        📈 Numeri più segnalati
      </h2>

      {feed.length === 0 ? (
        <div className="empty-state">Nessuna segnalazione ancora.</div>
      ) : (
        feed.map((item, i) => (
          <div key={i} className="feed-item">
            <div className={`feed-score ${getScoreClass(item.spam_score)}`}>
              {item.spam_score}
            </div>
            <div className="feed-info">
              <div className="feed-number">{item.number_masked}</div>
              <div className="feed-category">
                {item.category_label}
                {item.operator_name && ` · ${item.operator_name}`}
              </div>
            </div>
            <div className="feed-reports">
              <strong>{item.total_reports}</strong>
              segnalazioni
            </div>
          </div>
        ))
      )}
    </div>
  )
}

export default Feed
