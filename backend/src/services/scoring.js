/**
 * CallGuard Score Engine
 * Calcola lo spam score (0-100) basandosi su più segnali
 */

function recalculateScore(db, phoneNumberId) {
  const phone = db.prepare('SELECT * FROM phone_numbers WHERE id = ?').get(phoneNumberId);
  if (!phone) return 0;

  // 1. Report score (40%) — basato su numero di segnalazioni
  const reportScore = Math.min(100, phone.total_reports * 5);

  // 2. Velocity score (25%) — segnalazioni nelle ultime 24h
  const recentReports = db.prepare(`
    SELECT COUNT(*) as count FROM reports 
    WHERE phone_number_id = ? AND created_at > datetime('now', '-1 day')
  `).get(phoneNumberId);
  const velocityScore = Math.min(100, recentReports.count * 15);

  // 3. Diversity score (20%) — quanti device diversi hanno segnalato
  const uniqueDevices = db.prepare(`
    SELECT COUNT(DISTINCT device_hash) as count FROM reports 
    WHERE phone_number_id = ?
  `).get(phoneNumberId);
  const diversityScore = Math.min(100, uniqueDevices.count * 10);

  // 4. Prefix score (10%) — rischio del prefisso
  const prefixScore = getPrefixScore(db, phone.number);

  // 5. Category bonus (5%) — categorie ad alto rischio
  const categoryBonus = getCategoryBonus(phone.category);

  // Calcolo finale pesato
  const finalScore = Math.round(
    reportScore * 0.40 +
    velocityScore * 0.25 +
    diversityScore * 0.20 +
    prefixScore * 0.10 +
    categoryBonus * 0.05
  );

  // Clamp tra 0 e 100
  const clampedScore = Math.max(0, Math.min(100, finalScore));

  // Aggiorna nel database
  db.prepare(`
    UPDATE phone_numbers 
    SET spam_score = ?, updated_at = datetime('now')
    WHERE id = ?
  `).run(clampedScore, phoneNumberId);

  return clampedScore;
}

function getPrefixScore(db, number) {
  const prefixes = db.prepare(
    'SELECT * FROM prefix_patterns ORDER BY LENGTH(prefix) DESC'
  ).all();

  for (const p of prefixes) {
    if (number.startsWith(p.prefix)) {
      return p.risk_level;
    }
  }
  return 20; // default per prefissi sconosciuti
}

function getCategoryBonus(category) {
  const highRisk = {
    'truffa': 100,
    'telemarketing_energia': 60,
    'telemarketing_telefonia': 50,
    'telemarketing_assicurazioni': 50,
    'telemarketing': 40,
    'sondaggio': 20,
  };
  return highRisk[category] || 30;
}

function calculateSpamScore(phoneData) {
  // Versione semplificata per lookup senza ricalcolo completo
  return phoneData.spam_score;
}

module.exports = { recalculateScore, calculateSpamScore };
