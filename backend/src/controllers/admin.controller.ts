import { Response } from 'express';
import { AuthenticatedRequest } from '../middleware/auth.middleware';
import prisma from '../config/prisma';
import { setConfigValue } from '../config/platform.config';

export const getAdminDashboard = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const totalUsers = await prisma.user.count();
    const totalBusinesses = await prisma.businessProfile.count();
    const totalOrders = await prisma.order.count();

    const orders = await prisma.order.findMany();
    const totalGmv = orders.reduce((sum, o) => sum + parseFloat(o.totalAmount.toString()), 0);
    const totalFees = orders.reduce((sum, o) => sum + parseFloat(o.emulgicFee.toString()), 0);

    const pendingPayouts = await prisma.payout.findMany({
      where: { status: 'REQUESTED' },
      include: { business: true },
    });

    const pendingBusinesses = await prisma.businessProfile.findMany({
      where: { status: 'PENDING' },
    });

    res.json({
      metrics: {
        totalUsers,
        totalBusinesses,
        totalOrders,
        totalGmv,
        totalFees,
      },
      pendingPayouts,
      pendingBusinesses,
    });
  } catch (error: any) {
    res.status(500).json({ error: 'Failed to retrieve admin dashboard metrics', details: error.message });
  }
};

export const updatePayoutStatus = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { payoutId } = req.params;
    const { status } = req.body; // APPROVED, COMPLETED, REJECTED, FAILED

    if (!['APPROVED', 'COMPLETED', 'REJECTED', 'FAILED'].includes(status)) {
      return res.status(400).json({ error: 'Invalid payout status value' });
    }

    const payout = await prisma.payout.findUnique({
      where: { id: payoutId },
    });

    if (!payout) {
      return res.status(404).json({ error: 'Payout request not found' });
    }

    const updatedPayout = await prisma.$transaction(async (tx) => {
      const updated = await tx.payout.update({
        where: { id: payoutId },
        data: { status },
      });

      // Once completed, deduct it permanently from the dynamic ledger balance
      if (status === 'COMPLETED' && payout.status !== 'COMPLETED') {
        await tx.ledgerEntry.create({
          data: {
            businessId: payout.businessId,
            amount: payout.amount.negated(), // negative amount representing payout debit
            type: 'PAYOUT',
            description: `Completed payout request ID: ${payout.id} via ${payout.method}`,
          },
        });
      }

      return updated;
    });

    res.json({
      message: `Payout status updated to ${status} successfully.`,
      payout: updatedPayout,
    });
  } catch (error: any) {
    console.error('Update Payout Status Error:', error);
    res.status(500).json({ error: 'Failed to update payout status', details: error.message });
  }
};

export const updateConfig = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { key, value } = req.body;

    if (!key || value === undefined) {
      return res.status(400).json({ error: 'Key and value are required' });
    }

    await setConfigValue(key, value.toString());

    res.json({
      message: `System configuration parameter [${key}] updated to [${value}]`,
    });
  } catch (error: any) {
    res.status(500).json({ error: 'Failed to update system config', details: error.message });
  }
};
