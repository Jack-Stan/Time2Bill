/**
 * Firestore Backup Script
 * 
 * This script creates a backup of the Firestore database.
 * It exports the data to a JSON file with a timestamp.
 * 
 * Usage: node backup_firestore.js [output-dir]
 * 
 * Arguments:
 *   output-dir: Optional directory to save the backup (default: ./backups)
 */

import { getFirebaseAdmin } from '../src/config/firebase.config.js';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// Get __dirname equivalent in ES modules
const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Initialize Firebase Admin
import { initializeFirebaseAdmin } from '../src/config/firebase.config.js';
initializeFirebaseAdmin();
const admin = getFirebaseAdmin();
const firestore = admin.firestore();

// Configure backup directory
const backupDir = process.argv[2] || path.join(__dirname, '..', 'backups');

// Ensure the backup directory exists
if (!fs.existsSync(backupDir)) {
  fs.mkdirSync(backupDir, { recursive: true });
  console.log(`Created backup directory: ${backupDir}`);
}

// Generate timestamp for the backup filename
const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
const backupFilename = `firestore-backup-${timestamp}.json`;
const backupPath = path.join(backupDir, backupFilename);

/**
 * Recursively gets all documents and subcollections from a collection
 */
async function getCollectionData(collectionRef, documentLimit = 0) {
  const snapshot = documentLimit > 0 
    ? await collectionRef.limit(documentLimit).get()
    : await collectionRef.get();
  
  const data = [];
  
  for (const doc of snapshot.docs) {
    const docData = doc.data();
    const subCollections = await firestore.collection(collectionRef.path).doc(doc.id).listCollections();
    
    // Process subcollections
    const subCollectionData = {};
    for (const subCollection of subCollections) {
      subCollectionData[subCollection.id] = await getCollectionData(subCollection);
    }
    
    data.push({
      id: doc.id,
      path: doc.ref.path,
      data: docData,
      subcollections: subCollectionData
    });
  }
  
  return data;
}

async function backupFirestore() {
  try {
    console.log('Starting Firestore backup...');
    
    // Get all top-level collections
    const collections = await firestore.listCollections();
    
    // Process each collection
    const backupData = {};
    for (const collection of collections) {
      console.log(`Processing collection: ${collection.id}`);
      backupData[collection.id] = await getCollectionData(collection);
    }
    
    // Write backup to file
    fs.writeFileSync(backupPath, JSON.stringify(backupData, null, 2));
    
    console.log(`Backup completed successfully and saved to: ${backupPath}`);
    return backupPath;
    
  } catch (error) {
    console.error('Error creating backup:', error);
    throw error;
  } finally {
    // Exit the process
    process.exit(0);
  }
}

// Run the backup
backupFirestore();
