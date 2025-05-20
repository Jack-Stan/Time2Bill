import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../Dashboard/widgets/sidebar.dart';
import 'widgets/edit_project_form.dart';
import '../../models/project_model.dart';

class ProjectDetailPage extends StatefulWidget {
  final Map<String, dynamic>? projectData;
  
  const ProjectDetailPage({super.key, this.projectData});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 6; // Projects index in sidebar
  late TabController _tabController;
  final Color primaryColor = const Color(0xFF0B5394);
  Map<String, dynamic> _projectData = {};
  bool _isLoading = false;
  
  // Mock time entries
  final List<Map<String, dynamic>> _timeEntries = [
    {
      'id': '1',
      'task': 'Design homepage mockup',
      'date': '12/04/2023',
      'duration': '3h 30m',
    },
    {
      'id': '2',
      'task': 'Create responsive layout',
      'date': '13/04/2023',
      'duration': '5h 15m',
    },
  ];
  
  // Mock invoices data
  final List<Map<String, dynamic>> _invoices = [
    {
      'id': 'INV-001',
      'date': '30/04/2023',
      'amount': '€1,250.00',
      'status': 'Betaald',
    },
    {
      'id': 'INV-002',
      'date': '15/05/2023',
      'amount': '€950.00',
      'status': 'Wacht op betaling',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // Get the current project data, either from widget or route arguments
  Map<String, dynamic> _getProjectData() {
    if (_projectData.isNotEmpty) {
      return _projectData;
    }
    
    final projectData = widget.projectData ?? 
      (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {});
      
    _projectData = projectData;
    return projectData;
  }

  void _editProject() {
    final projectData = _getProjectData();
    
    // Get the ProjectModel from the map
    final ProjectModel? projectModel = projectData['projectModel'];
    
    if (projectModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kan project niet bewerken: ProjectModel ontbreekt')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditProjectForm(
          project: projectModel,
          onProjectUpdated: () {
            // Reload project data from Firestore
            _refreshProjectData(projectModel.id!);
          },
        );
      },
    );
  }
  
  Future<void> _refreshProjectData(String projectId) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('projects')
          .doc(projectId)
          .get();
      
      if (!doc.exists) {
        // Project was deleted, navigate back
        if (!mounted) return;
        Navigator.pop(context);
        return;
      }
      
      // Convert to ProjectModel
      final project = ProjectModel.fromFirestore(doc);
      
      // Update project data map
      _projectData = {
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
        'projectModel': project,
      };
      
      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      print('Error refreshing project data: $error');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fout bij ophalen projectgegevens: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectData = _getProjectData();
    
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          DashboardSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              // Handle navigation
            },
          ),
          
          // Main content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMainContent(projectData),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(Map<String, dynamic> projectData) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(projectData),
          const SizedBox(height: 16),
          _buildProjectInfoCard(projectData),
          const SizedBox(height: 24),
          _buildTabBar(),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTasksTab(),
                _buildTimeTrackingTab(),
                _buildInvoicesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> projectData) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Terug',
            ),
            const SizedBox(width: 8),
            Text(
              projectData['title'] ?? 'Project Details',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _editProject,
          icon: const Icon(Icons.edit),
          label: const Text('Project bewerken'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildProjectInfoCard(Map<String, dynamic> projectData) {
    final startDate = projectData['startDate'] as DateTime?;
    final endDate = projectData['endDate'] as DateTime?;
    final formatter = DateFormat('dd/MM/yyyy');
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Client info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Client',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    projectData['client'] ?? 'Geen client',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(primaryColor.r.toInt(), primaryColor.g.toInt(), primaryColor.b.toInt(), 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(projectData['status']),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      projectData['status'] ?? 'Onbekend',
                      style: TextStyle(
                        color: _getStatusColor(projectData['status']),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Date range
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Periode',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    startDate != null
                        ? endDate != null
                            ? '${formatter.format(startDate)} - ${formatter.format(endDate)}'
                            : 'Vanaf ${formatter.format(startDate)}'
                        : 'Niet ingesteld',
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            // Hourly rate
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Uurtarief',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '€${(projectData['hourlyRate'] ?? 0).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
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

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'actief':
        return Colors.green;
      case 'inactief':
        return Colors.grey;
      case 'voltooid':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  Widget _buildTabBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: primaryColor,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[700],
        tabs: const [
          Tab(text: "To-do's"),
          Tab(text: "Time Tracking"),
          Tab(text: "Facturen"),
        ],
      ),
    );
  }

  // Tab contents
  Widget _buildTasksTab() {
    // Get project data from current state
    final projectData = _getProjectData();
      
    // Get tasks from project data, or use empty list if not available
    final List<Map<String, dynamic>> tasks = 
      (projectData['todoItems'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Taken (${tasks.length})',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // Add new task
                _addNewTask(projectData);
              },
              icon: const Icon(Icons.add),
              label: const Text('Nieuwe taak'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: tasks.isEmpty
              ? _buildEmptyTasksState()
              : ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CheckboxListTile(
                        title: Text(
                          task['title'],
                          style: TextStyle(
                            decoration: task['completed'] ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        value: task['completed'],
                        onChanged: (bool? newValue) {
                          setState(() {
                            task['completed'] = newValue;
                            // Update in Firebase after changing completion status
                            _updateProject(projectData);
                          });
                        },
                        secondary: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _editTask(projectData, task),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () => _deleteTask(projectData, task['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
  
  // Update the project in Firebase
  Future<void> _updateProject(Map<String, dynamic> projectData) async {
    try {
      final projectId = projectData['id'] as String;
      
      if (projectId.isEmpty) {
        print('Cannot update project: No project ID');
        return;
      }
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('Cannot update project: User not authenticated');
        return;
      }
      
      // Update todoItems field in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('projects')
          .doc(projectId)
          .update({
            'todoItems': projectData['todoItems'],
          });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project bijgewerkt')),
      );
    } catch (error) {
      print('Error updating project: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fout bij bijwerken project: $error')),
      );
    }
  }
  
  // Add a new task to the project
  void _addNewTask(Map<String, dynamic> projectData) {
    final TextEditingController taskController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Nieuwe taak toevoegen'),
          content: TextField(
            controller: taskController,
            decoration: const InputDecoration(
              labelText: 'Taakomschrijving',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuleren'),
            ),
            TextButton(
              onPressed: () {
                if (taskController.text.isNotEmpty) {
                  setState(() {
                    // Get the current todoItems or create an empty list if null
                    List<Map<String, dynamic>> todoItems = 
                      (projectData['todoItems'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
                    
                    // Add the new task
                    todoItems.add({
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'title': taskController.text,
                      'completed': false,
                    });
                    
                    // Update the project data
                    projectData['todoItems'] = todoItems;
                    
                    // Update in Firebase
                    _updateProject(projectData);
                  });
                  
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Toevoegen'),
            ),
          ],
        );
      },
    );
  }
  
  // Handle task deletion
  void _deleteTask(Map<String, dynamic> projectData, String taskId) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Taak verwijderen'),
          content: const Text('Weet u zeker dat u deze taak wilt verwijderen?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuleren'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  // Get the current todoItems
                  List<Map<String, dynamic>> todoItems = 
                    (projectData['todoItems'] as List<dynamic>).cast<Map<String, dynamic>>();
                  
                  // Remove the task with matching ID
                  todoItems.removeWhere((task) => task['id'] == taskId);
                  
                  // Update the project data
                  projectData['todoItems'] = todoItems;
                  
                  // Update in Firebase
                  _updateProject(projectData);
                });
                
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Verwijderen'),
            ),
          ],
        );
      },
    );
  }
  
  // Edit an existing task
  void _editTask(Map<String, dynamic> projectData, Map<String, dynamic> task) {
    final TextEditingController taskController = TextEditingController(text: task['title']);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Taak bewerken'),
          content: TextField(
            controller: taskController,
            decoration: const InputDecoration(
              labelText: 'Taakomschrijving',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuleren'),
            ),
            TextButton(
              onPressed: () {
                if (taskController.text.isNotEmpty) {
                  setState(() {
                    // Update the task title
                    task['title'] = taskController.text;
                    
                    // Update in Firebase
                    _updateProject(projectData);
                  });
                  
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Opslaan'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyTasksState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_box_outline_blank, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nog geen taken',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            'Maak taken om uw project te organiseren',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _addNewTask(_getProjectData()),
            icon: const Icon(Icons.add),
            label: const Text('Nieuwe taak'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTrackingTab() {
    // Get project data
    final projectData = _getProjectData();
    final List<Map<String, dynamic>> tasks = 
      (projectData['todoItems'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    
    // Filter incomplete tasks for dropdown
    final incompleteTasks = tasks.where((task) => task['completed'] == false).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tijdsregistraties',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _addTimeEntry(projectData, incompleteTasks),
              icon: const Icon(Icons.add),
              label: const Text('Nieuwe tijdsregistratie'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _timeEntries.isEmpty
              ? _buildEmptyTimeEntriesState()
              : ListView.builder(
                  itemCount: _timeEntries.length,
                  itemBuilder: (context, index) {
                    final entry = _timeEntries[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(entry['task'] ?? ''),
                        subtitle: Text(entry['date'] ?? ''),
                        trailing: Text(
                          entry['duration'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
  
  // Add a time entry
  void _addTimeEntry(Map<String, dynamic> projectData, List<Map<String, dynamic>> incompleteTasks) {
    // This is a placeholder. In a real implementation, this would be integrated with your
    // time tracking system and add an actual time entry.
    if (incompleteTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geen openstaande taken voor tijdsregistratie')),
      );
      return;
    }
    
    // Navigate to time tracking page with selectedProject and selectedTask preset
    Navigator.pushNamed(
      context,
      '/time-tracking',
      arguments: {
        'selectedProjectId': projectData['id'],
        'suggestedTaskId': incompleteTasks.first['id'],
      },
    );
  }

  Widget _buildEmptyTimeEntriesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nog geen tijdsregistraties',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            'Registreer tijd om de voortgang bij te houden',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              final projectData = _getProjectData();
              final List<Map<String, dynamic>> tasks = 
                (projectData['todoItems'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
              final incompleteTasks = tasks.where((task) => task['completed'] == false).toList();
              _addTimeEntry(projectData, incompleteTasks);
            },
            icon: const Icon(Icons.add),
            label: const Text('Nieuwe tijdsregistratie'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Facturen',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // Handle create invoice (redirect to invoices page)
                Navigator.pushNamed(context, '/invoices');
              },
              icon: const Icon(Icons.add),
              label: const Text('Nieuwe factuur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _invoices.isEmpty
              ? _buildEmptyInvoicesState()
              : ListView.builder(
                  itemCount: _invoices.length,
                  itemBuilder: (context, index) {
                    final invoice = _invoices[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(invoice['id'] ?? ''),
                        subtitle: Text(invoice['date'] ?? ''),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              invoice['amount'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              invoice['status'] ?? '',
                              style: TextStyle(
                                color: invoice['status'] == 'Betaald'
                                    ? Colors.green
                                    : Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildEmptyInvoicesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nog geen facturen',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            'Maak een factuur om betaling te ontvangen',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to invoices page with this project pre-selected
              Navigator.pushNamed(
                context, 
                '/invoices',
                arguments: {
                  'createInvoice': true,
                  'projectId': _getProjectData()['id'],
                },
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Nieuwe factuur'),
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
