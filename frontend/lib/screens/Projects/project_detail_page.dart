import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../Dashboard/widgets/sidebar.dart';
import 'widgets/edit_project_form.dart';
import '../../models/project_model.dart';
import '../../models/time_entry_model.dart';
import '../../models/invoice_model.dart';
import '../../services/firebase_service.dart';

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
  final FirebaseService _firebaseService = FirebaseService();
  List<TimeEntryModel> _timeEntries = [];
  List<InvoiceModel> _invoices = [];
  bool _loadingTimeEntries = false;
  bool _loadingInvoices = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      // Haal projectdata op uit route-arguments
      final projectData = widget.projectData ?? (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {});
      _projectData = projectData;
      _loadProjectRelatedData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectRelatedData() async {
    final projectData = _getProjectData();
    final String? projectId = projectData['id'] as String?;
    if (projectId == null || projectId.isEmpty) return;
    setState(() {
      _loadingTimeEntries = true;
      _loadingInvoices = true;
    });
    try {
      final timeEntries = await _firebaseService.getTimeEntries(projectId: projectId);
      final invoices = await _firebaseService.getInvoicesForProject(projectId);
      setState(() {
        _timeEntries = timeEntries;
        _invoices = invoices;
        _loadingTimeEntries = false;
        _loadingInvoices = false;
      });
    } catch (e) {
      setState(() {
        _loadingTimeEntries = false;
        _loadingInvoices = false;
      });
    }
  }

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
        if (!mounted) return;
        Navigator.pop(context);
        return;
      }

      final project = ProjectModel.fromFirestore(doc);

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
          DashboardSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              switch (index) {
                case 0:
                  Navigator.pushReplacementNamed(context, '/dashboard');
                  break;
                case 1:
                  Navigator.pushReplacementNamed(context, '/time-tracking');
                  break;
                case 2:
                  Navigator.pushReplacementNamed(context, '/invoices');
                  break;
                case 3:
                  Navigator.pushReplacementNamed(context, '/clients');
                  break;
                case 4:
                  Navigator.pushReplacementNamed(context, '/reports');
                  break;
                case 5:
                  Navigator.pushReplacementNamed(context, '/settings');
                  break;
                case 6:
                  Navigator.pushReplacementNamed(context, '/projects');
                  break;
              }
            },
          ),
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
                            ? '${formatter.format(startDate)} t/m ${formatter.format(endDate)}'
                            : 'Vanaf ${formatter.format(startDate)}'
                        : 'Niet ingesteld',
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
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

  Widget _buildTasksTab() {
    final projectData = _getProjectData();
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
                    List<Map<String, dynamic>> todoItems =
                        (projectData['todoItems'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

                    todoItems.add({
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'title': taskController.text,
                      'completed': false,
                    });

                    projectData['todoItems'] = todoItems;

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

  void _deleteTask(Map<String, dynamic> projectData, String taskId) {
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
                      (projectData['todoItems'] as List<dynamic>).cast<Map<String, dynamic>>();

                  todoItems.removeWhere((task) => task['id'] == taskId);

                  projectData['todoItems'] = todoItems;

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
    final projectData = _getProjectData();
    final List<Map<String, dynamic>> tasks =
        (projectData['todoItems'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final incompleteTasks = tasks.where((task) => task['completed'] == false).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Tijdsregistraties', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            ElevatedButton.icon(
              onPressed: () => _addTimeEntry(projectData, incompleteTasks),
              icon: const Icon(Icons.add),
              label: const Text('Nieuwe tijdsregistratie'),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _loadingTimeEntries
              ? const Center(child: CircularProgressIndicator())
              : _timeEntries.isEmpty
                  ? _buildEmptyTimeEntriesState()
                  : ListView.builder(
                      itemCount: _timeEntries.length,
                      itemBuilder: (context, index) {
                        final entry = _timeEntries[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            title: Text(entry.description),
                            subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(entry.startTime)),
                            trailing: Text(_formatDuration(entry.duration), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  String _formatDuration(double seconds) {
    final int h = seconds ~/ 3600;
    final int m = ((seconds % 3600) ~/ 60);
    return '${h}h ${m}m';
  }

  void _addTimeEntry(Map<String, dynamic> projectData, List<Map<String, dynamic>> incompleteTasks) {
    if (incompleteTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geen openstaande taken voor tijdsregistratie')),
      );
      return;
    }

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
            Text('Facturen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/invoices');
              },
              icon: const Icon(Icons.add),
              label: const Text('Nieuwe factuur'),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _loadingInvoices
              ? const Center(child: CircularProgressIndicator())
              : _invoices.isEmpty
                  ? _buildEmptyInvoicesState()
                  : ListView.builder(
                      itemCount: _invoices.length,
                      itemBuilder: (context, index) {
                        final invoice = _invoices[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            title: Text(invoice.invoiceNumber),
                            subtitle: Text(DateFormat('dd/MM/yyyy').format(invoice.invoiceDate)),
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('€${invoice.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  invoice.status,
                                  style: TextStyle(
                                    color: invoice.status.toLowerCase() == 'paid' || invoice.status.toLowerCase() == 'betaald' ? Colors.green : Colors.orange,
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
