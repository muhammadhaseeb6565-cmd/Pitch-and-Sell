import { Router } from 'express';
import { getAdminDashboard, updatePayoutStatus, updateConfig } from '../controllers/admin.controller';
import { authenticateJWT, requireAdmin } from '../middleware/auth.middleware';
import { adminUpdateBusinessStatus } from '../controllers/business.controller';

const router = Router();

// Secure admin routes
router.use(authenticateJWT);
router.use(requireAdmin);

router.get('/dashboard', getAdminDashboard);
router.patch('/payout/:payoutId/status', updatePayoutStatus);
router.patch('/business/:businessId/status', adminUpdateBusinessStatus);
router.post('/config', updateConfig);

export default router;
