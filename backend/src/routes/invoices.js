import express from 'express';
import { getFirebaseAdmin } from '../config/firebase.config.js';

const router = express.Router();
const admin = getFirebaseAdmin();

// Create a new invoice
router.post('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const { projectId, clientId, dueDate, lineItems = [], total, notes = '' } = req.body;
    
    if (!projectId || !clientId || !total) {
      return res.status(400).json({ error: 'Missing required fields' });
    }
    
    const invoiceRef = admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('invoices')
      .doc();
    
    const invoiceData = {
      projectId,
      clientId,
      invoiceNumber: `INV-${Math.floor(10000 + Math.random() * 90000)}`,
      dueDate: dueDate ? new Date(dueDate) : null,
      lineItems,
      total: Number(total),
      notes,
      status: 'unpaid',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    };
    
    await invoiceRef.set(invoiceData);
    
    // Also create reference in project's invoices subcollection
    await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('projects')
      .doc(projectId)
      .collection('invoices')
      .doc(invoiceRef.id)
      .set({
        invoiceId: invoiceRef.id
      });
    
    res.status(201).json({
      id: invoiceRef.id,
      invoiceNumber: invoiceData.invoiceNumber,
      message: 'Invoice created successfully'
    });
    
  } catch (error) {
    console.error('Error creating invoice:', error);
    res.status(400).json({ error: error.message });
  }
});

// Get all invoices for a user
router.get('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const { status } = req.query;
    
    let query = admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('invoices')
      .orderBy('createdAt', 'desc');
    
    if (status) {
      query = query.where('status', '==', status);
    }
    
    const invoicesSnapshot = await query.get();
    
    const invoices = [];
    invoicesSnapshot.forEach(doc => {
      invoices.push({
        id: doc.id,
        ...doc.data()
      });
    });
    
    res.json(invoices);
    
  } catch (error) {
    console.error('Error fetching invoices:', error);
    res.status(400).json({ error: error.message });
  }
});

// Mark an invoice as paid
router.put('/:userId/:invoiceId/mark-paid', async (req, res) => {
  try {
    const { userId, invoiceId } = req.params;
    const { paymentDate = new Date() } = req.body;
    
    await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('invoices')
      .doc(invoiceId)
      .update({
        status: 'paid',
        paymentDate: new Date(paymentDate),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    
    res.json({ message: 'Invoice marked as paid' });
    
  } catch (error) {
    console.error('Error updating invoice status:', error);
    res.status(400).json({ error: error.message });
  }
});

export default router;
