import { Router } from 'express';
import { googleSignIn, getMe, updateProfile, signUp, signIn } from '../controllers/auth.controller';
import { authenticateJWT } from '../middleware/auth.middleware';

const router = Router();

router.post('/signup', signUp);
router.post('/signin', signIn);
router.post('/google', googleSignIn);
router.get('/me', authenticateJWT, getMe);
router.put('/profile', authenticateJWT, updateProfile);

export default router;
