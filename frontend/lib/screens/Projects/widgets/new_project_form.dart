import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewProjectForm extends StatefulWidget {
  final Function? onProjectAdded;
  
  const NewProjectForm({super.key, this.onProjectAdded});

  @override
  State<NewProjectForm> createState() => _NewProjectFormState();
}

class _NewProjectFormState extends State<NewProjectForm> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedClient;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  List<Map<String, dynamic>> _clients = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchClients();
  }

  Future<void> _fetchClients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('clients')
          .orderBy('name')
          .get();

      final clients = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc.data()['name'] ?? 'Unnamed Client',
        };
      }).toList();

      setState(() {
        _clients = clients;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('User not authenticated');
        }

        // Create new project document
        final projectRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('projects')
            .doc();

        await projectRef.set({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'clientId': _selectedClient,
          'status': 'Active',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Also add project reference to the client's projects subcollection
        if (_selectedClient != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('clients')
              .doc(_selectedClient)
              .collection('projects')
              .doc(projectRef.id)
              .set({
                'projectId': projectRef.id,
                'createdAt': FieldValue.serverTimestamp(),
              });
        }

        if (!mounted) return;

        // Close the dialog
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project aangemaakt')),
        );

        // Call callback to refresh project list
        widget.onProjectAdded?.call();
      } catch (error) {
        setState(() {
          _errorMessage = 'Error: ${error.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nieuw Project',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildClientDropdown(),
              const SizedBox(height: 16),
              _buildNewClientLink(),
              const SizedBox(height: 16),
              _buildTitleField(),
              const SizedBox(height: 16),
              _buildDescriptionField(),
              const SizedBox(height: 16),
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),
              const SizedBox(height: 24),
              _buildButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientDropdown() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Client',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        prefixIcon: Icon(Icons.business),
      ),
      value: _selectedClient,
      hint: const Text('Selecteer een client'),
      items: _clients.map<DropdownMenuItem<String>>((client) {
        return DropdownMenuItem<String>(
          value: client['id'],
          child: Text(client['name']),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedClient = newValue;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Selecteer een client';
        }
        return null;
      },
    );
  }

  Widget _buildNewClientLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Nieuwe client aanmaken'),
        onPressed: () {
          Navigator.of(context).pop();
          Navigator.pushNamed(context, '/clients');
        },
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF0B5394),
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Projecttitel',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        prefixIcon: Icon(Icons.title),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Voer een projecttitel in';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Beschrijving (optioneel)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        prefixIcon: Icon(Icons.description),
      ),
      minLines: 3,
      maxLines: 5,
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isLoading ? null : () {
            Navigator.pop(context);
          },
          child: const Text('Annuleren'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0B5394),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Project aanmaken'),
        ),
      ],
    );
  }
}
