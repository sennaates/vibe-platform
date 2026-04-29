const bcrypt = require('bcryptjs');
const pool = require('../config/database');
const { generateAccessToken, generateRefreshToken, verifyRefreshToken } = require('../utils/jwt');

const SALT_ROUNDS = 12;

// ─────────────────────────────────────────
// POST /auth/register
// ─────────────────────────────────────────
const register = async (req, res) => {
  try {
    const { username, email, password } = req.body;

    // Validasyon
    if (!username || !email || !password) {
      return res.status(400).json({ error: 'username, email ve password zorunludur.' });
    }
    if (password.length < 6) {
      return res.status(400).json({ error: 'Şifre en az 6 karakter olmalıdır.' });
    }
    if (username.length < 3 || username.length > 30) {
      return res.status(400).json({ error: 'Kullanıcı adı 3-30 karakter arasında olmalıdır.' });
    }

    // Email/username benzersizlik kontrolü
    const existing = await pool.query(
      'SELECT id FROM users WHERE email = $1 OR username = $2',
      [email.toLowerCase(), username.toLowerCase()]
    );
    if (existing.rows.length > 0) {
      return res.status(409).json({ error: 'Bu e-posta veya kullanıcı adı zaten kullanımda.' });
    }

    // Şifre hashleme
    const hashedPassword = await bcrypt.hash(password, SALT_ROUNDS);

    // Kullanıcı oluştur
    const result = await pool.query(
      `INSERT INTO users (username, email, password)
       VALUES ($1, $2, $3)
       RETURNING id, username, email, created_at`,
      [username.toLowerCase(), email.toLowerCase(), hashedPassword]
    );
    const user = result.rows[0];

    // Token üret
    const tokenPayload = { id: user.id, email: user.email, username: user.username };
    const accessToken = generateAccessToken(tokenPayload);
    const refreshToken = generateRefreshToken(tokenPayload);

    // Refresh token'ı DB'ye kaydet
    await pool.query(
      `INSERT INTO refresh_tokens (user_id, token, expires_at)
       VALUES ($1, $2, NOW() + INTERVAL '7 days')`,
      [user.id, refreshToken]
    );

    return res.status(201).json({
      message: 'Kayıt başarılı! 🎉',
      user: { id: user.id, username: user.username, email: user.email },
      accessToken,
      refreshToken,
    });
  } catch (err) {
    console.error('[register]', err.message);
    return res.status(500).json({ error: 'Sunucu hatası.' });
  }
};

// ─────────────────────────────────────────
// POST /auth/login
// ─────────────────────────────────────────
const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'email ve password zorunludur.' });
    }

    // Kullanıcıyı bul
    const result = await pool.query(
      'SELECT id, username, email, password FROM users WHERE email = $1',
      [email.toLowerCase()]
    );
    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'E-posta veya şifre hatalı.' });
    }

    const user = result.rows[0];

    // Şifre kontrol
    const isValid = await bcrypt.compare(password, user.password);
    if (!isValid) {
      return res.status(401).json({ error: 'E-posta veya şifre hatalı.' });
    }

    // Token üret
    const tokenPayload = { id: user.id, email: user.email, username: user.username };
    const accessToken = generateAccessToken(tokenPayload);
    const refreshToken = generateRefreshToken(tokenPayload);

    // Eski refresh token'ları temizle, yenisini kaydet
    await pool.query('DELETE FROM refresh_tokens WHERE user_id = $1', [user.id]);
    await pool.query(
      `INSERT INTO refresh_tokens (user_id, token, expires_at)
       VALUES ($1, $2, NOW() + INTERVAL '7 days')`,
      [user.id, refreshToken]
    );

    return res.json({
      message: 'Giriş başarılı! 🎨',
      user: { id: user.id, username: user.username, email: user.email },
      accessToken,
      refreshToken,
    });
  } catch (err) {
    console.error('[login]', err.message);
    return res.status(500).json({ error: 'Sunucu hatası.' });
  }
};

// ─────────────────────────────────────────
// POST /auth/refresh
// ─────────────────────────────────────────
const refresh = async (req, res) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(400).json({ error: 'refreshToken zorunludur.' });
    }

    // Token'ı doğrula
    const decoded = verifyRefreshToken(refreshToken);

    // DB'de var mı?
    const result = await pool.query(
      'SELECT * FROM refresh_tokens WHERE token = $1 AND expires_at > NOW()',
      [refreshToken]
    );
    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Geçersiz veya süresi dolmuş refresh token.' });
    }

    // Yeni access token üret
    const tokenPayload = { id: decoded.id, email: decoded.email, username: decoded.username };
    const newAccessToken = generateAccessToken(tokenPayload);

    return res.json({ accessToken: newAccessToken });
  } catch (err) {
    return res.status(401).json({ error: 'Geçersiz refresh token.' });
  }
};

// ─────────────────────────────────────────
// POST /auth/logout
// ─────────────────────────────────────────
const logout = async (req, res) => {
  try {
    const { refreshToken } = req.body;
    if (refreshToken) {
      await pool.query('DELETE FROM refresh_tokens WHERE token = $1', [refreshToken]);
    }
    return res.json({ message: 'Çıkış yapıldı.' });
  } catch (err) {
    return res.status(500).json({ error: 'Sunucu hatası.' });
  }
};

// ─────────────────────────────────────────
// GET /auth/me
// ─────────────────────────────────────────
const me = async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, username, email, avatar_url, bio, created_at FROM users WHERE id = $1',
      [req.user.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Kullanıcı bulunamadı.' });
    }
    return res.json({ user: result.rows[0] });
  } catch (err) {
    return res.status(500).json({ error: 'Sunucu hatası.' });
  }
};

module.exports = { register, login, refresh, logout, me };
