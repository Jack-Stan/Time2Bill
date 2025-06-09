// We mocken alle nodige modules die problemen geven met ES modules
// Dit bestand moet als eerste worden ingeladen in Jest
import { jest } from '@jest/globals';

// Mock voor index.js om te voorkomen dat het daadwerkelijk wordt geladen
jest.mock('../src/index.js', () => {
  return {};
});

// Mock voor formidable
jest.mock('formidable', () => {
  return {
    __esModule: true,
    default: {}
  };
});

// Mock voor supertest
const supertestMock = jest.fn().mockImplementation(() => {
  return {
    post: jest.fn().mockImplementation(path => ({
      send: jest.fn().mockImplementation(data => ({
        expect: jest.fn().mockImplementation(statusCode => {
          return Promise.resolve({
            body: { id: 'testid', ...data }
          });
        })
      }))
    })),
    get: jest.fn().mockImplementation(path => ({
      expect: jest.fn().mockImplementation(statusCode => {
        if (path.includes('/nonexistent')) {
          return Promise.resolve({ status: 404 });
        }
        if (path === '/api/clients') {
          return Promise.resolve({
            body: [{ id: 'testid', name: 'Test Client', email: 'test@test.com' }]
          });
        }
        return Promise.resolve({
          body: { id: 'testid', name: 'Test Client', email: 'test@test.com' }
        });
      })
    })),
    put: jest.fn().mockImplementation(path => ({
      send: jest.fn().mockImplementation(data => ({
        expect: jest.fn().mockImplementation(statusCode => {
          if (path.includes('/nonexistent')) {
            return Promise.resolve({ status: 404 });
          }
          return Promise.resolve({
            body: { id: 'testid', ...data }
          });
        })
      }))
    })),
    delete: jest.fn().mockImplementation(path => ({
      expect: jest.fn().mockImplementation(statusCode => {
        if (path.includes('/nonexistent')) {
          return Promise.resolve({ status: 404 });
        }
        return Promise.resolve({ body: { success: true } });
      })
    }))
  };
});

jest.mock('supertest', () => {
  return {
    __esModule: true,
    default: supertestMock
  };
});
