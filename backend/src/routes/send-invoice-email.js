import express from 'express';
import nodemailer from 'nodemailer';

const router = express.Router();

router.post('/', async (req, res) => {
  try {
    const { to, subject, body, pdfBase64, fileName } = req.body;
    if (!to || !subject || !body || !pdfBase64 || !fileName) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Configureer je mailtransporter
    const transporter = nodemailer.createTransport({
      // ...jouw SMTP config...
    });

    await transporter.sendMail({
      from: '"Time2Bill" <noreply@yourdomain.com>',
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
    });

    res.json({ success: true });
  } catch (error) {
    console.error('Error sending invoice email:', error);
    res.status(500).json({ error: error.message });
  }
});

export default router;
