// Simple test to verify that Jest is working correctly
import { jest } from '@jest/globals';

describe('Basic Test', () => {
  it('should pass a simple test', () => {
    expect(1 + 1).toBe(2);
  });
  
  it('should verify true is true', () => {
    expect(true).toBe(true);
  });
});
