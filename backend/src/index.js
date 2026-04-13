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

app.use(helmet());
app.use(cors());
app.use(express.json());

const db = initDatabase();

app.use((req, res, next) => {
  req.db = db;
  next();
});

app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'BrunoBlock API',
    version: '2.0.0',
    timestamp: new Date().toISOString()
  });
});

app.use('/api', lookupRouter);
app.use('/api', reportRouter);
app.use('/api', feedRouter);

app.listen(PORT, () => {
  console.log('\n🛡️  BrunoBlock API avviato su http://localhost:' + PORT);
  console.log('📊 Health check: http://localhost:' + PORT + '/api/health');
  console.log('🔍 Prova lookup: http://localhost:' + PORT + '/api/lookup/+393331234567\n');
});
