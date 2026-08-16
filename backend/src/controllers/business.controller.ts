import { Response } from 'express';
import { AuthenticatedRequest } from '../middleware/auth.middleware';
import prisma from '../config/prisma';

export const createBusinessProfile = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user?.userId;
    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    // Check if business profile already exists
    const existingProfile = await prisma.businessProfile.findUnique({
      where: { userId },
    });

    if (existingProfile) {
      return res.status(400).json({ error: 'Business profile already exists for this user' });
    }

    const {
      name,
      category,
      description,
      phone,
      email,
      logoUrl,
      city,
      address,
    } = req.body;

    if (!name || !category || !phone || !email || !city || !address) {
      return res.status(400).json({ error: 'Required fields are missing' });
    }

    const business = await prisma.businessProfile.create({
      data: {
        userId,
        name,
        category,
        description: description || '',
        phone,
        email,
        logoUrl,
        city,
        address,
        status: 'PENDING', // default initial status
      },
    });

    res.status(201).json({
      message: 'Business profile created successfully. Awaiting verification.',
      business,
    });
  } catch (error: any) {
    console.error('Create Business Profile Error:', error);
    res.status(500).json({ error: 'Failed to create business profile', details: error.message });
  }
};

export const getBusinessProfile = async (req: AuthenticatedRequest, res: Response) => {
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

    res.json({ business });
  } catch (error: any) {
    res.status(500).json({ error: 'Failed to fetch business profile', details: error.message });
  }
};

export const updateBusinessProfile = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user?.userId;
    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const {
      name,
      category,
      description,
      phone,
      email,
      logoUrl,
      city,
      address,
    } = req.body;

    const business = await prisma.businessProfile.update({
      where: { userId },
      data: {
        name,
        category,
        description,
        phone,
        email,
        logoUrl,
        city,
        address,
      },
    });

    res.json({
      message: 'Business profile updated successfully',
      business,
    });
  } catch (error: any) {
    res.status(500).json({ error: 'Failed to update business profile', details: error.message });
  }
};

// Admin status updates
export const adminUpdateBusinessStatus = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { businessId } = req.params;
    const { status } = req.body; // PENDING, VERIFIED, REJECTED, SUSPENDED

    if (!['PENDING', 'VERIFIED', 'REJECTED', 'SUSPENDED'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status value' });
    }

    const business = await prisma.businessProfile.update({
      where: { id: businessId },
      data: { status },
    });

    res.json({
      message: `Business status updated to ${status} successfully`,
      business,
    });
  } catch (error: any) {
    res.status(500).json({ error: 'Failed to update status', details: error.message });
  }
};
