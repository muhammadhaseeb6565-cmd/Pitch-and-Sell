import { Request, Response } from 'express';
import prisma from '../config/prisma';
import jwt from 'jsonwebtoken';
import fs from 'fs';
import path from 'path';

const JWT_SECRET = process.env.JWT_SECRET || 'emulgic_pitch_and_sell_secret_key';
const USERS_DB_PATH = path.join(__dirname, '../../users_db.json');

const readLocalUsers = (): any[] => {
  if (!fs.existsSync(USERS_DB_PATH)) {
    fs.writeFileSync(USERS_DB_PATH, JSON.stringify([]));
  }
  try {
    return JSON.parse(fs.readFileSync(USERS_DB_PATH, 'utf-8'));
  } catch (e) {
    return [];
  }
};

const writeLocalUsers = (users: any[]) => {
  fs.writeFileSync(USERS_DB_PATH, JSON.stringify(users, null, 2));
};

export const googleSignIn = async (req: Request, res: Response) => {
  try {
    const { email, name, avatarUrl } = req.body;

    if (!email || !name) {
      return res.status(400).json({ error: 'Email and name are required' });
    }

    // Find or create the user in the database
    let user = await prisma.user.findUnique({
      where: { email },
      include: { businessProfile: true },
    });

    if (!user) {
      user = await prisma.user.create({
        data: {
          email,
          name,
          avatarUrl,
        },
        include: { businessProfile: true },
      });
    } else if (user.name !== name) {
      user = await prisma.user.update({
        where: { email },
        data: { name, avatarUrl },
        include: { businessProfile: true },
      });
    }

    // Sync to local JSON database fallback
    const localUsers = readLocalUsers();
    let localUser = localUsers.find((u: any) => u.email === email);
    if (!localUser) {
      localUser = { id: user.id, email: user.email, name: user.name, avatarUrl: user.avatarUrl, role: user.role, businessProfile: user.businessProfile };
      localUsers.push(localUser);
    } else {
      localUser.name = user.name;
      localUser.avatarUrl = user.avatarUrl;
      localUser.businessProfile = user.businessProfile;
    }
    writeLocalUsers(localUsers);

    // Sign JWT
    const token = jwt.sign(
      { userId: user.id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.json({
      message: 'Sign-in successful',
      token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        avatarUrl: user.avatarUrl,
        role: user.role,
        businessProfile: user.businessProfile,
      },
    });
  } catch (error: any) {
    console.error('Google Sign-In Error:', error);
    res.status(500).json({ error: 'Authentication failed', details: error.message });
  }
};

export const getMe = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.userId;
    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { businessProfile: true },
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({ user });
  } catch (error: any) {
    res.status(500).json({ error: 'Failed to fetch user', details: error.message });
  }
};

export const updateProfile = async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.userId;
    const { name, avatarUrl } = req.body;

    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: {
        name,
        avatarUrl,
      },
      include: { businessProfile: true },
    });

    // Sync to local JSON database fallback
    const localUsers = readLocalUsers();
    const localUser = localUsers.find((u: any) => u.id === userId);
    if (localUser) {
      localUser.name = updatedUser.name;
      localUser.avatarUrl = updatedUser.avatarUrl;
      localUser.businessProfile = updatedUser.businessProfile;
      writeLocalUsers(localUsers);
    }

    res.json({ user: updatedUser });
  } catch (error: any) {
    res.status(500).json({ error: 'Failed to update profile', details: error.message });
  }
};
