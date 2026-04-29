require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

const authRoutes = require('./src/routes/auth');
const drawingRoutes = require('./src/routes/drawings');

const app = express();
const PORT = process.env.PORT || 3000;

// ─── Güvenlik Middleware'leri ───
app.use(helmet());
app.use(cors({
  origin: ['http://localhost:3001', 'http://localhost:5173'], // web dev sunucuları
  credentials: true,
}));

// Rate limiting — auth endpoint'leri için daha sıkı
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 dakika
  max: 20,
  message: { error: 'Çok fazla istek gönderildi. Lütfen 15 dakika sonra tekrar deneyin.' },
});

const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 200,
  message: { error: 'Çok fazla istek.' },
});

app.use(generalLimiter);
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// ─── Routes ───
app.use('/auth', authLimiter, authRoutes);
app.use('/drawings', drawingRoutes);

// ─── Health Check ───
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'Vibe API',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
  });
});

// ─── 404 ───
app.use((req, res) => {
  res.status(404).json({ error: `Endpoint bulunamadı: ${req.method} ${req.path}` });
});

// ─── Global Error Handler ───
app.use((err, req, res, next) => {
  console.error('[GlobalError]', err.stack);
  res.status(500).json({ error: 'Beklenmedik bir hata oluştu.' });
});

// ─── Server Başlat ───
app.listen(PORT, () => {
  console.log(`🚀 Vibe API çalışıyor → http://localhost:${PORT}`);
  console.log(`📊 Health check      → http://localhost:${PORT}/health`);
});

module.exports = app;
