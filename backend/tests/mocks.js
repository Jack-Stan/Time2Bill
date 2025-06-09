// Mocks voor Firebase Admin en andere services
import { jest } from '@jest/globals';

// Mock voor Firebase Admin
export const mockFirebaseAdmin = {
  firestore: jest.fn(() => ({
    collection: jest.fn(() => ({
      doc: jest.fn(() => ({
        set: jest.fn(() => Promise.resolve()),
        get: jest.fn(() => Promise.resolve({
          exists: true,
          data: () => ({ id: '123', name: 'Test' }),
          id: '123'
        })),
        update: jest.fn(() => Promise.resolve()),
        delete: jest.fn(() => Promise.resolve())
      })),
      where: jest.fn(() => ({
        get: jest.fn(() => Promise.resolve({
          empty: false,
          docs: [
            {
              id: '123',
              data: () => ({ name: 'Test' }),
              exists: true
            }
          ]
        }))
      })),
      add: jest.fn(() => Promise.resolve({ id: '123' })),
      get: jest.fn(() => Promise.resolve({
        empty: false,
        docs: [
          {
            id: '123',
            data: () => ({ name: 'Test' }),
            exists: true
          }
        ]
      }))
    })),
    FieldValue: {
      serverTimestamp: jest.fn(() => new Date())
    },
    batch: jest.fn(() => ({
      set: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
      commit: jest.fn(() => Promise.resolve())
    }))
  })),
  auth: jest.fn(() => ({
    verifyIdToken: jest.fn(() => Promise.resolve({ uid: 'testuid' }))
  }))
};

// Mock voor de authentication middleware
export const mockAuthMiddleware = jest.fn((req, res, next) => {
  req.user = { uid: 'testuid' };
  next();
});

export const setupMocks = () => {
  // Mock firebase config
  jest.mock('../src/config/firebase.config.js', () => ({
    default: {
      initializeFirebaseAdmin: jest.fn(),
      getFirebaseAdmin: jest.fn(() => mockFirebaseAdmin)
    }
  }));
  
  // Mock auth middleware
  jest.mock('../src/middleware/auth.middleware.js', () => ({
    default: mockAuthMiddleware,
    authMiddleware: mockAuthMiddleware
  }));
};
