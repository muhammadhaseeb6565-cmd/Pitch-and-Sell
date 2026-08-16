import { Router } from 'express';
import { generatePitchScript } from '../controllers/ai.controller';
import { authenticateJWT } from '../middleware/auth.middleware';

const router = Router();

// Route: POST /api/ai/generate-pitch
router.post('/generate-pitch', authenticateJWT, generatePitchScript);

export default router;
