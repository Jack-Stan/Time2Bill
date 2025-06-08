import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const sendInvoiceEmail = functions.https.onCall(async (data, context) => {
  try {
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'The function must be called while authenticated.'
      );
    }

    const { to, subject, body, pdfBase64, fileName } = data;
    const userId = context.auth.uid;

    // Validate required fields
    if (!to || !subject || !body || !pdfBase64 || !fileName) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing required fields',
        { required: ['to', 'subject', 'body', 'pdfBase64', 'fileName'] }
      );
    }

    // Get business settings
    const businessSettings = await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('settings')
      .doc('business')
      .get();

    if (!businessSettings.exists) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Business settings are missing'
      );
    }

    const settings = businessSettings.data();

    // Create email message document to trigger the extension
    const mailData = {
      to,
      message: {
        subject,
        text: body,
        html: body.replace(/\n/g, '<br>'),
        attachments: [{
          filename: fileName,
          content: pdfBase64,
          contentType: 'application/pdf',
          encoding: 'base64'
        }]
      },
      from: `${settings.companyName} <noreply@yourdomain.com>`
    };

    await admin.firestore().collection('mail').add(mailData);

    // Update invoice status
    const match = fileName.match(/factuur_(.+)\.pdf/);
    if (match && match[1]) {
      const invoiceNumber = match[1];
      const invoicesRef = admin.firestore()
        .collection('users')
        .doc(userId)
        .collection('invoices');
        
      const invoiceQuery = await invoicesRef
        .where('invoiceNumber', '==', invoiceNumber)
        .limit(1)
        .get();
        
      if (!invoiceQuery.empty) {
        await invoicesRef.doc(invoiceQuery.docs[0].id).update({
          status: 'sent',
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }

    return { success: true };
  } catch (error) {
    console.error('Error sending invoice email:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send email', error);
  }
});
