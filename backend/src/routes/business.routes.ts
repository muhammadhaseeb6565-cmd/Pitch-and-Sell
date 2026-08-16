import { Router } from 'express';
import { createBusinessProfile, getBusinessProfile, updateBusinessProfile } from '../controllers/business.controller';
import { authenticateJWT } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticateJWT);

router.post('/', createBusinessProfile);
router.get('/', getBusinessProfile);
router.put('/', updateBusinessProfile);

export default router;
