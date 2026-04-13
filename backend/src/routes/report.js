const express = require('express');
const router = express.Router();
const { recalculateScore } = require('../services/scoring');

const MAX_REPORTS_PER_DAY = 20;

function cleanPhoneNumber(number) {
  let cleaned = number.replace(/[\s\-\(\)\.]/g, '');
  if (!cleaned.startsWith('+')) {
    cleaned = '+' + cleaned;
  }
  return cleaned;
}

function isValidPhoneNumber(number) {
  return /^\+\d{8,15}$/.test(number);
}

function getOrCreateDevice(db, deviceHash) {
  let device = db.prepare('SELECT * FROM devices WHERE device_hash = ?').get(deviceHash);

  if (!device) {
    db.prepare(
      "INSERT INTO devices (device_hash, trust_score, total_reports, reports_today, last_report_date) VALUES (?, 50, 0, 0, date('now'))"
    ).run(deviceHash);
    device = db.prepare('SELECT * FROM devices WHERE device_hash = ?').get(deviceHash);
  } else {
    const today = new Date().toISOString().split('T')[0];
    if (device.last_report_date !== today) {
      db.prepare(
        "UPDATE devices SET reports_today = 0, last_report_date = date('now') WHERE id = ?"
      ).run(device.id);
      device.reports_today = 0;
    }
  }

  return device;
}

router.post('/report', (req, res) => {
  const { phone_number, report_type, category, description, call_duration } = req.body;

  if (!phone_number || !report_type) {
    return res.status(400).json({
      error: 'Campi obbligatori: phone_number, report_type'
    });
  }

  const validTypes = ['spam', 'truffa', 'telemarketing', 'sondaggio', 'legittimo'];
  if (!validTypes.includes(report_type)) {
    return res.status(400).json({
      error: 'report_type deve essere uno di: ' + validTypes.join(', ')
    });
  }

  let number = cleanPhoneNumber(phone_number);

  if (!isValidPhoneNumber(number)) {
    return res.status(400).json({
      error: 'Formato numero non valido. Usa formato internazionale es: +393331234567'
    });
  }

  const deviceHash = req.headers['x-device-id'] || 'web_' + Date.now();

  try {
    const device = getOrCreateDevice(req.db, deviceHash);

    if (device.reports_today >= MAX_REPORTS_PER_DAY) {
      return res.status(429).json({
        error: 'Hai raggiunto il limite di ' + MAX_REPORTS_PER_DAY + ' segnalazioni al giorno.'
      });
    }

    let phoneNumber = req.db.prepare('SELECT * FROM phone_numbers WHERE number = ?').get(number);

    if (!phoneNumber) {
      const countryCode = number.startsWith('+39') ? '+39' : number.substring(0, 4);
      const result = req.db.prepare(
        "INSERT INTO phone_numbers (number, country_code, total_reports, unique_reporters, category, last_reported_at) VALUES (?, ?, 1, 1, ?, datetime('now'))"
      ).run(number, countryCode, category || report_type);

      phoneNumber = req.db.prepare('SELECT * FROM phone_numbers WHERE id = ?').get(result.lastInsertRowid);
    } else {
      const existingReport = req.db.prepare(
        "SELECT id FROM reports WHERE phone_number_id = ? AND device_hash = ? AND created_at > date('now')"
      ).get(phoneNumber.id, deviceHash);

      if (existingReport) {
        return res.status(200).json({
          success: true,
          already_reported: true,
          phone_number: number,
          new_spam_score: phoneNumber.spam_score,
          total_reports: phoneNumber.total_reports,
          message: 'Hai già segnalato questo numero oggi. Grazie per il tuo contributo!'
        });
      }

      const uniqueReporters = req.db.prepare(
        'SELECT COUNT(DISTINCT device_hash) as count FROM reports WHERE phone_number_id = ?'
      ).get(phoneNumber.id);

      req.db.prepare(
        "UPDATE phone_numbers SET total_reports = total_reports + 1, unique_reporters = ?, last_reported_at = datetime('now'), updated_at = datetime('now'), category = COALESCE(?, category) WHERE id = ?"
      ).run((uniqueReporters.count || 0) + 1, category, phoneNumber.id);
    }

    req.db.prepare(
      'INSERT INTO reports (phone_number_id, report_type, category, description, call_duration, device_hash) VALUES (?, ?, ?, ?, ?, ?)'
    ).run(phoneNumber.id, report_type, category || null, description || null, call_duration || 0, deviceHash);

    req.db.prepare(
      'UPDATE devices SET total_reports = total_reports + 1, reports_today = reports_today + 1 WHERE device_hash = ?'
    ).run(deviceHash);

    const newScore = recalculateScore(req.db, phoneNumber.id);

    const updated = req.db.prepare('SELECT * FROM phone_numbers WHERE id = ?').get(phoneNumber.id);

    res.status(201).json({
      success: true,
      already_reported: false,
      phone_number: number,
      new_spam_score: newScore,
      total_reports: updated.total_reports,
      unique_reporters: updated.unique_reporters,
      message: 'Segnalazione registrata. Grazie per il contributo!'
    });

  } catch (err) {
    console.error('Errore segnalazione:', err);
    res.status(500).json({ error: 'Errore interno del server' });
  }
});

module.exports = router;
