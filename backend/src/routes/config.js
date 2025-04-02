import express from 'express';
import { getFirebaseConfig } from '../config/firebase.config.js';

const router = express.Router();

router.get('/firebase', (req, res) => {
  res.json(getFirebaseConfig());
});

export default router;
