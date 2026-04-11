import { useState } from 'react'
import SpamBadge from '../components/SpamBadge'

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000'

function Search() {
  const [number, setNumber] = useState('')
  const [result, setResult] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  const handleSearch = async (e) => {
    e.preventDefault()
    if (!number.trim()) return

    setLoading(true)
    setError(null)
    setResult(null)

    try {
      let searchNumber = number.trim()
      if (!searchNumber.startsWith('+')) {
        searchNumber = '+39' + searchNumber
      }

      const res = await fetch(`${API_URL}/api/lookup/${encodeURIComponent(searchNumber)}`)
      const data = await res.json()
      setResult(data)
    } catch (err) {
      setError('Impossibile contattare il server. Verifica che il backend sia attivo.')
    } finally {
      setLoading(false)
    }
  }

  const getScoreClass = (score) => {
    if (score >= 70) return 'danger'
    if (score >= 40) return 'warning'
    if (score > 0) return 'safe'
    return 'unknown'
  }

  return (
    <div>
      <form onSubmit={handleSearch}>
        <div className="search-box">
          <span className="search-icon">🔍</span>
          <input
            className="search-input"
            type="tel"
            placeholder="Inserisci numero di telefono..."
            value={number}
            onChange={(e) => setNumber(e.target.value)}
          />
        </div>
        <button className="search-btn" type="submit" disabled={loading || !number.trim()}>
          {loading ? 'Ricerca in corso...' : 'Cerca numero'}
        </button>
      </form>

      {error && <div className="error-msg">{error}</div>}

      {result && (
        <div className="result-card">
          <div className="result-header" style={{
            background: result.found 
              ? (result.spam_score >= 70 ? 'var(--red-light)' : result.spam_score >= 40 ? 'var(--yellow-light)' : 'var(--green-light)')
              : 'var(--gray-100)'
          }}>
            <div className="result-number">
              📞 {result.number}
            </div>
            <div className={`score-big ${getScoreClass(result.spam_score)}`}>
              {result.found ? result.spam_score : '?'}
            </div>
            <div className="score-label">
              {result.found ? 'spam score su 100' : 'nessuno score disponibile'}
            </div>
            <div style={{marginTop: 12}}>
              <SpamBadge score={result.spam_score} found={result.found} />
            </div>
          </div>

          <div className="result-details">
            {result.found ? (
              <>
                <div className="detail-row">
                  <span className="detail-label">Categoria</span>
                  <span className="detail-value">{result.category || '—'}</span>
                </div>
                <div className="detail-row">
                  <span className="detail-label">Segnalazioni totali</span>
                  <span className="detail-value">{result.total_reports}</span>
                </div>
                <div className="detail-row">
                  <span className="detail-label">Segnalazioni oggi</span>
                  <span className="detail-value">{result.recent_reports_24h}</span>
                </div>
                <div className="detail-row">
                  <span className="detail-label">Operatore</span>
                  <span className="detail-value">{result.operator_name || 'Sconosciuto'}</span>
                </div>
                <div className="detail-row">
                  <span className="detail-label">Azione consigliata</span>
                  <span className="detail-value" style={{
                    color: result.action_suggested === 'block' ? 'var(--red)' 
                         : result.action_suggested === 'warn' ? 'var(--yellow)' 
                         : 'var(--green)'
                  }}>
                    {result.action_suggested === 'block' ? '🚫 Blocca' 
                     : result.action_suggested === 'warn' ? '⚠️ Attenzione' 
                     : '✅ OK'}
                  </span>
                </div>
              </>
            ) : (
              <div style={{padding: '12px 0', color: 'var(--gray-500)', fontSize: 14}}>
                <p>Numero non presente nel database</p>
                {result.prefix_risk > 30 && (
                  <p style={{marginTop: 8, color: 'var(--yellow)'}}>
                    ⚠️ Prefisso a rischio medio-alto ({result.prefix_info})
                  </p>
                )}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  )
}

export default Search
