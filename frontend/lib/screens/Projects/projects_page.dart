import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Dashboard/widgets/sidebar.dart';
import 'widgets/project_card.dart';
import 'widgets/new_project_form.dart';
import 'widgets/edit_project_form.dart'; // Import the edit form
import '../../services/firebase_service.dart';
import '../../models/project_model.dart'; // Import ProjectModel

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  int _selectedIndex = 6; // Set this to the Projects index in sidebar
  final Color primaryColor = const Color(0xFF0B5394);
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _projects = [];
  final FirebaseService _firebaseService = FirebaseService();

  // Filter state
  String _statusFilter = 'Alle';
  final List<String> _statusOptions = ['Alle', 'Actief', 'Niet-actief'];

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  Future<void> _fetchProjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final projects = await _firebaseService.getProjects();
      
      // Convert ProjectModel objects to the map format used by the UI
      final projectsData = projects.map((project) {
        return {
          'id': project.id ?? '',
          'title': project.title,
          'client': project.clientName ?? 'No Client',
          'description': project.description ?? 'No description',
          'status': project.status,
          'hourlyRate': project.hourlyRate,
          'startDate': project.startDate,
          'endDate': project.endDate,
          'clientId': project.clientId ?? '',
          'todoItems': project.todoItems,
          'projectModel': project, // Store the entire model for easy editing
        };
      }).toList();

      setState(() {
        _projects = projectsData;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Error loading projects: ${error.toString()}';
        _isLoading = false;
      });
      print('Error fetching projects: $error');
    }
  }

  void _openNewProjectForm() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return NewProjectForm(
          onProjectAdded: _fetchProjects, // Refresh list after adding
        );
      },
    );
  }

  void _openEditProjectForm(Map<String, dynamic> project) {
    // Get the ProjectModel from the map
    final ProjectModel projectModel = project['projectModel'];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditProjectForm(
          project: projectModel,
          onProjectUpdated: _fetchProjects, // Refresh list after updating
        );
      },
    );
  }

  void _navigateToProjectDetail(Map<String, dynamic> project) {
    // Navigate to project detail page and pass the project data
    Navigator.pushNamed(
      context, 
      '/project-detail',
      arguments: project,
    ).then((_) {
      // Refresh project list when returning from detail page
      _fetchProjects();
    });
  }

  Future<void> _deleteProject(String projectId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('projects')
          .doc(projectId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project verwijderd')),
      );

      // Refresh the project list
      _fetchProjects();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${error.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          DashboardSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              switch (index) {
                case 0: // Dashboard
                  Navigator.pushReplacementNamed(context, '/dashboard');
                  break;
                case 1: // Time Tracking
                  Navigator.pushReplacementNamed(context, '/time-tracking');
                  break;
                case 2: // Invoices
                  Navigator.pushReplacementNamed(context, '/invoices');
                  break;
                case 3: // Clients
                  Navigator.pushReplacementNamed(context, '/clients');
                  break;
                case 4: // Reports
                  Navigator.pushReplacementNamed(context, '/reports');
                  break;
                case 5: // Settings
                  Navigator.pushReplacementNamed(context, '/settings');
                  break;
                case 6: // Projects
                  // Already on Projects
                  break;
              }
            },
          ),
          // Main Content
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: _buildMainContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchProjects,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          Expanded(
            child: _projects.isEmpty 
              ? _buildEmptyState() 
              : _buildProjectList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Mijn Projecten',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            DropdownButton<String>(
              value: _statusFilter,
              items: _statusOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _statusFilter = newValue ?? 'Alle';
                });
              },
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _openNewProjectForm,
              icon: const Icon(Icons.add),
              label: const Text('Nieuw Project'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProjectList() {
    // Filter projecten op basis van de gekozen status
    List<Map<String, dynamic>> filteredProjects = _projects;
    if (_statusFilter == 'Actief') {
      filteredProjects = _projects.where((p) => (p['status']?.toLowerCase() ?? '') != 'niet-actief').toList();
    } else if (_statusFilter == 'Niet-actief') {
      filteredProjects = _projects.where((p) => (p['status']?.toLowerCase() ?? '') == 'niet-actief').toList();
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: filteredProjects.length,
      itemBuilder: (context, index) {
        final project = filteredProjects[index];
        return ProjectCard(
          id: project['id'],
          title: project['title'],
          client: project['client'],
          description: project['description'],
          status: project['status'],
          todoItems: project['todoItems'] as List<Map<String, dynamic>>?, // Pass todoItems to card
          onDelete: () => _deleteProject(project['id']),
          onEdit: () => _openEditProjectForm(project),
          onView: () => _navigateToProjectDetail(project),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Geen projecten gevonden',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Klik op "Nieuw Project" om een project aan te maken',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openNewProjectForm,
            icon: const Icon(Icons.add),
            label: const Text('Nieuw Project'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
