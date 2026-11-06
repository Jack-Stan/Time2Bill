// Test-only Firebase service-account values. The real credentials live in
// backend/.env (gitignored) and are never needed by the mocked test suite.
// A throwaway RSA key is generated per run so firebase-admin's cert() check passes
// without any real secret, locally or in CI. Values already set in the
// environment are left alone.
import { generateKeyPairSync } from 'crypto';

if (!process.env.FIREBASE_PRIVATE_KEY) {
  const { privateKey } = generateKeyPairSync('rsa', {
    modulusLength: 2048,
    privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
    publicKeyEncoding: { type: 'spki', format: 'pem' },
  });
  process.env.FIREBASE_PRIVATE_KEY = privateKey;
}
process.env.FIREBASE_PROJECT_ID ??= 'test-project';
process.env.FIREBASE_CLIENT_EMAIL ??= 'test@test-project.iam.gserviceaccount.com';
