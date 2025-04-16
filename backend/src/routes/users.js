import express from 'express';
import { getFirebaseAdmin } from '../config/firebase.config.js';

const router = express.Router();
const admin = getFirebaseAdmin();

// User registration
router.post('/', async (req, res) => {
  try {
    console.log('Step 1: Received registration request:', req.body);

    const { email, password, fullName } = req.body;
    
    if (!email || !password || !fullName) {
      console.log('Step 2: Missing required fields');
      return res.status(400).json({ error: 'Missing required fields' });
    }

    console.log('Step 3: Creating Firebase user...');
    const userRecord = await admin.auth().createUser({
      email,
      password,
      displayName: fullName,
      emailVerified: false
    });
    console.log('Step 4: Firebase user created:', userRecord.uid);

    console.log('Step 5: Sending verification email...');
    const verificationLink = await admin.auth().generateEmailVerificationLink(email, {
      url: 'http://localhost:3000/verify-email-success',
    });
    // Here you would typically send this link via your email service
    console.log('Verification link generated:', verificationLink);

    console.log('Step 6: Creating Firestore document...');
    await admin.firestore().collection('users').doc(userRecord.uid).set({
      fullName,
      email,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'pending_verification',
      role: 'user',
      lastLogin: admin.firestore.FieldValue.serverTimestamp(),
      profile_completed: false
    });
    console.log('Step 7: Firestore document created');

    res.status(201).json({ 
      uid: userRecord.uid,
      message: 'User created successfully. Please check your email for verification.',
      verificationLink // Temporary: sending link in response for testing
    });
  } catch (error) {
    console.error('Registration error:', error);
    
    // Provide more user-friendly error messages
    let errorMessage = error.message;
    if (error.code === 'auth/too-many-requests') {
      errorMessage = 'Too many attempts. Please try again later.';
    }

    res.status(400).json({ 
      error: errorMessage
    });
  }
});

// Update business details
router.put('/:userId/business-details', async (req, res) => {
  try {
    const { userId } = req.params;
    const details = req.body;

    // Only include peppolId if it's provided
    const businessDetails = {
      ...details,
      peppolId: details.peppolId || null, // Make sure it's null if not provided
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    };

    await admin.firestore().collection('users').doc(userId).update({
      'businessDetails': businessDetails,
      'status': 'business_details_added',
      'updatedAt': admin.firestore.FieldValue.serverTimestamp(),
      'profile_completed': true
    });

    res.json({ message: 'Business details updated successfully' });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Update banking details
router.put('/:userId/banking-details', async (req, res) => {
  try {
    const { userId } = req.params;
    const details = req.body;

    await admin.firestore().collection('users').doc(userId).update({
      'bankingDetails': details,
      'status': 'active',
      'updatedAt': admin.firestore.FieldValue.serverTimestamp()
    });

    res.json({ message: 'Banking details updated successfully' });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Add email verification check endpoint
router.get('/:userId/verification-status', async (req, res) => {
  try {
    const { userId } = req.params;
    const user = await admin.auth().getUser(userId);
    
    res.json({ 
      emailVerified: user.emailVerified,
      email: user.email 
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Resend verification email
router.post('/:userId/resend-verification', async (req, res) => {
  try {
    const { userId } = req.params;
    const user = await admin.auth().getUser(userId);
    
    const verificationLink = await admin.auth().generateEmailVerificationLink(
      user.email,
      { url: 'http://localhost:3000/verify-email-success' }
    );

    // Here you would typically send the email
    console.log('New verification link generated:', verificationLink);

    res.json({ 
      message: 'Verification email sent',
      verificationLink // Remove in production
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

export default router;
