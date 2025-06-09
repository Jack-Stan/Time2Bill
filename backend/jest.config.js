export default {
  testEnvironment: 'node',
  verbose: true,
  transform: {},
  extensionsToTreatAsEsm: ['.ts'],
  testEnvironmentOptions: {
    customExportConditions: ['node', 'node-addons'],
  },
  moduleNameMapper: {
    '^../src/(.*)$': '<rootDir>/src/$1',
    '^./src/(.*)$': '<rootDir>/src/$1',
  },
  setupFiles: ['<rootDir>/tests/jest-mocks.js', '<rootDir>/tests/setup-server.js'],  setupFilesAfterEnv: ['<rootDir>/tests/mocks.js'],  
  transformIgnorePatterns: [],
  collectCoverageFrom: [
    'src/**/*.js',
    '!src/config/**',
    '!**/*.config.js',
    '!**/node_modules/**',
  ],  coverageThreshold: {
    global: {
      branches: 0,
      functions: 0,
      lines: 0,
      statements: 0,
    },
  },
  testMatch: ['**/__tests__/**/*.js', '**/?(*.)+(spec|test).js'],
};
