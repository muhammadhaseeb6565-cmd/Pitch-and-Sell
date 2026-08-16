import express, { Request, Response, NextFunction } from 'express';
import http from 'http';
import { Server } from 'socket.io';
import cors from 'cors';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*', // Allow all origins for Flutter development
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  },
});

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Import API Routers
import authRoutes from './routes/auth.routes';
import businessRoutes from './routes/business.routes';
import productRoutes from './routes/product.routes';
import orderRoutes from './routes/order.routes';
import adminRoutes from './routes/admin.routes';
import aiRoutes from './routes/ai.route';
import paymentRoutes from './routes/payment.routes';

// Mount API Routers
app.use('/api/auth', authRoutes);
app.use('/api/business', businessRoutes);
app.use('/api/products', productRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/payments', paymentRoutes);

// Serve static uploaded videos/images
app.use('/uploads', express.static('uploads'));

// Basic Health Check Route
app.get('/health', (req: Request, res: Response) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Socket.io Real-Time Connection
io.on('connection', (socket) => {
  console.log(`User connected: ${socket.id}`);

  // Join a chat room
  socket.on('join_chat', (chatId: string) => {
    socket.join(chatId);
    console.log(`Socket ${socket.id} joined chat room: ${chatId}`);
  });

  // Handle message sending
  socket.on('send_message', (data: { chatId: string; senderId: string; content: string }) => {
    // Broadcast message to room
    io.to(data.chatId).emit('receive_message', data);
  });

  socket.on('disconnect', () => {
    console.log(`User disconnected: ${socket.id}`);
  });
});

// Error handling middleware
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Internal Server Error',
    message: err.message,
  });
});

const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
  console.log(`[Pitch and Sell Backend] Server is running on port ${PORT}`);
});

export { app, server, io };
