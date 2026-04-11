const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const path = require('path');
const { initDatabase } = require('./database');
const lookupRouter = require('./routes/lookup');
const reportRouter = require('./routes/report');
const feedRouter = require('./routes/feed');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Inizializza database
const db = initDatabase();

// Rendi il database accessibile alle route
app.use((req, res, next) => {
  req.db = db;
  next();
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    service: 'CallGuard API',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

// Route API
app.use('/api', lookupRouter);
app.use('/api', reportRouter);
app.use('/api', feedRouter);

// Avvio server
app.listen(PORT, () => {
  console.log(`\n🛡️  CallGuard API avviato su http://localhost:${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/api/health`);
  console.log(`🔍 Prova lookup: http://localhost:${PORT}/api/lookup/+393331234567\n`);
});
