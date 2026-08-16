import { Router } from 'express';
import { createProductWithVideo, getFeed, toggleLikeVideo, addComment, getComments, promoteProduct } from '../controllers/product.controller';
import { authenticateJWT } from '../middleware/auth.middleware';
import { upload } from '../config/multer';

const router = Router();

// Feed is public
router.get('/feed', authenticateJWT, getFeed);
router.get('/video/:videoId/comments', getComments);

// Actions requiring authentication
router.post(
  '/',
  authenticateJWT,
  upload.fields([{ name: 'video', maxCount: 1 }]),
  createProductWithVideo
);
router.post('/video/:videoId/like', authenticateJWT, toggleLikeVideo);
router.post('/video/:videoId/comments', authenticateJWT, addComment);
router.post('/:productId/promote', authenticateJWT, promoteProduct);

export default router;
