import express from 'express';
import { getFirebaseAdmin } from '../config/firebase.config.js';
import { authMiddleware } from '../middleware/auth.middleware.js';
import { validateRequest } from '../middleware/validation.middleware.js';
import Joi from 'joi';

const router = express.Router();
const admin = getFirebaseAdmin();

// Validation schemas
const userRegisterSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().min(6).required(),
  fullName: Joi.string().required().min(3)
});

const businessDetailsSchema = Joi.object({
  companyName: Joi.string().required(),
  address: Joi.string().required(),
  city: Joi.string().required(),
  postalCode: Joi.string().required(),
  country: Joi.string().required(),
  vatNumber: Joi.string().allow(null, ''),
  peppolId: Joi.string().allow(null, '')
});

const bankingDetailsSchema = Joi.object({
  accountNumber: Joi.string().required(),
  bankName: Joi.string().required(),
  accountHolder: Joi.string().required(),
  swiftBic: Joi.string().allow(null, '')
});

// User registration - no auth required
router.post('/', validateRequest(userRegisterSchema), async (req, res) => {
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

// Protected routes below - require authentication

// Update business details
router.put('/:userId/business-details', authMiddleware, validateRequest(businessDetailsSchema), async (req, res) => {
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
router.put('/:userId/banking-details', authMiddleware, validateRequest(bankingDetailsSchema), async (req, res) => {
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
router.get('/:userId/verification-status', authMiddleware, async (req, res) => {
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
router.post('/:userId/resend-verification', authMiddleware, async (req, res) => {
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
