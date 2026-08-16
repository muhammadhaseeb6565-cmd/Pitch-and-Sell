import { Response } from 'express';
import { AuthenticatedRequest } from '../middleware/auth.middleware';
import prisma from '../config/prisma';
import { getConfigValue } from '../config/platform.config';

// Helper to generate custom order IDs like EMU-ORD-000001
const generateOrderDisplayId = async (): Promise<string> => {
  const count = await prisma.order.count();
  const nextNum = count + 1;
  return `EMU-ORD-${nextNum.toString().padStart(6, '0')}`;
};

export const createOrder = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user?.userId;
    const { productId, quantity, paymentMethod } = req.body;

    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    if (!productId || !quantity || !paymentMethod) {
      return res.status(400).json({ error: 'Required fields are missing' });
    }

    const qty = parseInt(quantity, 10);
    if (qty <= 0) {
      return res.status(400).json({ error: 'Quantity must be greater than zero' });
    }

    // Fetch product details
    const product = await prisma.product.findUnique({
      where: { id: productId },
      include: { business: true },
    });

    if (!product) {
      return res.status(404).json({ error: 'Product not found' });
    }

    if (product.status !== 'PUBLISHED') {
      return res.status(400).json({ error: 'Product is not available for orders' });
    }

    // Check stock
    if (product.stock < qty) {
      return res.status(400).json({ error: 'Insufficient stock available' });
    }

    // Fetch fee config from database
    const platformFeeConfig = paymentMethod === 'PAY_NOW' 
      ? await getConfigValue('PAY_NOW_FEE') 
      : await getConfigValue('COD_FEE');

    const unitPrice = product.price;
    const totalAmount = unitPrice.mul(qty);
    
    // Simple mock delivery fee logic
    const deliveryFee = 200; 
    const orderTotal = totalAmount.add(deliveryFee);

    // Compute platform fee and seller earnings
    const emulgicFee = platformFeeConfig;
    const sellerEarnings = orderTotal.sub(emulgicFee);

    const orderId = await generateOrderDisplayId();

    const order = await prisma.$transaction(async (tx) => {
      // Decrement stock
      await tx.product.update({
        where: { id: productId },
        data: { stock: { decrement: qty } },
      });

      // Create Order
      const newOrder = await tx.order.create({
        data: {
          id: orderId,
          customerId: userId,
          productId,
          quantity: qty,
          unitPrice,
          totalAmount: orderTotal,
          deliveryFee,
          paymentMethod,
          paymentStatus: paymentMethod === 'PAY_NOW' ? 'PAID' : 'PENDING',
          orderStatus: 'PENDING',
          emulgicFee,
          sellerEarnings,
        },
      });

      return newOrder;
    });

    res.status(201).json({
      message: 'Order created successfully',
      order,
    });
  } catch (error: any) {
    console.error('Create Order Error:', error);
    res.status(500).json({ error: 'Failed to create order', details: error.message });
  }
};

export const getSellerLedger = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user?.userId;
    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const business = await prisma.businessProfile.findUnique({
      where: { userId },
    });

    if (!business) {
      return res.status(404).json({ error: 'Business profile not found' });
    }

    // Fetch all transaction ledger entries for this business
    const entries = await prisma.ledgerEntry.findMany({
      where: { businessId: business.id },
      orderBy: { createdAt: 'desc' },
    });

    // Dynamically sum balances to ensure absolute audits
    let grossSales = 0;
    let platformFees = 0;
    let paidOut = 0;
    let refunds = 0;

    entries.forEach(entry => {
      const amt = parseFloat(entry.amount.toString());
      if (entry.type === 'SALE_EARNING') {
        grossSales += amt;
      } else if (entry.type === 'PLATFORM_FEE') {
        platformFees += amt; // stored as positive or negative, let's keep negative in db
      } else if (entry.type === 'PAYOUT') {
        paidOut += amt; // negative
      } else if (entry.type === 'REFUND_ADJUSTMENT') {
        refunds += amt;
      }
    });

    // Payout requests that are processing/requested subtract from available balance
    const pendingPayoutsList = await prisma.payout.findMany({
      where: {
        businessId: business.id,
        status: { in: ['REQUESTED', 'APPROVED', 'PROCESSING'] },
      },
    });
    
    const pendingPayoutAmount = pendingPayoutsList.reduce(
      (acc, p) => acc + parseFloat(p.amount.toString()), 0
    );

    const netEarnings = grossSales + platformFees + refunds; // platformFees is negative
    const totalPaidOut = Math.abs(paidOut);
    const availableBalance = netEarnings - totalPaidOut - pendingPayoutAmount;

    res.json({
      summary: {
        grossSales,
        platformFees,
        netEarnings,
        paidOut: totalPaidOut,
        pendingPayouts: pendingPayoutAmount,
        availableForPayout: Math.max(0, availableBalance),
      },
      entries,
    });
  } catch (error: any) {
    res.status(500).json({ error: 'Failed to fetch ledger info', details: error.message });
  }
};

export const requestPayout = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user?.userId;
    const { amount, method, details } = req.body;

    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    if (!amount || !method || !details) {
      return res.status(400).json({ error: 'Required fields are missing' });
    }

    const payoutAmount = parseFloat(amount);
    const minPayout = await getConfigValue('MIN_PAYOUT');

    if (payoutAmount < minPayout) {
      return res.status(400).json({ error: `Minimum payout threshold is PKR ${minPayout}` });
    }

    const business = await prisma.businessProfile.findUnique({
      where: { userId },
    });

    if (!business) {
      return res.status(404).json({ error: 'Business profile not found' });
    }

    // Dynamic Balance Verification
    const entries = await prisma.ledgerEntry.findMany({
      where: { businessId: business.id },
    });

    let balance = 0;
    entries.forEach(entry => {
      balance += parseFloat(entry.amount.toString());
    });

    const pendingPayoutsList = await prisma.payout.findMany({
      where: {
        businessId: business.id,
        status: { in: ['REQUESTED', 'APPROVED', 'PROCESSING'] },
      },
    });
    
    const pendingPayoutAmount = pendingPayoutsList.reduce(
      (acc, p) => acc + parseFloat(p.amount.toString()), 0
    );

    const availableBalance = balance - pendingPayoutAmount;

    if (availableBalance < payoutAmount) {
      return res.status(400).json({ error: 'Insufficient balance available for this payout request' });
    }

    const payout = await prisma.payout.create({
      data: {
        businessId: business.id,
        amount: payoutAmount,
        method,
        details,
        status: 'REQUESTED',
      },
    });

    res.status(201).json({
      message: 'Payout request submitted successfully',
      payout,
    });
  } catch (error: any) {
    res.status(500).json({ error: 'Failed to request payout', details: error.message });
  }
};

export const updateOrderStatus = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { orderId } = req.params;
    const { status } = req.body; // e.g. COMPLETED, CANCELLED, SHIPPED, etc.

    const order = await prisma.order.findUnique({
      where: { id: orderId },
      include: { product: true },
    });

    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }

    // Run order status transition
    const updatedOrder = await prisma.$transaction(async (tx) => {
      const o = await tx.order.update({
        where: { id: orderId },
        data: { orderStatus: status },
      });

      // Financial Integrity: If order transitions to COMPLETED, post to ledger
      if (status === 'COMPLETED' && order.orderStatus !== 'COMPLETED') {
        // 1. Credit full order total to Business Profile ledger
        await tx.ledgerEntry.create({
          data: {
            businessId: order.product.businessId,
            orderId: order.id,
            amount: order.totalAmount,
            type: 'SALE_EARNING',
            description: `Sales revenue for order ${order.id}`,
          },
        });

        // 2. Debit platform fee from Business Profile ledger
        await tx.ledgerEntry.create({
          data: {
            businessId: order.product.businessId,
            orderId: order.id,
            amount: order.emulgicFee.negated(),
            type: 'PLATFORM_FEE',
            description: `Emulgic platform transaction fee for order ${order.id}`,
          },
        });
      }

      // Stock adjustment if cancelled
      if (status === 'CANCELLED' && order.orderStatus !== 'CANCELLED') {
        await tx.product.update({
          where: { id: order.productId },
          data: { stock: { increment: order.quantity } },
        });
      }

      return o;
    });

    res.json({
      message: `Order status updated to ${status}`,
      order: updatedOrder,
    });
  } catch (error: any) {
    console.error('Update Order Status Error:', error);
    res.status(500).json({ error: 'Failed to update order status', details: error.message });
  }
};

export const getOrders = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user?.userId;
    const { mode } = req.query; // 'customer' or 'seller'

    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    if (mode === 'seller') {
      const business = await prisma.businessProfile.findUnique({
        where: { userId },
      });

      if (!business) {
        return res.status(404).json({ error: 'Business profile not found' });
      }

      const orders = await prisma.order.findMany({
        where: {
          product: { businessId: business.id },
        },
        include: {
          customer: { select: { id: true, name: true, email: true } },
          product: true,
        },
        orderBy: { createdAt: 'desc' },
      });

      return res.json({ orders });
    } else {
      // Default to customer orders
      const orders = await prisma.order.findMany({
        where: { customerId: userId },
        include: {
          product: {
            include: { business: true },
          },
        },
        orderBy: { createdAt: 'desc' },
      });

      return res.json({ orders });
    }
  } catch (error: any) {
    res.status(500).json({ error: 'Failed to fetch orders', details: error.message });
  }
};

// Structured Offers in Chat
export const createOffer = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user?.userId;
    const { chatId, productId, quantity, unitPrice, deliveryFee, paymentMethod } = req.body;

    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    // Verify chat exists and user is part of it
    const chat = await prisma.chat.findUnique({
      where: { id: chatId },
      include: { users: true },
    });

    if (!chat || !chat.users.some(u => u.id === userId)) {
      return res.status(403).json({ error: 'Access to chat denied' });
    }

    const qty = parseInt(quantity, 10);
    const priceVal = parseFloat(unitPrice);
    const deliveryVal = parseFloat(deliveryFee || '200');
    const totalAmount = (priceVal * qty) + deliveryVal;

    const offer = await prisma.offer.create({
      data: {
        chatId,
        productId,
        quantity: qty,
        unitPrice: priceVal,
        deliveryFee: deliveryVal,
        totalAmount,
        paymentMethod,
        expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000), // expires in 24 hours
        status: 'PENDING',
      },
    });

    res.status(201).json({
      message: 'Wholesale offer sent successfully',
      offer,
    });
  } catch (error: any) {
    res.status(500).json({ error: 'Failed to create offer', details: error.message });
  }
};

export const acceptOffer = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user?.userId;
    const { offerId } = req.params;

    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const offer = await prisma.offer.findUnique({
      where: { id: offerId },
      include: { product: { include: { business: true } } },
    });

    if (!offer) {
      return res.status(404).json({ error: 'Offer not found' });
    }

    if (offer.status !== 'PENDING') {
      return res.status(400).json({ error: `Offer is already ${offer.status}` });
    }

    if (new Date() > offer.expiresAt) {
      await prisma.offer.update({
        where: { id: offerId },
        data: { status: 'EXPIRED' },
      });
      return res.status(400).json({ error: 'Offer has expired' });
    }

    // Verify stock
    if (offer.product.stock < offer.quantity) {
      return res.status(400).json({ error: 'Insufficient product stock to accept this offer' });
    }

    // Fetch platform fee config
    const platformFeeConfig = offer.paymentMethod === 'PAY_NOW'
      ? await getConfigValue('PAY_NOW_FEE')
      : await getConfigValue('COD_FEE');

    const emulgicFee = platformFeeConfig;
    const sellerEarnings = offer.totalAmount.sub(emulgicFee);
    const orderId = await generateOrderDisplayId();

    const result = await prisma.$transaction(async (tx) => {
      // Update offer status
      const updatedOffer = await tx.offer.update({
        where: { id: offerId },
        data: { status: 'ACCEPTED' },
      });

      // Decrement stock
      await tx.product.update({
        where: { id: offer.productId },
        data: { stock: { decrement: offer.quantity } },
      });

      // Create Order from accepted offer
      const newOrder = await tx.order.create({
        data: {
          id: orderId,
          customerId: userId,
          productId: offer.productId,
          quantity: offer.quantity,
          unitPrice: offer.unitPrice,
          totalAmount: offer.totalAmount,
          deliveryFee: offer.deliveryFee,
          paymentMethod: offer.paymentMethod,
          paymentStatus: offer.paymentMethod === 'PAY_NOW' ? 'PAID' : 'PENDING',
          orderStatus: 'ACCEPTED', // accepted directly
          emulgicFee,
          sellerEarnings,
        },
      });

      return { offer: updatedOffer, order: newOrder };
    });

    res.json({
      message: 'Offer accepted and order created successfully',
      ...result,
    });
  } catch (error: any) {
    console.error('Accept Offer Error:', error);
    res.status(500).json({ error: 'Failed to accept offer', details: error.message });
  }
};

export const cancelOrder = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user?.userId;
    const { orderId } = req.params;

    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const order = await prisma.order.findUnique({
      where: { id: orderId },
      include: { product: true },
    });

    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }

    const isCustomer = order.customerId === userId;
    const business = await prisma.businessProfile.findFirst({
      where: { userId, id: order.product.businessId },
    });
    
    if (!isCustomer && !business) {
      return res.status(403).json({ error: 'You are not authorized to cancel this order' });
    }

    if (order.orderStatus === 'CANCELLED' || order.orderStatus === 'DELIVERED' || order.orderStatus === 'COMPLETED') {
      return res.status(400).json({ error: `Order is already ${order.orderStatus}` });
    }

    const updated = await prisma.$transaction(async (tx) => {
      const updatedOrder = await tx.order.update({
        where: { id: orderId },
        data: { orderStatus: 'CANCELLED' },
      });

      await tx.product.update({
        where: { id: order.productId },
        data: { stock: { increment: order.quantity } },
      });

      return updatedOrder;
    });

    res.json({
      message: 'Order cancelled successfully',
      order: updated,
    });
  } catch (error: any) {
    console.error('Cancel Order Error:', error);
    res.status(500).json({ error: 'Failed to cancel order', details: error.message });
  }
};
