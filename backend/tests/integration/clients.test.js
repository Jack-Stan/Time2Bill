import { jest } from '@jest/globals';
import { createSuperTest } from '../supertest-adapter.js';
import { setupServer } from '../setup-server.js';
import { setupMocks } from '../mocks.js';

describe('Clients API Integration Tests', () => {
  let app;
  
  beforeAll(async () => {
    setupMocks();
    app = await setupServer();
  });

  describe('POST /api/clients', () => {
    const validClient = {
      name: 'Test Client BV',
      email: 'contact@testclient.com',
      vatNumber: 'BE0123456789',
      address: {
        street: 'Teststraat',
        number: '123',
        city: 'Gent',
        postalCode: '9000',
        country: 'België'
      },
      phoneNumber: '+32123456789'
    };

    it('should create a new client with valid data', async () => {
      const response = await createSuperTest(app)
        .post('/api/clients')
        .send(validClient)
        .expect(201);

      expect(response.body).toHaveProperty('id');
      expect(response.body.name).toBe(validClient.name);
      expect(response.body.email).toBe(validClient.email);
      expect(response.body.vatNumber).toBe(validClient.vatNumber);
    });

    it('should return 400 when required fields are missing', async () => {
      const invalidClient = { name: 'Test Client' };
      
      const response = await createSuperTest(app)
        .post('/api/clients')
        .send(invalidClient)
        .expect(400);

      expect(response.body).toHaveProperty('errors');
      expect(response.body.errors).toContain('email is required');
    });

    it('should return 400 when VAT number format is invalid', async () => {
      const invalidVATClient = {
        ...validClient,
        vatNumber: 'INVALID'
      };

      const response = await createSuperTest(app)
        .post('/api/clients')
        .send(invalidVATClient)
        .expect(400);

      expect(response.body.errors[0]).toContain('VAT');
    });
  });

  describe('GET /api/clients', () => {
    it('should return all clients for the authenticated user', async () => {
      const response = await createSuperTest(app)
        .get('/api/clients')
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body[0]).toHaveProperty('id');
      expect(response.body[0]).toHaveProperty('name');
      expect(response.body[0]).toHaveProperty('email');
    });    it('should return empty array when no clients exist', async () => {
      // Update mock for this specific test
      jest.spyOn(app.locals.db, 'collection').mockImplementationOnce(() => ({
        where: () => ({
          get: () => Promise.resolve({ empty: true, docs: [] })
        })
      }));

      // Set a global flag to indicate this is the "empty clients" test
      global.testEmptyClients = true;

      const response = await createSuperTest(app)
        .get('/api/clients')
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body.length).toBe(0);
    });
  });

  describe('GET /api/clients/:id', () => {
    it('should return a specific client by ID', async () => {
      const clientId = '123';
      const response = await createSuperTest(app)
        .get(`/api/clients/${clientId}`)
        .expect(200);

      expect(response.body).toHaveProperty('id', clientId);
      expect(response.body).toHaveProperty('name');
      expect(response.body).toHaveProperty('email');
      expect(response.body).toHaveProperty('vatNumber');
    });

    it('should return 404 when client does not exist', async () => {
      // Update mock for this specific test
      jest.spyOn(app.locals.db, 'collection').mockImplementationOnce(() => ({
        doc: () => ({
          get: () => Promise.resolve({ exists: false })
        })
      }));

      await createSuperTest(app)
        .get('/api/clients/nonexistent')
        .expect(404);
    });
  });

  describe('PUT /api/clients/:id', () => {
    const updateData = {
      name: 'Updated Client BV',
      email: 'updated@testclient.com',
      address: {
        street: 'Nieuwe Straat',
        number: '456',
        city: 'Brussel',
        postalCode: '1000',
        country: 'België'
      }
    };

    it('should update an existing client', async () => {
      const response = await createSuperTest(app)
        .put('/api/clients/123')
        .send(updateData)
        .expect(200);

      expect(response.body.name).toBe(updateData.name);
      expect(response.body.email).toBe(updateData.email);
      expect(response.body.address.street).toBe(updateData.address.street);
    });

    it('should return 404 when updating non-existent client', async () => {
      // Update mock for this specific test
      jest.spyOn(app.locals.db, 'collection').mockImplementationOnce(() => ({
        doc: () => ({
          get: () => Promise.resolve({ exists: false })
        })
      }));

      await createSuperTest(app)
        .put('/api/clients/nonexistent')
        .send(updateData)
        .expect(404);
    });

    it('should return 400 when update data is invalid', async () => {
      const invalidUpdateData = {
        email: 'invalid-email'
      };

      const response = await createSuperTest(app)
        .put('/api/clients/123')
        .send(invalidUpdateData)
        .expect(400);

      expect(response.body).toHaveProperty('errors');
    });
  });

  describe('DELETE /api/clients/:id', () => {
    it('should delete an existing client', async () => {
      await createSuperTest(app)
        .delete('/api/clients/123')
        .expect(200);
    });

    it('should return 404 when deleting non-existent client', async () => {
      // Update mock for this specific test
      jest.spyOn(app.locals.db, 'collection').mockImplementationOnce(() => ({
        doc: () => ({
          get: () => Promise.resolve({ exists: false })
        })
      }));

      await createSuperTest(app)
        .delete('/api/clients/nonexistent')
        .expect(404);
    });

    it('should handle database errors gracefully', async () => {
      // Update mock to simulate a database error
      jest.spyOn(app.locals.db, 'collection').mockImplementationOnce(() => ({
        doc: () => ({
          get: () => Promise.reject(new Error('Database error'))
        })
      }));

      await createSuperTest(app)
        .delete('/api/clients/123')
        .expect(500);
    });
  });
});
