import { Response } from 'express';
import { AuthenticatedRequest } from '../middleware/auth.middleware';
import prisma from '../config/prisma';
import { getVideoDuration } from '../utils/video.utils';
import fs from 'fs';

export const createProductWithVideo = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user?.userId;
    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    // Check if user has a verified business profile
    const business = await prisma.businessProfile.findUnique({
      where: { userId },
    });

    if (!business) {
      return res.status(400).json({ error: 'Please create a business profile before uploading products.' });
    }

    if (business.status === 'SUSPENDED') {
      return res.status(403).json({ error: 'Your business profile is suspended.' });
    }

    const {
      name,
      description,
      price,
      oldPrice,
      discount,
      category,
      stock,
      allowDownload,
      status,
      videoUrl,
    } = req.body;

    // Handle files or direct videoUrl
    const files = req.files as { [fieldname: string]: Express.Multer.File[] };
    const videoFile = files?.['video']?.[0];
    
    let finalVideoUrl = '';
    let duration = 15.0;

    if (videoUrl) {
      finalVideoUrl = videoUrl;
    } else if (videoFile) {
      finalVideoUrl = videoFile.path.replace(/\\/g, '/');
      duration = await getVideoDuration(videoFile.path);
      if (duration > 60.5) {
        if (fs.existsSync(videoFile.path)) {
          fs.unlinkSync(videoFile.path);
        }
        return res.status(400).json({ error: `Video exceeds the 60-second limit (duration: ${duration.toFixed(1)}s)` });
      }
    } else {
      return res.status(400).json({ error: 'A product video file or videoUrl is required.' });
    }

    if (!name || !price || !category) {
      if (videoFile && fs.existsSync(videoFile.path)) {
        fs.unlinkSync(videoFile.path);
      }
      return res.status(400).json({ error: 'Required fields (name, price, category) are missing.' });
    }

    const priceDecimal = parseFloat(price);
    const oldPriceDecimal = oldPrice ? parseFloat(oldPrice) : null;
    const discountDecimal = discount ? parseFloat(discount) : null;
    const stockInt = stock ? parseInt(stock, 10) : 0;
    const isDownloadAllowed = allowDownload === 'true' || allowDownload === true;

    // Run within a transaction to guarantee atomicity
    const result = await prisma.$transaction(async (tx) => {
      const product = await tx.product.create({
        data: {
          businessId: business.id,
          name,
          description: description || '',
          price: priceDecimal,
          oldPrice: oldPriceDecimal,
          discount: discountDecimal,
          category,
          stock: stockInt,
          status: status || 'PUBLISHED',
        },
      });

      const video = await tx.video.create({
        data: {
          productId: product.id,
          url: finalVideoUrl,
          duration,
          allowDownload: isDownloadAllowed,
        },
      });

      return { product, video };
    });

    res.status(201).json({
      message: 'Product and video uploaded successfully.',
      ...result,
    });
  } catch (error: any) {
    console.error('Upload product error:', error);
    res.status(500).json({ error: 'Failed to upload product', details: error.message });
  }
};

export const getFeed = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { category, search } = req.query;
    const userId = req.user?.userId;

    // Filter clauses
    const whereClause: any = {
      status: 'PUBLISHED',
    };

    if (category) {
      whereClause.category = category as string;
    }

    if (search) {
      whereClause.OR = [
        { name: { contains: search as string, mode: 'insensitive' } },
        { description: { contains: search as string, mode: 'insensitive' } },
      ];
    }

    const products = await prisma.product.findMany({
      where: whereClause,
      include: {
        business: true,
        video: {
          include: {
            likes: userId ? { where: { userId } } : false,
          },
        },
      },
      orderBy: [
        { createdAt: 'desc' },
      ],
    });

    res.json({ products });
  } catch (error: any) {
    res.status(500).json({ error: 'Failed to fetch video feed', details: error.message });
  }
};

export const toggleLikeVideo = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user?.userId;
    const { videoId } = req.params;

    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const existingLike = await prisma.like.findUnique({
      where: {
        userId_videoId: { userId, videoId },
      },
    });

    if (existingLike) {
      await prisma.$transaction([
        prisma.like.delete({
          where: { id: existingLike.id },
        }),
        prisma.video.update({
          where: { id: videoId },
          data: { likesCount: { decrement: 1 } },
        }),
      ]);
      return res.json({ liked: false });
    } else {
      await prisma.$transaction([
        prisma.like.create({
          data: { userId, videoId },
        }),
        prisma.video.update({
          where: { id: videoId },
          data: { likesCount: { increment: 1 } },
        }),
      ]);
      return res.json({ liked: true });
    }
  } catch (error: any) {
    res.status(500).json({ error: 'Failed to like/unlike video', details: error.message });
  }
};

export const addComment = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user?.userId;
    const { videoId } = req.params;
    const { content } = req.body;

    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    if (!content) {
      return res.status(400).json({ error: 'Comment content is required' });
    }

    const comment = await prisma.comment.create({
      data: {
        userId,
        videoId,
        content,
      },
      include: {
        user: { select: { name: true, avatarUrl: true } },
      },
    });

    res.status(201).json({ comment });
  } catch (error: any) {
    res.status(500).json({ error: 'Failed to add comment', details: error.message });
  }
};

export const getComments = async (req: Request, res: Response) => {
  try {
    const { videoId } = req.params;

    const comments = await prisma.comment.findMany({
      where: { videoId },
      include: {
        user: { select: { id: true, name: true, avatarUrl: true } },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    res.json({ comments });
  } catch (error: any) {
    res.status(500).json({ error: 'Failed to fetch comments', details: error.message });
  }
};

export const promoteProduct = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user?.userId;
    const { productId } = req.params;

    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const product = await prisma.product.findUnique({
      where: { id: productId },
      include: { business: true },
    });

    if (!product) {
      return res.status(404).json({ error: 'Product not found' });
    }

    if (product.business.userId !== userId) {
      return res.status(403).json({ error: 'You do not own this business product' });
    }

    if (product.isFeatured) {
      return res.status(400).json({ error: 'Product is already promoted' });
    }

    const { plan } = req.body;
    let feeAmount = 100.0;
    let planLabel = 'Featured Promotion';

    if (plan === 'STANDARD') {
      feeAmount = 500.0;
      planLabel = 'Boost Standard (2x for 24h)';
    } else if (plan === 'PREMIUM') {
      feeAmount = 1500.0;
      planLabel = 'Boost Premium (5x for 72h)';
    } else if (plan === 'ELITE') {
      feeAmount = 5000.0;
      planLabel = 'Boost Elite (10x for 7 days)';
    }

    const result = await prisma.$transaction(async (tx) => {
      const entry = await tx.ledgerEntry.create({
        data: {
          businessId: product.businessId,
          amount: feeAmount,
          type: 'PLATFORM_FEE',
          description: `${planLabel}: ${product.name}`,
        },
      });

      const updatedProduct = await tx.product.update({
        where: { id: productId },
        data: { isFeatured: true },
      });

      return { entry, product: updatedProduct };
    });

    res.json({
      message: `Product promoted successfully! PKR ${feeAmount} deducted from your balance.`,
      ...result,
    });
  } catch (error: any) {
    console.error('Promote Product Error:', error);
    res.status(500).json({ error: 'Failed to promote product', details: error.message });
  }
};
