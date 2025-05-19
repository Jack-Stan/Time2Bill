import express from 'express';
import cors from 'cors';
import { initializeFirebaseAdmin, getFirebaseAdmin } from './config/firebase.config.js';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { authMiddleware } from './middleware/auth.middleware.js';
import userRoutes from './routes/users.js';
import projectRoutes from './routes/projects.js';
import clientRoutes from './routes/clients.js';
import invoiceRoutes from './routes/invoices.js';
import configRoutes from './routes/config.js';

const __dirname = dirname(fileURLToPath(import.meta.url));

dotenv.config();

const app = express();

// Update CORS configuration to accept any localhost origin
app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (like mobile apps or curl requests)
    if (!origin) return callback(null, true);
    
    // Allow all localhost origins
    if (origin.startsWith('http://localhost:')) {
      return callback(null, true);
    }
    
    callback(new Error('Not allowed by CORS'));
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Pre-flight requests
app.options('*', cors());

app.use(express.json());

// Initialize Firebase Admin
initializeFirebaseAdmin();
const admin = getFirebaseAdmin();

// Public routes
app.get('/api/test', (req, res) => {
  res.json({ message: 'Backend is working!' });
});

app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok',
    firebase: admin.app().name ? 'connected' : 'not connected'
  });
});

app.use('/api/config', configRoutes);

// Registration route doesn't need auth
app.use('/api/users', userRoutes);

// Protected routes with authentication middleware
app.use('/api/projects', authMiddleware, projectRoutes);
app.use('/api/clients', authMiddleware, clientRoutes);
app.use('/api/invoices', authMiddleware, invoiceRoutes);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
