const Database = require('better-sqlite3');
const path = require('path');

function initDatabase() {
  const dbPath = path.join(__dirname, '..', 'data', 'callguard.db');
  const db = new Database(dbPath);

  db.pragma('journal_mode = WAL');

  db.exec(`
    CREATE TABLE IF NOT EXISTS phone_numbers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      number TEXT NOT NULL UNIQUE,
      country_code TEXT NOT NULL DEFAULT '+39',
      number_type TEXT DEFAULT 'unknown',
      spam_score INTEGER DEFAULT 0,
      total_reports INTEGER DEFAULT 0,
      unique_reporters INTEGER DEFAULT 0,
      category TEXT,
      operator_name TEXT,
      first_seen_at TEXT DEFAULT (datetime('now')),
      last_reported_at TEXT,
      is_verified_spam INTEGER DEFAULT 0,
      is_whitelisted INTEGER DEFAULT 0,
      created_at TEXT DEFAULT (datetime('now')),
      updated_at TEXT DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS reports (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      phone_number_id INTEGER NOT NULL,
      report_type TEXT NOT NULL,
      category TEXT,
      description TEXT,
      call_duration INTEGER DEFAULT 0,
      device_hash TEXT,
      confidence INTEGER DEFAULT 50,
      created_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (phone_number_id) REFERENCES phone_numbers(id)
    );

    CREATE TABLE IF NOT EXISTS prefix_patterns (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      prefix TEXT NOT NULL UNIQUE,
      risk_level INTEGER DEFAULT 50,
      description TEXT,
      spam_rate REAL DEFAULT 0,
      updated_at TEXT DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS devices (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      device_hash TEXT NOT NULL UNIQUE,
      trust_score INTEGER DEFAULT 50,
      total_reports INTEGER DEFAULT 0,
      accurate_reports INTEGER DEFAULT 0,
      reports_today INTEGER DEFAULT 0,
      last_report_date TEXT,
      created_at TEXT DEFAULT (datetime('now'))
    );

    CREATE INDEX IF NOT EXISTS idx_phone_number ON phone_numbers(number);
    CREATE INDEX IF NOT EXISTS idx_spam_score ON phone_numbers(spam_score);
    CREATE INDEX IF NOT EXISTS idx_reports_phone ON reports(phone_number_id);
    CREATE INDEX IF NOT EXISTS idx_reports_created ON reports(created_at);
    CREATE INDEX IF NOT EXISTS idx_reports_device ON reports(device_hash);
    CREATE INDEX IF NOT EXISTS idx_devices_hash ON devices(device_hash);
    CREATE UNIQUE INDEX IF NOT EXISTS idx_report_unique ON reports(phone_number_id, device_hash, created_at);
  `);

  // Aggiungi colonna unique_reporters se non esiste (migrazione)
  try {
    db.exec('ALTER TABLE phone_numbers ADD COLUMN unique_reporters INTEGER DEFAULT 0');
  } catch (e) {
    // Colonna già esistente, ignora
  }

  const count = db.prepare('SELECT COUNT(*) as n FROM phone_numbers').get();
  if (count.n === 0) {
    console.log('📦 Database vuoto, inserisco dati di esempio...');
    seedDatabase(db);
  }

  return db;
}

function seedDatabase(db) {
  const insertNumber = db.prepare(`
    INSERT OR IGNORE INTO phone_numbers (number, country_code, spam_score, total_reports, unique_reporters, category, operator_name, last_reported_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'))
  `);

  const insertReport = db.prepare(`
    INSERT INTO reports (phone_number_id, report_type, category, description, device_hash)
    VALUES (?, ?, ?, ?, ?)
  `);

  const insertPrefix = db.prepare(`
    INSERT OR IGNORE INTO prefix_patterns (prefix, risk_level, description, spam_rate)
    VALUES (?, ?, ?, ?)
  `);

  const spamNumbers = [
    { number: '+393331234567', score: 95, reports: 342, reporters: 120, category: 'telemarketing_energia', operator: 'Sospetto Eni Plenitude' },
    { number: '+393289876543', score: 88, reports: 156, reporters: 67, category: 'telemarketing_telefonia', operator: 'Operatore sconosciuto' },
    { number: '+393471112233', score: 92, reports: 289, reporters: 95, category: 'truffa', operator: 'Truffa investimenti crypto' },
    { number: '+390211234567', score: 85, reports: 98, reporters: 41, category: 'telemarketing_energia', operator: 'Fornitore gas sconosciuto' },
    { number: '+390612345678', score: 78, reports: 67, reporters: 28, category: 'sondaggio', operator: 'Sondaggi politici' },
    { number: '+393511234567', score: 91, reports: 203, reporters: 82, category: 'truffa', operator: 'Falso supporto tecnico Microsoft' },
    { number: '+393661234567', score: 72, reports: 45, reporters: 18, category: 'telemarketing_telefonia', operator: 'Offerte fibra' },
    { number: '+393771234567', score: 96, reports: 567, reporters: 201, category: 'truffa', operator: 'Truffa pacco in giacenza' },
    { number: '+390287654321', score: 65, reports: 34, reporters: 14, category: 'telemarketing_assicurazioni', operator: 'Assicurazioni auto' },
    { number: '+393801234567', score: 83, reports: 112, reporters: 45, category: 'telemarketing_energia', operator: 'Cambio fornitore luce' },
    { number: '+355691234567', score: 88, reports: 178, reporters: 73, category: 'truffa', operator: 'Call center Albania' },
    { number: '+355681234567', score: 91, reports: 234, reporters: 98, category: 'truffa', operator: 'Truffa trading online' },
    { number: '+38246123456', score: 79, reports: 89, reporters: 35, category: 'telemarketing', operator: 'Call center Kosovo' },
    { number: '+44201234567', score: 71, reports: 56, reporters: 22, category: 'truffa', operator: 'Falso supporto Amazon UK' },
    { number: '+393331111111', score: 87, reports: 145, reporters: 58, category: 'telemarketing_energia', operator: 'Enel impostore' },
    { number: '+393332222222', score: 74, reports: 52, reporters: 21, category: 'sondaggio', operator: 'Sondaggi soddisfazione' },
    { number: '+393333333333', score: 93, reports: 401, reporters: 150, category: 'truffa', operator: 'Phishing bancario' },
    { number: '+393334444444', score: 68, reports: 38, reporters: 15, category: 'telemarketing_telefonia', operator: 'Offerte telefonia mobile' },
    { number: '+393335555555', score: 81, reports: 99, reporters: 40, category: 'telemarketing_energia', operator: 'Gas e luce offerte' },
    { number: '+393336666666', score: 90, reports: 267, reporters: 105, category: 'truffa', operator: 'Vincita premio falsa' },
    { number: '+393337777777', score: 76, reports: 61, reporters: 24, category: 'telemarketing_assicurazioni', operator: 'Polizza vita' },
    { number: '+393338888888', score: 94, reports: 489, reporters: 180, category: 'truffa', operator: 'Truffa INPS falsa' },
    { number: '+393339999999', score: 69, reports: 41, reporters: 16, category: 'sondaggio', operator: 'Ricerche di mercato' },
    { number: '+393340000001', score: 82, reports: 103, reporters: 42, category: 'telemarketing_energia', operator: 'Fotovoltaico porta a porta' },
    { number: '+393340000002', score: 77, reports: 58, reporters: 23, category: 'telemarketing_telefonia', operator: 'Cambio operatore mobile' },
    { number: '+216201234567', score: 85, reports: 134, reporters: 55, category: 'truffa', operator: 'Call center Tunisia' },
    { number: '+212601234567', score: 82, reports: 97, reporters: 39, category: 'truffa', operator: 'Call center Marocco' },
    { number: '+393401234567', score: 73, reports: 48, reporters: 19, category: 'telemarketing_energia', operator: 'Offerta gas mercato libero' },
    { number: '+393411234567', score: 86, reports: 167, reporters: 68, category: 'truffa', operator: 'Falso corriere DHL' },
    { number: '+393421234567', score: 70, reports: 43, reporters: 17, category: 'telemarketing', operator: 'Abbonamenti riviste' },
  ];

  const transaction = db.transaction(() => {
    for (const num of spamNumbers) {
      const result = insertNumber.run(
        num.number,
        num.number.startsWith('+39') ? '+39' : num.number.substring(0, num.number.length > 12 ? 4 : 3),
        num.score,
        num.reports,
        num.reporters,
        num.category,
        num.operator
      );

      const reportCount = Math.min(num.reports, 5);
      const reportTypes = ['spam', 'truffa', 'telemarketing'];
      for (let i = 0; i < reportCount; i++) {
        insertReport.run(
          result.lastInsertRowid,
          reportTypes[i % reportTypes.length],
          num.category,
          'Segnalazione automatica #' + (i + 1),
          'seed_device_' + i
        );
      }
    }

    const prefixes = [
      { prefix: '+355', risk: 80, desc: 'Albania — alto volume spam verso Italia', rate: 72.5 },
      { prefix: '+382', risk: 70, desc: 'Montenegro — call center frequenti', rate: 58.3 },
      { prefix: '+383', risk: 65, desc: 'Kosovo — telemarketing aggressivo', rate: 51.2 },
      { prefix: '+216', risk: 75, desc: 'Tunisia — truffe telefoniche frequenti', rate: 68.1 },
      { prefix: '+212', risk: 70, desc: 'Marocco — call center per mercato IT', rate: 55.7 },
      { prefix: '+44', risk: 30, desc: 'Regno Unito — legittimo ma alcune truffe', rate: 12.4 },
      { prefix: '+39', risk: 10, desc: 'Italia — prefisso nazionale, rischio base basso', rate: 5.2 },
    ];

    for (const p of prefixes) {
      insertPrefix.run(p.prefix, p.risk, p.desc, p.rate);
    }
  });

  transaction();
  console.log('✅ Inseriti ' + spamNumbers.length + ' numeri spam e segnalazioni di esempio');
}

module.exports = { initDatabase };
