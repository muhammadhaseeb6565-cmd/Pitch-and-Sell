import { Router } from 'express';
import { googleSignIn, getMe, updateProfile } from '../controllers/auth.controller';
import { authenticateJWT } from '../middleware/auth.middleware';

const router = Router();

router.post('/google', googleSignIn);
router.get('/me', authenticateJWT, getMe);
router.put('/profile', authenticateJWT, updateProfile);

export default router;
