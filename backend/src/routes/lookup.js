const express = require('express');
const router = express.Router();
const { calculateSpamScore } = require('../services/scoring');

router.get('/lookup/:number', (req, res) => {
  let { number } = req.params;

  if (!number.startsWith('+')) {
    number = '+' + number;
  }

  const phoneNumber = req.db.prepare(
    'SELECT * FROM phone_numbers WHERE number = ?'
  ).get(number);

  if (phoneNumber) {
    const riskLevel = getRiskLevel(phoneNumber.spam_score);

    const recentReports = req.db.prepare(
      "SELECT COUNT(*) as count FROM reports WHERE phone_number_id = ? AND created_at > datetime('now', '-1 day')"
    ).get(phoneNumber.id);

    const uniqueReporters = req.db.prepare(
      'SELECT COUNT(DISTINCT device_hash) as count FROM reports WHERE phone_number_id = ?'
    ).get(phoneNumber.id);

    res.json({
      found: true,
      number: phoneNumber.number,
      spam_score: phoneNumber.spam_score,
      category: phoneNumber.category,
      total_reports: phoneNumber.total_reports,
      unique_reporters: uniqueReporters.count,
      recent_reports_24h: recentReports.count,
      last_reported_at: phoneNumber.last_reported_at,
      operator_name: phoneNumber.operator_name,
      risk_level: riskLevel,
      is_verified_spam: !!phoneNumber.is_verified_spam,
      action_suggested: getActionSuggestion(phoneNumber.spam_score)
    });
  } else {
    const prefixRisk = getPrefixRisk(req.db, number);

    res.json({
      found: false,
      number: number,
      spam_score: 0,
      category: null,
      total_reports: 0,
      unique_reporters: 0,
      risk_level: 'unknown',
      prefix_risk: prefixRisk.risk_level,
      prefix_info: prefixRisk.description,
      action_suggested: 'allow'
    });
  }
});

// Sync per CallKit — solo numeri con consenso sufficiente
// Soglia: spam_score >= 60 E almeno 3 segnalatori diversi
// Oppure spam_score >= 90 (seed data / verificati)
router.get('/sync/ios', (req, res) => {
  const since = req.query.since || '2000-01-01';
  const limit = Math.min(parseInt(req.query.limit) || 50000, 100000);
  const minScore = parseInt(req.query.min_score) || 60;

  const numbers = req.db.prepare(
    'SELECT number, spam_score, category FROM phone_numbers WHERE ((spam_score >= ? AND unique_reporters >= 3) OR spam_score >= 90) AND updated_at > ? ORDER BY spam_score DESC LIMIT ?'
  ).all(minScore, since, limit);

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
  const prefixes = db.prepare(
    'SELECT * FROM prefix_patterns ORDER BY LENGTH(prefix) DESC'
  ).all();

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
