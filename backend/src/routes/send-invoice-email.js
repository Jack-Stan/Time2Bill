import express from 'express';
import nodemailer from 'nodemailer';
import { getFirebaseAdmin } from '../config/firebase.config.js';
import { authMiddleware } from '../middleware/auth.middleware.js';

const router = express.Router();
const admin = getFirebaseAdmin();

router.post('/', authMiddleware, async (req, res) => {
  try {
    const { to, subject, body, pdfBase64, fileName } = req.body;
    if (!to || !subject || !body || !pdfBase64 || !fileName) {
      return res.status(400).json({ error: 'Missing required fields' });
    }
    
    // Get user's email settings from Firestore
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(req.user.uid)
      .collection('settings')
      .doc('email')
      .get();

    if (!userDoc.exists) {
      return res.status(400).json({ error: 'Email settings not configured' });
    }

    const emailSettings = userDoc.data();
    
    // Validate required email settings
    if (!emailSettings.smtpHost || !emailSettings.smtpPort || !emailSettings.smtpEmail || !emailSettings.smtpPassword) {
      return res.status(400).json({ error: 'Incomplete email settings' });
    }

    // Configure mail transporter with ProtonMail SMTP
    const transportConfig = {
      host: emailSettings.smtpHost,
      port: emailSettings.smtpPort,
      secure: emailSettings.smtpSecure, // true for 465, false for other ports
      auth: {
        user: emailSettings.smtpEmail,
        pass: emailSettings.smtpPassword
      },
      // Proper TLS configuration for ProtonMail
      tls: {
        rejectUnauthorized: true, // Verify TLS certificates
        minVersion: 'TLSv1.2'
      }
    };

    const transporter = nodemailer.createTransport(transportConfig);

    // Verify connection configuration
    try {
      await transporter.verify();
    } catch (verifyError) {
      console.error('SMTP Connection verification failed:', verifyError);
      return res.status(500).json({ 
        error: 'Failed to connect to email server',
        details: verifyError.message
      });
    }

    // Handle PGP encryption if enabled
    let emailConfig = {
      from: `"${emailSettings.smtpEmail}" <${emailSettings.smtpEmail}>`,
      to,
      subject,
      text: body,
      attachments: [
        {
          filename: fileName,
          content: Buffer.from(pdfBase64, 'base64'),
          contentType: 'application/pdf',
        },
      ],
    };

    // Add PGP signing if enabled
    if (emailSettings.signExternalMessages) {
      emailConfig.pgp = {
        sign: true,
        scheme: emailSettings.pgpScheme || 'PGP/MIME'
      };
      if (emailSettings.attachPublicKey) {
        emailConfig.attachments.push({
          filename: 'public-key.asc',
          path: `${process.env.PGP_PUBLIC_KEY_PATH}`
        });
      }
    }

    await transporter.sendMail(emailConfig);

    res.json({ success: true });
  } catch (error) {
    console.error('Error sending invoice email:', error);
    
    // Send appropriate error response based on error type
    if (error.code === 'ECONNECTION' || error.code === 'ENOTFOUND') {
      return res.status(503).json({
        error: 'Unable to connect to email server',
        details: error.message
      });
    } else if (error.code === 'EAUTH') {
      return res.status(401).json({
        error: 'Email authentication failed',
        details: error.message
      });
    }
    
    res.status(500).json({ 
      error: 'Failed to send email',
      details: error.message
    });
  }
});

export default router;
