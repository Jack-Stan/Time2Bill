import express from 'express';
import { getFirebaseAdmin } from '../config/firebase.config.js';

const router = express.Router();
const admin = getFirebaseAdmin();

// Create a new project
router.post('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const { title, description, clientId, status = 'active' } = req.body;
    
    if (!title || !clientId) {
      return res.status(400).json({ error: 'Missing required fields' });
    }
    
    // Create a project document in the projects subcollection
    const projectRef = admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('projects')
      .doc();
    
    await projectRef.set({
      title,
      description: description || '',
      clientId,
      status,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    // Also add reference to client's projects subcollection
    await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('clients')
      .doc(clientId)
      .collection('projects')
      .doc(projectRef.id)
      .set({
        projectId: projectRef.id
      });
    
    res.status(201).json({ 
      id: projectRef.id,
      message: 'Project created successfully' 
    });
    
  } catch (error) {
    console.error('Project creation error:', error);
    res.status(400).json({ error: error.message });
  }
});

// Get all projects for a user
router.get('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const projectsSnapshot = await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('projects')
      .orderBy('createdAt', 'desc')
      .get();
    
    const projects = [];
    projectsSnapshot.forEach(doc => {
      projects.push({
        id: doc.id,
        ...doc.data()
      });
    });
    
    res.json(projects);
    
  } catch (error) {
    console.error('Error fetching projects:', error);
    res.status(400).json({ error: error.message });
  }
});

// Get a specific project
router.get('/:userId/:projectId', async (req, res) => {
  try {
    const { userId, projectId } = req.params;
    
    const projectDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('projects')
      .doc(projectId)
      .get();
    
    if (!projectDoc.exists) {
      return res.status(404).json({ error: 'Project not found' });
    }
    
    res.json({
      id: projectDoc.id,
      ...projectDoc.data()
    });
    
  } catch (error) {
    console.error('Error fetching project:', error);
    res.status(400).json({ error: error.message });
  }
});

// Update a project
router.put('/:userId/:projectId', async (req, res) => {
  try {
    const { userId, projectId } = req.params;
    const updateData = req.body;
    
    // Add updatedAt timestamp
    updateData.updatedAt = admin.firestore.FieldValue.serverTimestamp();
    
    await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('projects')
      .doc(projectId)
      .update(updateData);
    
    res.json({ message: 'Project updated successfully' });
    
  } catch (error) {
    console.error('Error updating project:', error);
    res.status(400).json({ error: error.message });
  }
});

// Delete a project
router.delete('/:userId/:projectId', async (req, res) => {
  try {
    const { userId, projectId } = req.params;
    
    // Get the project to find the clientId
    const projectDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('projects')
      .doc(projectId)
      .get();
    
    if (!projectDoc.exists) {
      return res.status(404).json({ error: 'Project not found' });
    }
    
    const { clientId } = projectDoc.data();
    
    // Start a batch operation
    const batch = admin.firestore().batch();
    
    // Delete project from projects collection
    const projectRef = admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('projects')
      .doc(projectId);
    
    batch.delete(projectRef);
    
    // Delete reference from client's projects subcollection
    const clientProjectRef = admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('clients')
      .doc(clientId)
      .collection('projects')
      .doc(projectId);
    
    batch.delete(clientProjectRef);
    
    // Commit the batch
    await batch.commit();
    
    res.json({ message: 'Project deleted successfully' });
    
  } catch (error) {
    console.error('Error deleting project:', error);
    res.status(400).json({ error: error.message });
  }
});

// Create a todo for a project
router.post('/:userId/:projectId/todos', async (req, res) => {
  try {
    const { userId, projectId } = req.params;
    const { title, description, deadline, status = 'pending' } = req.body;
    
    if (!title) {
      return res.status(400).json({ error: 'Missing required fields' });
    }
    
    const todoRef = admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('projects')
      .doc(projectId)
      .collection('todos')
      .doc();
    
    await todoRef.set({
      title,
      description: description || '',
      status,
      deadline: deadline ? new Date(deadline) : null,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    res.status(201).json({
      id: todoRef.id,
      message: 'Todo created successfully'
    });
    
  } catch (error) {
    console.error('Error creating todo:', error);
    res.status(400).json({ error: error.message });
  }
});

// Get all todos for a project
router.get('/:userId/:projectId/todos', async (req, res) => {
  try {
    const { userId, projectId } = req.params;
    
    const todosSnapshot = await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('projects')
      .doc(projectId)
      .collection('todos')
      .orderBy('createdAt', 'desc')
      .get();
    
    const todos = [];
    todosSnapshot.forEach(doc => {
      todos.push({
        id: doc.id,
        ...doc.data()
      });
    });
    
    res.json(todos);
    
  } catch (error) {
    console.error('Error fetching todos:', error);
    res.status(400).json({ error: error.message });
  }
});

// Add a time tracking entry for a project
router.post('/:userId/:projectId/time-tracking', async (req, res) => {
  try {
    const { userId, projectId } = req.params;
    const { startTime, endTime, duration, todoId, description } = req.body;
    
    if (!startTime || !duration) {
      return res.status(400).json({ error: 'Missing required fields' });
    }
    
    const timeTrackRef = admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('projects')
      .doc(projectId)
      .collection('timeTracking')
      .doc();
    
    await timeTrackRef.set({
      startTime: new Date(startTime),
      endTime: endTime ? new Date(endTime) : null,
      duration: Number(duration), // Duration in seconds
      todoId: todoId || null,
      description: description || '',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    res.status(201).json({
      id: timeTrackRef.id,
      message: 'Time tracking entry created successfully'
    });
    
  } catch (error) {
    console.error('Error creating time tracking entry:', error);
    res.status(400).json({ error: error.message });
  }
});

export default router;
