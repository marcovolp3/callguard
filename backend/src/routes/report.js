const express = require('express');
const router = express.Router();
const { recalculateScore } = require('../services/scoring');

// POST /api/report — segnala un numero
router.post('/report', (req, res) => {
  const { phone_number, report_type, category, description, call_duration } = req.body;

  // Validazione base
  if (!phone_number || !report_type) {
    return res.status(400).json({ 
      error: 'Campi obbligatori: phone_number, report_type' 
    });
  }

  // Normalizza
  let number = phone_number;
  if (!number.startsWith('+')) {
    number = '+' + number;
  }

  const validTypes = ['spam', 'truffa', 'telemarketing', 'sondaggio', 'legittimo'];
  if (!validTypes.includes(report_type)) {
    return res.status(400).json({ 
      error: `report_type deve essere uno di: ${validTypes.join(', ')}` 
    });
  }

  // Genera un device hash di esempio (in produzione viene dal client)
  const deviceHash = req.headers['x-device-id'] || 'web_' + Date.now();

  try {
    // Cerca o crea il numero
    let phoneNumber = req.db.prepare('SELECT * FROM phone_numbers WHERE number = ?').get(number);

    if (!phoneNumber) {
      // Nuovo numero — inseriscilo
      const countryCode = number.startsWith('+39') ? '+39' : number.substring(0, 4);
      const result = req.db.prepare(`
        INSERT INTO phone_numbers (number, country_code, total_reports, category, last_reported_at)
        VALUES (?, ?, 1, ?, datetime('now'))
      `).run(number, countryCode, category || report_type);

      phoneNumber = req.db.prepare('SELECT * FROM phone_numbers WHERE id = ?').get(result.lastInsertRowid);
    } else {
      // Numero esistente — aggiorna contatore
      req.db.prepare(`
        UPDATE phone_numbers 
        SET total_reports = total_reports + 1, 
            last_reported_at = datetime('now'),
            updated_at = datetime('now'),
            category = COALESCE(?, category)
        WHERE id = ?
      `).run(category, phoneNumber.id);
    }

    // Inserisci la segnalazione
    req.db.prepare(`
      INSERT INTO reports (phone_number_id, report_type, category, description, call_duration, device_hash)
      VALUES (?, ?, ?, ?, ?, ?)
    `).run(
      phoneNumber.id,
      report_type,
      category || null,
      description || null,
      call_duration || 0,
      deviceHash
    );

    // Ricalcola lo spam score
    const newScore = recalculateScore(req.db, phoneNumber.id);

    // Rileggi il numero aggiornato
    const updated = req.db.prepare('SELECT * FROM phone_numbers WHERE id = ?').get(phoneNumber.id);

    res.status(201).json({
      success: true,
      phone_number: number,
      new_spam_score: newScore,
      total_reports: updated.total_reports,
      message: 'Segnalazione registrata. Grazie per il contributo!'
    });

  } catch (err) {
    console.error('Errore segnalazione:', err);
    res.status(500).json({ error: 'Errore interno del server' });
  }
});

module.exports = router;
