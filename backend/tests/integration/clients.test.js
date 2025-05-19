import { jest } from '@jest/globals';
import request from 'supertest';
import { createTestServer } from '../setup-server.js';

describe('API Endpoints Integration Tests', () => {
  let app;

  beforeAll(() => {
    app = createTestServer();
  });

  describe('GET /api/test', () => {
    it('should return a success message', async () => {
      const res = await request(app).get('/api/test');
      
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('message');
      expect(res.body.message).toBe('Backend is working!');
    });
  });

  describe('Clients API', () => {
    it('should create a new client', async () => {
      const userId = 'testuser123';
      const newClient = {
        name: 'Test Client',
        email: 'test@example.com',
        phone: '+1234567890',
        address: '123 Test St',
        vatNumber: 'VAT12345'
      };

      const res = await request(app)
        .post(`/api/clients/${userId}`)
        .send(newClient);
      
      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('id');
      expect(res.body).toHaveProperty('message', 'Client created successfully');
    });

    it('should fail if client name is missing', async () => {
      const userId = 'testuser123';
      const invalidClient = {
        email: 'test@example.com',
        phone: '+1234567890',
        address: '123 Test St',
        vatNumber: 'VAT12345'
      };

      const res = await request(app)
        .post(`/api/clients/${userId}`)
        .send(invalidClient);
      
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('error');
    });
  });
});
