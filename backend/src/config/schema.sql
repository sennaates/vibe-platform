-- =============================================
-- VIBE — Veritabanı Şeması
-- Supabase SQL Editor'a bu dosyayı yapıştır ve çalıştır
-- =============================================

-- Uzantılar
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- USERS tablosu
-- =============================================
CREATE TABLE IF NOT EXISTS users (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  username    VARCHAR(30)  UNIQUE NOT NULL,
  email       VARCHAR(255) UNIQUE NOT NULL,
  password    TEXT         NOT NULL,             -- bcrypt hash
  avatar_url  TEXT,
  bio         TEXT,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- =============================================
-- EMOTION_LOGS tablosu (her çizim öncesi duygu kaydı)
-- =============================================
CREATE TABLE IF NOT EXISTS emotion_logs (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  bpm           INTEGER,                          -- nabız değeri (opsiyonel)
  emotion_label VARCHAR(20) NOT NULL              -- 'calm' | 'energetic' | 'stressed'
                CHECK (emotion_label IN ('calm', 'energetic', 'stressed')),
  input_method  VARCHAR(10) NOT NULL DEFAULT 'manual'
                CHECK (input_method IN ('healthkit', 'manual')),
  recorded_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================
-- DRAWINGS tablosu
-- =============================================
CREATE TABLE IF NOT EXISTS drawings (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  emotion_log_id  UUID REFERENCES emotion_logs(id) ON DELETE SET NULL,
  emotion_label   VARCHAR(20) NOT NULL
                  CHECK (emotion_label IN ('calm', 'energetic', 'stressed')),
  s3_key          TEXT NOT NULL,                  -- AWS S3 nesne anahtarı
  image_url       TEXT NOT NULL,                  -- Public veya pre-signed URL
  is_anonymous    BOOLEAN NOT NULL DEFAULT FALSE,
  like_count      INTEGER NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================
-- LIKES tablosu
-- =============================================
CREATE TABLE IF NOT EXISTS likes (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  drawing_id  UUID NOT NULL REFERENCES drawings(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, drawing_id)                    -- bir kullanıcı aynı çizimi bir kez beğenebilir
);

-- =============================================
-- REFRESH_TOKENS tablosu
-- =============================================
CREATE TABLE IF NOT EXISTS refresh_tokens (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token       TEXT NOT NULL UNIQUE,
  expires_at  TIMESTAMPTZ NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================
-- İndeksler (Performans)
-- =============================================
CREATE INDEX IF NOT EXISTS idx_drawings_user_id       ON drawings(user_id);
CREATE INDEX IF NOT EXISTS idx_drawings_emotion_label ON drawings(emotion_label);
CREATE INDEX IF NOT EXISTS idx_drawings_created_at    ON drawings(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_likes_drawing_id       ON likes(drawing_id);
CREATE INDEX IF NOT EXISTS idx_emotion_logs_user_id   ON emotion_logs(user_id);

-- =============================================
-- like_count otomatik güncelleme trigger'ı
-- =============================================
CREATE OR REPLACE FUNCTION update_like_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE drawings SET like_count = like_count + 1 WHERE id = NEW.drawing_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE drawings SET like_count = like_count - 1 WHERE id = OLD.drawing_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_like_count ON likes;
CREATE TRIGGER trigger_like_count
  AFTER INSERT OR DELETE ON likes
  FOR EACH ROW EXECUTE FUNCTION update_like_count();

-- =============================================
-- updated_at otomatik güncelleme trigger'ı
-- =============================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_users_updated_at ON users;
CREATE TRIGGER trigger_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
