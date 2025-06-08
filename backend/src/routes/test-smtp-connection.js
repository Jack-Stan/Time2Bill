import express from 'express';
import nodemailer from 'nodemailer';
import { authMiddleware } from '../middleware/auth.middleware.js';

const router = express.Router();

router.post('/', authMiddleware, async (req, res) => {
  try {
    const { smtpHost, smtpPort, smtpSecure, smtpEmail, smtpPassword } = req.body;

    // Create test SMTP transporter
    const transporter = nodemailer.createTransport({
      host: smtpHost,
      port: smtpPort,
      secure: smtpSecure, // true for 465, false for other ports
      auth: {
        user: smtpEmail,
        pass: smtpPassword,
      },
      tls: {
        // Do not fail on invalid certs
        rejectUnauthorized: false
      }
    });

    // Verify SMTP connection
    await transporter.verify();
    
    res.json({ success: true, message: 'SMTP connection test successful' });
  } catch (error) {
    console.error('SMTP connection test failed:', error);
    res.status(400).json({ 
      success: false, 
      message: 'SMTP connection test failed',
      error: error.message 
    });
  }
});

export default router;
