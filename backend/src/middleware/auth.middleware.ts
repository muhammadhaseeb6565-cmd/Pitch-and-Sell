import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'emulgic_pitch_and_sell_secret_key';

export interface AuthenticatedRequest extends Request {
  user?: {
    userId: string;
    email: string;
    role: string;
  };
}

export const authenticateJWT = (req: Request, res: Response, next: NextFunction) => {
  const authHeader = req.headers.authorization;

  if (authHeader) {
    const token = authHeader.split(' ')[1]; // Bearer <token>

    jwt.verify(token, JWT_SECRET, (err, user) => {
      if (err) {
        return res.status(403).json({ error: 'Forbidden: Invalid token' });
      }

      (req as AuthenticatedRequest).user = user as any;
      next();
    });
  } else {
    res.status(401).json({ error: 'Unauthorized: No token provided' });
  }
};

export const requireAdmin = (req: Request, res: Response, next: NextFunction) => {
  const user = (req as AuthenticatedRequest).user;
  if (!user || user.role !== 'ADMIN') {
    return res.status(403).json({ error: 'Forbidden: Admin role required' });
  }
  next();
};
