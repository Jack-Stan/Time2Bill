import express from 'express';
import { getFirebaseAdmin } from '../config/firebase.config.js';

const router = express.Router();
const admin = getFirebaseAdmin();

// Create a new client
router.post('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const { name, email, phone, address, vatNumber } = req.body;
    
    if (!name) {
      return res.status(400).json({ error: 'Client name is required' });
    }
    
    const clientRef = admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('clients')
      .doc();
    
    await clientRef.set({
      name,
      email: email || null,
      phone: phone || null,
      address: address || null,
      vatNumber: vatNumber || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    res.status(201).json({ 
      id: clientRef.id,
      message: 'Client created successfully' 
    });
    
  } catch (error) {
    console.error('Client creation error:', error);
    res.status(400).json({ error: error.message });
  }
});

// Get all clients for a user
router.get('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    const clientsSnapshot = await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('clients')
      .orderBy('name')
      .get();
    
    const clients = [];
    clientsSnapshot.forEach(doc => {
      clients.push({
        id: doc.id,
        ...doc.data()
      });
    });
    
    res.json(clients);
    
  } catch (error) {
    console.error('Error fetching clients:', error);
    res.status(400).json({ error: error.message });
  }
});

// Get a specific client
router.get('/:userId/:clientId', async (req, res) => {
  try {
    const { userId, clientId } = req.params;
    
    const clientDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('clients')
      .doc(clientId)
      .get();
    
    if (!clientDoc.exists) {
      return res.status(404).json({ error: 'Client not found' });
    }
    
    // Get client's projects
    const projectsSnapshot = await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('clients')
      .doc(clientId)
      .collection('projects')
      .get();
    
    const projects = [];
    projectsSnapshot.forEach(doc => {
      projects.push({
        id: doc.id,
        ...doc.data()
      });
    });
    
    res.json({
      id: clientDoc.id,
      ...clientDoc.data(),
      projects
    });
    
  } catch (error) {
    console.error('Error fetching client:', error);
    res.status(400).json({ error: error.message });
  }
});

// Update a client
router.put('/:userId/:clientId', async (req, res) => {
  try {
    const { userId, clientId } = req.params;
    const updateData = req.body;
    
    // Add updatedAt timestamp
    updateData.updatedAt = admin.firestore.FieldValue.serverTimestamp();
    
    await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('clients')
      .doc(clientId)
      .update(updateData);
    
    res.json({ message: 'Client updated successfully' });
    
  } catch (error) {
    console.error('Error updating client:', error);
    res.status(400).json({ error: error.message });
  }
});

// Delete a client
router.delete('/:userId/:clientId', async (req, res) => {
  try {
    const { userId, clientId } = req.params;
    
    // Check if client has associated projects
    const projectsSnapshot = await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('clients')
      .doc(clientId)
      .collection('projects')
      .get();
    
    if (!projectsSnapshot.empty) {
      return res.status(400).json({ 
        error: 'Cannot delete client with associated projects. Please delete the projects first.' 
      });
    }
    
    await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('clients')
      .doc(clientId)
      .delete();
    
    res.json({ message: 'Client deleted successfully' });
    
  } catch (error) {
    console.error('Error deleting client:', error);
    res.status(400).json({ error: error.message });
  }
});

export default router;
