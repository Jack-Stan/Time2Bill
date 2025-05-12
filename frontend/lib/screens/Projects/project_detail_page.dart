import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Dashboard/widgets/sidebar.dart';

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

  @override
  Widget build(BuildContext context) {
    // If projectData wasn't passed in constructor, try to get it from the route arguments
    final projectData = widget.projectData ?? 
      (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {});
    
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
                  Navigator.pushReplacementNamed(context, '/projects');
                  break;
              }
            },
          ),
          // Main Content
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: _buildMainContent(projectData),
            ),
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
          const SizedBox(height: 24),
          _buildProjectInfoCard(projectData),
          const SizedBox(height: 24),
          _buildTabBar(),
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
              onPressed: () => Navigator.of(context).pop(),
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
          onPressed: () {
            // Edit project
          },
          icon: const Icon(Icons.edit),
          label: const Text('Project bewerken'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectInfoCard(Map<String, dynamic> projectData) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Client:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    projectData['client'] ?? 'N/A',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    projectData['status'] ?? 'N/A',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Beschrijving:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    projectData['description'] ?? 'Geen beschrijving',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
    // Get project data from route
    final projectData = widget.projectData ?? 
      (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {});
      
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
            ),            ElevatedButton.icon(
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
                        value: task['completed'],                        onChanged: (bool? newValue) {
                          setState(() {
                            task['completed'] = newValue;
                            // Update in Firebase after changing completion status
                            _updateProject(projectData);
                          });
                        },
                        secondary: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [                            IconButton(
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
                  List<Map<String, dynamic>> todoItems = 
                    (projectData['todoItems'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
                  
                  todoItems.removeWhere((task) => task['id'] == taskId);
                  projectData['todoItems'] = todoItems;
                  
                  // Update in Firebase
                  _updateProject(projectData);
                });
                Navigator.of(context).pop();
              },
              child: const Text('Verwijderen', style: TextStyle(color: Colors.red)),
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
          Icon(
            Icons.check_box_outline_blank,
            size: 60,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Geen taken gevonden',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Klik op "Nieuwe taak" om een taak toe te voegen',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTrackingTab() {
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
              onPressed: () {
                // Add new time entry
              },
              icon: const Icon(Icons.timer),
              label: const Text('Start Timer'),
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
            ? Center(
                child: Text(
                  'Geen tijdsregistraties gevonden',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
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
                      leading: const Icon(Icons.access_time),
                      title: Text(entry['task']),
                      subtitle: Text('Datum: ${entry['date']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              entry['duration'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {},
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
                // Create new invoice
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
            ? Center(
                child: Text(
                  'Geen facturen gevonden',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
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
                      leading: const Icon(Icons.receipt_long),
                      title: Text(invoice['id']),
                      subtitle: Text('Datum: ${invoice['date']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            invoice['amount'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: invoice['status'] == 'Betaald' 
                                ? Colors.green.withOpacity(0.1) 
                                : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: invoice['status'] == 'Betaald' 
                                  ? Colors.green 
                                  : Colors.orange,
                              ),
                            ),
                            child: Text(
                              invoice['status'],
                              style: TextStyle(
                                color: invoice['status'] == 'Betaald' 
                                  ? Colors.green 
                                  : Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        // View invoice details
                      },
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }
}
