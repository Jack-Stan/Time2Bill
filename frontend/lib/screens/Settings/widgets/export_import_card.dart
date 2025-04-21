import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class ExportImportCard extends StatefulWidget {
  final String userId;

  const ExportImportCard({
    super.key,
    required this.userId,
  });

  @override
  State<ExportImportCard> createState() => _ExportImportCardState();
}

class _ExportImportCardState extends State<ExportImportCard> {
  bool _isExporting = false;
  bool _isImporting = false;
  String? _errorMessage;
  String? _successMessage;

  Future<void> _exportData() async {
    setState(() {
      _isExporting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Fetch user data from Firestore
      Map<String, dynamic> exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'userData': {},
        'clients': [],
        'projects': [],
        'invoices': [],
        'timeTracking': [],
      };

      // Get user profile data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      
      if (userDoc.exists) {
        exportData['userData'] = userDoc.data() ?? {};
      }

      // Get clients
      final clientsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('clients')
          .get();
      
      exportData['clients'] = clientsSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      // Get projects
      final projectsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('projects')
          .get();
      
      exportData['projects'] = projectsSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      // Get invoices
      final invoicesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('invoices')
          .get();
      
      exportData['invoices'] = invoicesSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      // Get time tracking entries
      final timeTrackingSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('timeTracking')
          .get();
      
      exportData['timeTracking'] = timeTrackingSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      // Convert to JSON
      final jsonData = jsonEncode(exportData);
      
      // In a real app, we would initiate a download here
      // For now, just show a success message
      
      setState(() {
        _isExporting = false;
        _successMessage = 'Data exported successfully! In a production app, this would download a file.';
      });
      
      // For debugging
      print('Export data: ${jsonData.substring(0, 100)}...');
      
    } catch (error) {
      setState(() {
        _isExporting = false;
        _errorMessage = 'Error exporting data: ${error.toString()}';
      });
      print('Error exporting data: $error');
    }
  }

  Future<void> _importData() async {
    // In a real app, this would open a file picker
    // For now, just show a dialog explaining the feature
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text(
          'This feature would allow you to import data from a previously exported file. In a production app, this would open a file picker and validate the data before importing.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Data Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.storage, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Export or import your business data',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
                  ],
                ),
              ),
              
            if (_successMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_successMessage!, style: const TextStyle(color: Colors.green))),
                  ],
                ),
              ),
            
            // Export Feature
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Data'),
              subtitle: const Text('Download all your business data as a JSON file'),
              trailing: _isExporting 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2)
                    )
                  : const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _isExporting ? null : _exportData,
            ),
            
            const Divider(),
            
            // Import Feature
            ListTile(
              leading: const Icon(Icons.upload),
              title: const Text('Import Data'),
              subtitle: const Text('Restore data from a previously exported file'),
              trailing: _isImporting 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2)
                    )
                  : const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _isImporting ? null : _importData,
            ),
            
            const SizedBox(height: 16),
            
            // Warning note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.amber[100]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Importing data may overwrite your existing data. Always backup before importing.',
                      style: TextStyle(color: Colors.amber, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
