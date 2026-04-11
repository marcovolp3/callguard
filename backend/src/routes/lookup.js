const express = require('express');
const router = express.Router();
const { calculateSpamScore } = require('../services/scoring');

// GET /api/lookup/:number — cerca un numero di telefono
router.get('/lookup/:number', (req, res) => {
  let { number } = req.params;

  // Normalizza il numero (aggiungi + se mancante)
  if (!number.startsWith('+')) {
    number = '+' + number;
  }

  // Cerca nel database
  const phoneNumber = req.db.prepare(`
    SELECT * FROM phone_numbers WHERE number = ?
  `).get(number);

  if (phoneNumber) {
    // Numero trovato — calcola risk level
    const riskLevel = getRiskLevel(phoneNumber.spam_score);

    // Conta segnalazioni recenti (ultime 24h)
    const recentReports = req.db.prepare(`
      SELECT COUNT(*) as count FROM reports 
      WHERE phone_number_id = ? AND created_at > datetime('now', '-1 day')
    `).get(phoneNumber.id);

    res.json({
      found: true,
      number: phoneNumber.number,
      spam_score: phoneNumber.spam_score,
      category: phoneNumber.category,
      total_reports: phoneNumber.total_reports,
      recent_reports_24h: recentReports.count,
      last_reported_at: phoneNumber.last_reported_at,
      operator_name: phoneNumber.operator_name,
      risk_level: riskLevel,
      is_verified_spam: !!phoneNumber.is_verified_spam,
      action_suggested: getActionSuggestion(phoneNumber.spam_score)
    });
  } else {
    // Numero non trovato — controlla rischio prefisso
    const prefixRisk = getPrefixRisk(req.db, number);

    res.json({
      found: false,
      number: number,
      spam_score: 0,
      category: null,
      total_reports: 0,
      risk_level: 'unknown',
      prefix_risk: prefixRisk.risk_level,
      prefix_info: prefixRisk.description,
      action_suggested: 'allow'
    });
  }
});

// GET /api/sync/ios — bulk download per CallKit
router.get('/sync/ios', (req, res) => {
  const since = req.query.since || '2000-01-01';
  const limit = Math.min(parseInt(req.query.limit) || 50000, 100000);

  const numbers = req.db.prepare(`
    SELECT number, spam_score, category 
    FROM phone_numbers 
    WHERE spam_score >= 60 AND updated_at > ?
    ORDER BY spam_score DESC 
    LIMIT ?
  `).all(since, limit);

  const formatted = numbers.map(n => ({
    number: n.number,
    spam_score: n.spam_score,
    label: getCategoryLabel(n.category)
  }));

  res.json({
    numbers: formatted,
    total: formatted.length,
    sync_timestamp: new Date().toISOString()
  });
});

function getRiskLevel(score) {
  if (score >= 90) return 'verified_spam';
  if (score >= 70) return 'high';
  if (score >= 40) return 'medium';
  return 'low';
}

function getActionSuggestion(score) {
  if (score >= 85) return 'block';
  if (score >= 60) return 'warn';
  return 'allow';
}

function getPrefixRisk(db, number) {
  // Cerca il prefisso più lungo che corrisponde
  const prefixes = db.prepare(`
    SELECT * FROM prefix_patterns ORDER BY LENGTH(prefix) DESC
  `).all();

  for (const p of prefixes) {
    if (number.startsWith(p.prefix)) {
      return p;
    }
  }
  return { risk_level: 0, description: 'Prefisso non classificato' };
}

function getCategoryLabel(category) {
  const labels = {
    'telemarketing_energia': 'Telemarketing energia',
    'telemarketing_telefonia': 'Telemarketing telefonia',
    'telemarketing_assicurazioni': 'Telemarketing assicurazioni',
    'telemarketing': 'Telemarketing',
    'truffa': 'Sospetta truffa',
    'sondaggio': 'Sondaggio',
  };
  return labels[category] || 'Spam';
}

module.exports = router;
