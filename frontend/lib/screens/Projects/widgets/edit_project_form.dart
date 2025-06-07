import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../models/project_model.dart';

class EditProjectForm extends StatefulWidget {
  final ProjectModel project;
  final Function? onProjectUpdated;
  
  const EditProjectForm({
    super.key,
    required this.project,
    this.onProjectUpdated,
  });

  @override
  State<EditProjectForm> createState() => _EditProjectFormState();
}

class _EditProjectFormState extends State<EditProjectForm> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedClient;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _hourlyRateController = TextEditingController();
  
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;  String _status = 'Actief';
  
  List<Map<String, dynamic>> _clients = [];
  bool _isLoading = false;
  String? _errorMessage;

  final statusOptions = [
    'Actief',
    'Inactief',
    'Voltooid',
    'In afwachting',
  ];
  @override
  void initState() {
    super.initState();
    // Initialize form with project data
    _titleController.text = widget.project.title;
    _descriptionController.text = widget.project.description ?? '';
    _hourlyRateController.text = widget.project.hourlyRate.toString();
    _selectedClient = widget.project.clientId;
    _startDate = widget.project.startDate;
    _endDate = widget.project.endDate;
    
    // Convert status to match our capitalized options if needed
    if (widget.project.status == 'actief') {
      _status = 'Actief';
    } else if (widget.project.status == 'inactief') {
      _status = 'Inactief';
    } else if (widget.project.status == 'voltooid') {
      _status = 'Voltooid';
    } else if (widget.project.status == 'in afwachting') {
      _status = 'In afwachting';
    } else {
      _status = widget.project.status;
    }
    
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
    _hourlyRateController.dispose();
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

        // Find client name if client is selected
        String? clientName;
        if (_selectedClient != null) {
          final client = _clients.firstWhere(
            (client) => client['id'] == _selectedClient,
            orElse: () => {'name': null},
          );
          clientName = client['name'];
        }

        // Update project data
        final updatedProject = ProjectModel(
          id: widget.project.id,
          title: _titleController.text,
          clientId: _selectedClient,
          clientName: clientName,
          hourlyRate: double.tryParse(_hourlyRateController.text) ?? 0.0,
          startDate: _startDate,
          endDate: _endDate,
          description: _descriptionController.text,
          status: _status,
          createdAt: widget.project.createdAt,
          updatedAt: DateTime.now(),
          todoItems: widget.project.todoItems,
        );

        // Update project in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('projects')
            .doc(widget.project.id)
            .update(updatedProject.toMap());

        if (!mounted) return;

        // Close the dialog
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project bijgewerkt')),
        );

        // Call callback to refresh project list
        widget.onProjectUpdated?.call();
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
                'Project bewerken',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildClientDropdown(),
              const SizedBox(height: 16),
              _buildTitleField(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildHourlyRateField(),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatusDropdown(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStartDateField(),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildEndDateField(),
                  ),
                ],
              ),
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
    if (_isLoading && _clients.isEmpty) {
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

  Widget _buildHourlyRateField() {
    return TextFormField(
      controller: _hourlyRateController,
      decoration: const InputDecoration(
        labelText: 'Uurtarief (€)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        prefixIcon: Icon(Icons.euro),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Voer een uurtarief in';
        }
        if (double.tryParse(value) == null) {
          return 'Voer een geldig bedrag in';
        }
        return null;
      },
    );
  }
  Widget _buildStatusDropdown() {
    // Ensure the current status value is one of the available options
    if (!statusOptions.contains(_status)) {
      _status = statusOptions[0]; // Default to first option if not found
    }
    
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        prefixIcon: Icon(Icons.flag),
      ),
      value: _status,
      items: statusOptions.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _status = newValue!;
        });
      },
    );
  }

  Widget _buildStartDateField() {
    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: _startDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (pickedDate != null) {
          setState(() {
            _startDate = pickedDate;
            // If end date is before start date, adjust it
            if (_endDate != null && _endDate!.isBefore(_startDate)) {
              _endDate = null;
            }
          });
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Startdatum',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          DateFormat('dd/MM/yyyy').format(_startDate),
        ),
      ),
    );
  }

  Widget _buildEndDateField() {
    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
          firstDate: _startDate,
          lastDate: DateTime(2100),
        );
        if (pickedDate != null) {
          setState(() {
            _endDate = pickedDate;
          });
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Einddatum (optioneel)',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          _endDate != null
              ? DateFormat('dd/MM/yyyy').format(_endDate!)
              : 'Niet ingesteld',
        ),
      ),
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
              : const Text('Opslaan'),
        ),
      ],
    );
  }
}
