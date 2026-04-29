const { S3Client, PutObjectCommand, GetObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const { v4: uuidv4 } = require('uuid');
const pool = require('../config/database');

const s3 = new S3Client({
  region: process.env.AWS_REGION || 'eu-central-1',
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  },
});

const BUCKET = process.env.AWS_BUCKET_NAME;

// ─────────────────────────────────────────
// POST /drawings/presign
// iOS uygulaması doğrudan S3'e upload edebilsin diye presigned URL üretir
// ─────────────────────────────────────────
const getPresignedUrl = async (req, res) => {
  try {
    const { contentType = 'image/png' } = req.body;
    const key = `drawings/${req.user.id}/${uuidv4()}.png`;

    const command = new PutObjectCommand({
      Bucket: BUCKET,
      Key: key,
      ContentType: contentType,
    });

    const url = await getSignedUrl(s3, command, { expiresIn: 300 }); // 5 dakika

    return res.json({ uploadUrl: url, s3Key: key });
  } catch (err) {
    console.error('[getPresignedUrl]', err.message);
    return res.status(500).json({ error: 'Presigned URL üretilemedi.' });
  }
};

// ─────────────────────────────────────────
// POST /drawings
// S3 upload tamamlandıktan sonra çizimi DB'ye kaydeder
// ─────────────────────────────────────────
const createDrawing = async (req, res) => {
  try {
    const { s3Key, emotionLabel, bpm, inputMethod = 'manual', isAnonymous = false } = req.body;

    if (!s3Key || !emotionLabel) {
      return res.status(400).json({ error: 's3Key ve emotionLabel zorunludur.' });
    }
    if (!['calm', 'energetic', 'stressed'].includes(emotionLabel)) {
      return res.status(400).json({ error: 'Geçersiz emotionLabel. calm | energetic | stressed olmalı.' });
    }

    // Emotion log kaydet
    const logResult = await pool.query(
      `INSERT INTO emotion_logs (user_id, bpm, emotion_label, input_method)
       VALUES ($1, $2, $3, $4) RETURNING id`,
      [req.user.id, bpm || null, emotionLabel, inputMethod]
    );
    const emotionLogId = logResult.rows[0].id;

    // Public URL oluştur (CDN veya doğrudan S3)
    const imageUrl = `https://${BUCKET}.s3.${process.env.AWS_REGION}.amazonaws.com/${s3Key}`;

    // Drawing kaydet
    const drawResult = await pool.query(
      `INSERT INTO drawings (user_id, emotion_log_id, emotion_label, s3_key, image_url, is_anonymous)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, emotion_label, image_url, is_anonymous, like_count, created_at`,
      [req.user.id, emotionLogId, emotionLabel, s3Key, imageUrl, isAnonymous]
    );

    return res.status(201).json({ drawing: drawResult.rows[0] });
  } catch (err) {
    console.error('[createDrawing]', err.message);
    return res.status(500).json({ error: 'Çizim kaydedilemedi.' });
  }
};

// ─────────────────────────────────────────
// GET /drawings/feed
// Sosyal akış — en yeniden en eskiye, sayfalanmış
// ─────────────────────────────────────────
const getFeed = async (req, res) => {
  try {
    const { emotion, page = 1, limit = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    let query = `
      SELECT
        d.id, d.emotion_label, d.image_url, d.like_count, d.is_anonymous, d.created_at,
        CASE WHEN d.is_anonymous THEN NULL ELSE u.username END AS username,
        CASE WHEN d.is_anonymous THEN NULL ELSE u.avatar_url END AS avatar_url,
        EXISTS (
          SELECT 1 FROM likes l WHERE l.drawing_id = d.id AND l.user_id = $1
        ) AS is_liked_by_me
      FROM drawings d
      JOIN users u ON u.id = d.user_id
    `;
    const params = [req.user.id];
    let paramCount = 2;

    if (emotion && ['calm', 'energetic', 'stressed'].includes(emotion)) {
      query += ` WHERE d.emotion_label = $${paramCount}`;
      params.push(emotion);
      paramCount++;
    }

    query += ` ORDER BY d.created_at DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    params.push(parseInt(limit), offset);

    const result = await pool.query(query, params);
    return res.json({ drawings: result.rows, page: parseInt(page), limit: parseInt(limit) });
  } catch (err) {
    console.error('[getFeed]', err.message);
    return res.status(500).json({ error: 'Feed yüklenemedi.' });
  }
};

// ─────────────────────────────────────────
// GET /drawings/my
// Kullanıcının kendi çizimleri
// ─────────────────────────────────────────
const getMyDrawings = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, emotion_label, image_url, like_count, is_anonymous, created_at
       FROM drawings WHERE user_id = $1 ORDER BY created_at DESC`,
      [req.user.id]
    );
    return res.json({ drawings: result.rows });
  } catch (err) {
    return res.status(500).json({ error: 'Çizimler yüklenemedi.' });
  }
};

// ─────────────────────────────────────────
// POST /drawings/:id/like  |  DELETE /drawings/:id/like
// ─────────────────────────────────────────
const likeDrawing = async (req, res) => {
  try {
    await pool.query(
      'INSERT INTO likes (user_id, drawing_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
      [req.user.id, req.params.id]
    );
    return res.json({ message: 'Beğenildi ❤️' });
  } catch (err) {
    return res.status(500).json({ error: 'Beğeni işlemi başarısız.' });
  }
};

const unlikeDrawing = async (req, res) => {
  try {
    await pool.query(
      'DELETE FROM likes WHERE user_id = $1 AND drawing_id = $2',
      [req.user.id, req.params.id]
    );
    return res.json({ message: 'Beğeni geri alındı.' });
  } catch (err) {
    return res.status(500).json({ error: 'İşlem başarısız.' });
  }
};

module.exports = { getPresignedUrl, createDrawing, getFeed, getMyDrawings, likeDrawing, unlikeDrawing };
