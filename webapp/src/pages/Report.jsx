import { useState } from 'react'

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000'

function Report() {
  const [form, setForm] = useState({
    phone_number: '',
    report_type: 'spam',
    category: '',
    description: ''
  })
  const [loading, setLoading] = useState(false)
  const [success, setSuccess] = useState(null)
  const [error, setError] = useState(null)

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!form.phone_number.trim()) return

    setLoading(true)
    setError(null)
    setSuccess(null)

    try {
      let number = form.phone_number.trim()
      if (!number.startsWith('+')) {
        number = '+39' + number
      }

      const res = await fetch(`${API_URL}/api/report`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ...form, phone_number: number })
      })

      const data = await res.json()

      if (res.ok) {
        setSuccess(data)
        setForm({ phone_number: '', report_type: 'spam', category: '', description: '' })
      } else {
        setError(data.error || 'Errore nella segnalazione')
      }
    } catch (err) {
      setError('Impossibile contattare il server.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div>
      <h2 className="section-title">
        ⚠️ Segnala un numero
      </h2>

      <form onSubmit={handleSubmit}>
        <div className="form-group">
          <label className="form-label">Numero di telefono *</label>
          <input
            className="form-input"
            type="tel"
            placeholder="+39 333 1234567"
            value={form.phone_number}
            onChange={(e) => setForm({...form, phone_number: e.target.value})}
            required
          />
        </div>

        <div className="form-group">
          <label className="form-label">Tipo di segnalazione *</label>
          <select
            className="form-select"
            value={form.report_type}
            onChange={(e) => setForm({...form, report_type: e.target.value})}
          >
            <option value="spam">Spam generico</option>
            <option value="telemarketing">Telemarketing</option>
            <option value="truffa">Truffa / Phishing</option>
            <option value="sondaggio">Sondaggio</option>
            <option value="legittimo">Numero legittimo (errore)</option>
          </select>
        </div>

        <div className="form-group">
          <label className="form-label">Categoria</label>
          <select
            className="form-select"
            value={form.category}
            onChange={(e) => setForm({...form, category: e.target.value})}
          >
            <option value="">— Seleziona —</option>
            <option value="telemarketing_energia">Energia (luce/gas)</option>
            <option value="telemarketing_telefonia">Telefonia / Internet</option>
            <option value="telemarketing_assicurazioni">Assicurazioni</option>
            <option value="truffa">Truffa / Frode</option>
            <option value="sondaggio">Sondaggio / Ricerca</option>
          </select>
        </div>

        <div className="form-group">
          <label className="form-label">Note (opzionale)</label>
          <textarea
            className="form-textarea"
            placeholder="Es: Voce registrata, offerta cambio fornitore gas..."
            value={form.description}
            onChange={(e) => setForm({...form, description: e.target.value})}
          />
        </div>

        <button className="submit-btn" type="submit" disabled={loading || !form.phone_number.trim()}>
          {loading ? 'Invio in corso...' : '🚨 Invia segnalazione'}
        </button>
      </form>

      {success && (
        <div className="success-msg">
          ✅ Segnalazione registrata! Nuovo spam score: {success.new_spam_score}/100
          ({success.total_reports} segnalazioni totali)
        </div>
      )}

      {error && <div className="error-msg">{error}</div>}
    </div>
  )
}

export default Report
