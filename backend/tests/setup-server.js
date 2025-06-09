import { jest } from '@jest/globals';
import express from 'express';
import userRoutes from '../src/routes/users.js';
import projectRoutes from '../src/routes/projects.js';
import clientRoutes from '../src/routes/clients.js';
import invoiceRoutes from '../src/routes/invoices.js';
import configRoutes from '../src/routes/config.js';
import cors from 'cors';
import { setupMocks, mockAuthMiddleware } from './mocks.js';

export async function createTestServer() {
  const app = express();
  
  // CORS configuratie
  app.use(cors());
  app.use(express.json());
  
  // Voeg de mockDB toe aan app.locals
  app.locals.db = {
    collection: jest.fn(() => ({
      doc: jest.fn(),
      where: jest.fn(),
      get: jest.fn()
    }))
  };
  
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

export async function setupServer() {
  const app = await createTestServer();
  
  // Auth middleware voor beschermde routes
  app.use('/api/clients', mockAuthMiddleware);
  app.use('/api/projects', mockAuthMiddleware);
  app.use('/api/invoices', mockAuthMiddleware);
  app.use('/api/users', mockAuthMiddleware);
  app.use('/api/config', mockAuthMiddleware);

  // Routes
  app.use('/api/users', userRoutes);
  app.use('/api/projects', projectRoutes);
  app.use('/api/clients', clientRoutes);
  app.use('/api/invoices', invoiceRoutes);
  app.use('/api/config', configRoutes);

  return app;
}
