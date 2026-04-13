const express = require('express');
const router = express.Router();

router.get('/feed', (req, res) => {
  const limit = Math.min(parseInt(req.query.limit) || 20, 50);

  const numbers = req.db.prepare(`
    SELECT 
      p.number,
      p.spam_score,
      p.total_reports,
      p.unique_reporters,
      p.category,
      p.operator_name,
      p.last_reported_at,
      p.is_verified_spam,
      (SELECT COUNT(*) FROM reports r 
       WHERE r.phone_number_id = p.id 
       AND r.created_at > datetime('now', '-1 day')) as reports_today
    FROM phone_numbers p
    WHERE p.spam_score > 30
    ORDER BY p.last_reported_at DESC
    LIMIT ?
  `).all(limit);

  const formatted = numbers.map(n => ({
    number_masked: maskNumber(n.number),
    number_full: n.number,
    spam_score: n.spam_score,
    total_reports: n.total_reports,
    unique_reporters: n.unique_reporters || 0,
    reports_today: n.reports_today,
    category: n.category,
    category_label: getCategoryLabel(n.category),
    operator_name: n.operator_name,
    last_reported_at: n.last_reported_at,
    is_verified_spam: !!n.is_verified_spam,
    trend: n.reports_today > 5 ? 'rising' : 'stable'
  }));

  res.json({
    reports: formatted,
    total: formatted.length,
    timestamp: new Date().toISOString()
  });
});

router.get('/stats', (req, res) => {
  const totalNumbers = req.db.prepare('SELECT COUNT(*) as n FROM phone_numbers').get();
  const totalReports = req.db.prepare('SELECT COUNT(*) as n FROM reports').get();
  const highRisk = req.db.prepare('SELECT COUNT(*) as n FROM phone_numbers WHERE spam_score >= 70').get();

  const topCategories = req.db.prepare(`
    SELECT category, COUNT(*) as count 
    FROM phone_numbers 
    WHERE category IS NOT NULL
    GROUP BY category 
    ORDER BY count DESC 
    LIMIT 5
  `).all();

  res.json({
    total_numbers_tracked: totalNumbers.n,
    total_reports: totalReports.n,
    high_risk_numbers: highRisk.n,
    top_categories: topCategories,
    timestamp: new Date().toISOString()
  });
});

function maskNumber(number) {
  if (number.length > 8) {
    return number.substring(0, number.length - 7) + '****' + number.substring(number.length - 3);
  }
  return number;
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
  return labels[category] || 'Spam generico';
}

module.exports = router;
