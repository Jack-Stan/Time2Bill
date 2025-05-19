import express from 'express';
import userRoutes from '../src/routes/users.js';
import projectRoutes from '../src/routes/projects.js';
import clientRoutes from '../src/routes/clients.js';
import invoiceRoutes from '../src/routes/invoices.js';
import configRoutes from '../src/routes/config.js';
import cors from 'cors';
import { setupMocks, mockAuthMiddleware } from './mocks.js';

// Setup de mocks voordat we de server maken
setupMocks();

export function createTestServer() {
  const app = express();
  
  // CORS configuratie
  app.use(cors());
  app.use(express.json());
  
  // Public routes
  app.get('/api/test', (req, res) => {
    res.json({ message: 'Backend is working!' });
  });

  // Protected routes
  app.use('/api/users', userRoutes);
  app.use('/api/projects', mockAuthMiddleware, projectRoutes);
  app.use('/api/clients', mockAuthMiddleware, clientRoutes);
  app.use('/api/invoices', mockAuthMiddleware, invoiceRoutes);
  app.use('/api/config', mockAuthMiddleware, configRoutes);
  
  return app;
}
