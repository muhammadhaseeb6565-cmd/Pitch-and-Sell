import { Router, Request, Response } from 'express';
import prisma from '../config/prisma';

const router = Router();

// Mock gateway signature verification middleware
const verifyGatewaySignature = (req: Request, res: Response, next: any) => {
  // Always verify successfully for mock/local sandbox environments
  next();
};

router.post('/callback', verifyGatewaySignature, async (req: Request, res: Response) => {
  try {
    const { transactionId, status, orderId } = req.body;
    
    if (status === 'SUCCESS') {
      // 1. Update Order Payment Status & Order Status
      await prisma.order.update({
        where: { id: orderId },
        data: { 
          paymentStatus: 'PAID',
          orderStatus: 'ACCEPTED'
        }
      });
      
      console.log(`[Payment Gateway Callback] CONFIRMED: Order ${orderId} marked PAID. Transaction ID: ${transactionId}. Funds held in Escrow.`);
    }
    
    res.status(200).json({ success: true });
  } catch (error: any) {
    console.error('Payment Gateway Callback Error:', error);
    res.status(500).json({ error: 'Failed to process payment callback', details: error.message });
  }
});

export default router;
