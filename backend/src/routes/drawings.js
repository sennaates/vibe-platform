const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const {
  getPresignedUrl,
  createDrawing,
  getFeed,
  getMyDrawings,
  likeDrawing,
  unlikeDrawing,
} = require('../controllers/drawingController');

// Tüm drawing route'ları authenticate gerektirir
router.use(authenticate);

router.post('/presign', getPresignedUrl);       // S3 presigned URL al
router.post('/', createDrawing);                // Çizimi kaydet
router.get('/feed', getFeed);                   // Sosyal akış
router.get('/my', getMyDrawings);               // Kendi çizimleri

router.post('/:id/like', likeDrawing);          // Beğen
router.delete('/:id/like', unlikeDrawing);      // Beğeniyi geri al

module.exports = router;
