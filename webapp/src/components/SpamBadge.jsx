function SpamBadge({ score, found }) {
  if (!found) {
    return (
      <span className="spam-badge unknown">
        ❓ Numero sconosciuto
      </span>
    )
  }

  if (score >= 70) {
    return (
      <span className="spam-badge danger">
        🚫 Spam confermato
      </span>
    )
  }

  if (score >= 40) {
    return (
      <span className="spam-badge warning">
        ⚠️ Sospetto spam
      </span>
    )
  }

  return (
    <span className="spam-badge safe">
      ✅ Probabilmente sicuro
    </span>
  )
}

export default SpamBadge
