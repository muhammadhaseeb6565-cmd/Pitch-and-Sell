import { Router } from 'express';
import { 
  createOrder, 
  getSellerLedger, 
  requestPayout, 
  updateOrderStatus, 
  getOrders, 
  createOffer, 
  acceptOffer,
  cancelOrder
} from '../controllers/order.controller';
import { authenticateJWT } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticateJWT);

router.post('/', createOrder);
router.get('/', getOrders);
router.patch('/:orderId/status', updateOrderStatus);
router.post('/:orderId/cancel', cancelOrder);

// Ledger & Payouts
router.get('/ledger', getSellerLedger);
router.post('/payout', requestPayout);

// Structured Offer System
router.post('/offer', createOffer);
router.post('/offer/:offerId/accept', acceptOffer);

export default router;
