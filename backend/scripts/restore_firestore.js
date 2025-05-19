/**
 * Firestore Restore Script
 * 
 * This script restores a Firestore database from a backup JSON file.
 * 
 * Usage: node restore_firestore.js <backup-file-path>
 * 
 * Arguments:
 *   backup-file-path: Required path to the backup JSON file
 */

import { getFirebaseAdmin } from '../src/config/firebase.config.js';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import readline from 'readline';

// Get __dirname equivalent in ES modules
const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Initialize Firebase Admin
import { initializeFirebaseAdmin } from '../src/config/firebase.config.js';
initializeFirebaseAdmin();
const admin = getFirebaseAdmin();
const firestore = admin.firestore();

// Get backup file path from command line
const backupFilePath = process.argv[2];
if (!backupFilePath) {
  console.error('Error: No backup file specified');
  console.log('Usage: node restore_firestore.js <backup-file-path>');
  process.exit(1);
}

// Check if backup file exists
if (!fs.existsSync(backupFilePath)) {
  console.error(`Error: Backup file not found: ${backupFilePath}`);
  process.exit(1);
}

// Create readline interface for user confirmation
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

// Function to restore documents recursively
async function restoreDocument(docData) {
  try {
    // Extract document path and data
    const { id, path, data, subcollections } = docData;
    
    // Create or update the document
    const docRef = firestore.doc(path);
    console.log(`Restoring document: ${path}`);
    
    // Remove any non-standard fields that might cause issues
    const cleanData = { ...data };
    delete cleanData.id;  // Remove id if present in data
    
    // Convert any timestamps from the backup
    Object.keys(cleanData).forEach(key => {
      const value = cleanData[key];
      if (value && value._seconds !== undefined && value._nanoseconds !== undefined) {
        cleanData[key] = new admin.firestore.Timestamp(value._seconds, value._nanoseconds);
      }
    });
    
    // Set the document data
    await docRef.set(cleanData);
    
    // Process subcollections if any
    if (subcollections) {
      for (const [subCollectionName, subDocs] of Object.entries(subcollections)) {
        if (Array.isArray(subDocs)) {
          for (const subDoc of subDocs) {
            await restoreDocument(subDoc);
          }
        }
      }
    }
  } catch (error) {
    console.error(`Error restoring document: ${docData.path}`, error);
  }
}

// Main restore function
async function restoreFirestore() {
  try {
    console.log(`Reading backup from: ${backupFilePath}`);
    const backupData = JSON.parse(fs.readFileSync(backupFilePath, 'utf8'));
    
    console.log('Starting Firestore restore...');
    
    // Process each collection
    for (const [collectionName, documents] of Object.entries(backupData)) {
      console.log(`Processing collection: ${collectionName}`);
      if (Array.isArray(documents)) {
        for (const doc of documents) {
          await restoreDocument(doc);
        }
      }
    }
    
    console.log('Restore completed successfully!');
    
  } catch (error) {
    console.error('Error during restore:', error);
  } finally {
    process.exit(0);
  }
}

// Ask for confirmation before proceeding
rl.question('WARNING: This will overwrite existing data in Firestore. Continue? (y/N) ', async (answer) => {
  if (answer.toLowerCase() === 'y') {
    await restoreFirestore();
  } else {
    console.log('Restore cancelled.');
    process.exit(0);
  }
  rl.close();
});
