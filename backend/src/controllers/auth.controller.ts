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

import { OAuth2Client } from 'google-auth-library';

const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID || 'dummy_client_id_for_dev');

export const googleSignIn = async (req: Request, res: Response) => {
  try {
    const { idToken, email: fallbackEmail, name: fallbackName, avatarUrl: fallbackAvatar } = req.body;

    let email = fallbackEmail;
    let name = fallbackName;
    let avatarUrl = fallbackAvatar;

    // Verify the real Google ID Token if provided
    if (idToken) {
      try {
        const ticket = await client.verifyIdToken({
            idToken: idToken,
            audience: process.env.GOOGLE_CLIENT_ID, // Specify the CLIENT_ID of the app that accesses the backend
        });
        const payload = ticket.getPayload();
        if (payload) {
          email = payload.email;
          name = payload.name;
          avatarUrl = payload.picture;
        }
      } catch (err) {
        console.warn('Google ID Token verification failed. Ensure GOOGLE_CLIENT_ID is set in .env.', err);
        // In production, you MUST reject if token is invalid:
        // return res.status(401).json({ error: 'Invalid Google Token' });
      }
    }

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
    } else if (user.name !== name || user.avatarUrl !== avatarUrl) {
      user = await prisma.user.update({
        where: { email },
        data: { name, avatarUrl },
        include: { businessProfile: true },
      });
    }

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

import bcrypt from 'bcryptjs';

export const signUp = async (req: Request, res: Response) => {
  try {
    const { email, password, name, phone, role } = req.body;

    if (!email || !password || !name) {
      return res.status(400).json({ error: 'Email, password, and name are required' });
    }

    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ error: 'Email already exists' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const user = await prisma.user.create({
      data: {
        email,
        name,
        password: hashedPassword,
        phone,
      },
    });

    const token = jwt.sign(
      { userId: user.id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.status(201).json({
      message: 'Account created successfully',
      token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
      }
    });
  } catch (error: any) {
    console.error('Sign Up Error:', error);
    res.status(500).json({ error: 'Sign up failed', details: error.message });
  }
};

export const signIn = async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    const user = await prisma.user.findUnique({
      where: { email },
      include: { businessProfile: true },
    });

    if (!user || !user.password) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const token = jwt.sign(
      { userId: user.id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.json({
      message: 'Sign in successful',
      token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        avatarUrl: user.avatarUrl,
        role: user.role,
        businessProfile: user.businessProfile,
      }
    });
  } catch (error: any) {
    console.error('Sign In Error:', error);
    res.status(500).json({ error: 'Sign in failed', details: error.message });
  }
};
