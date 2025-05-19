import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../Dashboard/widgets/sidebar.dart';
import '../Dashboard/models/timer_state.dart';
import '../../services/firebase_service.dart';
import '../../models/time_entry_model.dart';
import '../../models/project_model.dart';
import '../../models/client_model.dart';

class TimeTrackingPage extends StatefulWidget {
  const TimeTrackingPage({super.key});

  @override
  State<TimeTrackingPage> createState() => _TimeTrackingPageState();
}

class _TimeTrackingPageState extends State<TimeTrackingPage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 1; // TimeTracking tab index
  final Color primaryColor = const Color(0xFF0B5394);
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  List<TimeEntryModel> _timeEntries = [];
  List<ProjectModel> _projects = [];
  List<ClientModel> _clients = [];
  DateTime _selectedDate = DateTime.now();
  final FirebaseService _firebaseService = FirebaseService();
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedClientFilter;
  String? _selectedProjectFilter;

  // Controllers for new time entry form
  final _descriptionController = TextEditingController();
  String? _selectedProjectId;
  String? _selectedClientId;
  DateTime? _startTime;
  DateTime? _endTime;
  bool _isBillable = true;
  String? _selectedTaskId;
  List<Map<String, dynamic>> _tasksForSelectedProject = [];
  
  // Stats
  Duration _todayDuration = Duration.zero;
  Duration _weekDuration = Duration.zero;
  Duration _monthDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _loadClients();
    _calculateStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Handle route arguments if they exist
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs != null && routeArgs is Map<String, dynamic>) {
      // If project ID is passed, select it
      if (routeArgs.containsKey('selectedProjectId')) {
        final projectId = routeArgs['selectedProjectId'] as String?;
        if (projectId != null && _selectedProjectId != projectId) {
          _selectedProjectId = projectId;
          
          // Ensure projects are loaded before accessing them
          if (_projects.isNotEmpty) {
            // Find the project in the list
            final project = _projects.firstWhere(
              (p) => p.id == projectId,
              orElse: () => ProjectModel(
                title: '',
                clientId: '',
                clientName: '',
                hourlyRate: 0,
                startDate: DateTime.now(),
              ),
            );
            
            // Set client ID if available
            if (project.clientId != null && project.clientId!.isNotEmpty) {
              _selectedClientId = project.clientId;
            }
            
            // Update tasks for the selected project
            _tasksForSelectedProject = _getTasksForProject(projectId);
            
            // If a suggested task ID is passed, select it
            if (routeArgs.containsKey('suggestedTaskId')) {
              final taskId = routeArgs['suggestedTaskId'] as String?;
              if (taskId != null && _tasksForSelectedProject.any((t) => t['id'] == taskId)) {
                _selectedTaskId = taskId;
                
                // Optionally pre-fill the description with the task title
                final task = _tasksForSelectedProject.firstWhere(
                  (t) => t['id'] == taskId,
                  orElse: () => {'title': ''},
                );
                if (task['title'] != null && task['title'].toString().isNotEmpty) {
                  _descriptionController.text = task['title'];
                }
                
                // Auto-open the time entry modal
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    _showAddTimeEntryModal();
                  }
                });
              }
            }
          } else {
            // If projects aren't loaded yet, we'll handle this after loading
            // Store the IDs to use after loading is complete
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted && _projects.isNotEmpty) {
                didChangeDependencies();
              }
            });
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Controleer of de widget nog gemount is voordat setState wordt aangeroepen
  void _safeSetState(Function() fn) {
    if (mounted) {
      setState(fn);
    }
  }

  Future<void> _loadData() async {
    // Controleer of widget nog mounted is voordat setState wordt aangeroepen
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Loading time tracking data...');
      
      // Bepaal start- en einddatum voor de query
      final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);
      
      print('Fetching time entries for date range: $startOfDay to $endOfDay');
      
      // Laad tijdregistraties voor de geselecteerde dag
      List<TimeEntryModel> timeEntries;
      try {
        // Gebruik FirebaseService om tijdregistraties op te halen
        timeEntries = await _firebaseService.getTimeEntries(
          startDate: startOfDay,
          endDate: endOfDay,
        );
        print('Successfully loaded ${timeEntries.length} time entries via service');
      } catch (e) {
        print('Error loading time entries via service: $e');
        
        // Fallback naar directe Firestore-query
        if (!mounted) return; // Extra check toegevoegd
        
        print('Falling back to direct Firestore query for time entries');
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('User not authenticated');
        
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('timeTracking')
            .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
            .get();
            
        timeEntries = snapshot.docs.map((doc) => TimeEntryModel.fromFirestore(doc)).toList();
        print('Successfully loaded ${timeEntries.length} time entries via direct query');
      }
      
      // Laad projecten voor dropdown
      List<ProjectModel> projects;
      try {
        // Gebruik FirebaseService om projecten op te halen
        projects = await _firebaseService.getProjects();
        print('Successfully loaded ${projects.length} projects via service');
      } catch (e) {
        print('Error loading projects via service: $e');
        
        // Fallback naar directe Firestore-query
        if (!mounted) return; // Extra check toegevoegd
        
        print('Falling back to direct Firestore query for projects');
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('User not authenticated');
        
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('projects')
            .get();
            
        projects = snapshot.docs.map((doc) => ProjectModel.fromFirestore(doc)).toList();
        print('Successfully loaded ${projects.length} projects via direct query');
      }

      // Controleer of widget nog mounted is voordat setState wordt aangeroepen
      if (!mounted) return;
      
      setState(() {
        _timeEntries = timeEntries;
        _projects = projects;
        _isLoading = false;
      });
      
    } catch (e) {
      print('Error loading time tracking data: $e');
      
      // Controleer of widget nog mounted is voordat setState wordt aangeroepen
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Error loading data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadClients() async {
    try {
      final clients = await _firebaseService.getClients();
      _safeSetState(() {
        _clients = clients;
      });
    } catch (e) {
      print('Error loading clients: $e');
    }
  }

  Future<void> _calculateStats() async {
    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Bereken dagelijkse duur
      final todayEntries = await _firebaseService.getTimeEntries(
        startDate: startOfToday,
      );
      
      // Bereken wekelijkse duur
      final weekEntries = await _firebaseService.getTimeEntries(
        startDate: startOfWeek,
      );
      
      // Bereken maandelijkse duur
      final monthEntries = await _firebaseService.getTimeEntries(
        startDate: startOfMonth,
      );

      // Bereken totale duur voor elke periode
      int todaySeconds = 0;
      int weekSeconds = 0;
      int monthSeconds = 0;

      for (var entry in todayEntries) {
        todaySeconds += entry.duration.toInt();
      }

      for (var entry in weekEntries) {
        weekSeconds += entry.duration.toInt();
      }

      for (var entry in monthEntries) {
        monthSeconds += entry.duration.toInt();
      }

      _safeSetState(() {
        _todayDuration = Duration(seconds: todaySeconds);
        _weekDuration = Duration(seconds: weekSeconds);
        _monthDuration = Duration(seconds: monthSeconds);
      });
    } catch (e) {
      print('Error calculating stats: $e');
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '$hours:${minutes.toString().padLeft(2, '0')}';
  }

  Future<void> _addTimeEntry() async {
    // Validatie
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return;
    }

    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end times')),
      );
      return;
    }
    
    if (_endTime!.isBefore(_startTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time cannot be before start time')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Bereken duur in seconden
      final durationInSeconds = _endTime!.difference(_startTime!).inSeconds;
      
      // Zoek project details op als er een project is geselecteerd
      String? projectName;
      String? clientId = _selectedClientId;
      String? clientName;
      String? taskId = _selectedTaskId;
      String? taskTitle;
      
      if (_selectedProjectId != null) {
        final project = _projects.firstWhere(
          (p) => p.id == _selectedProjectId,
          orElse: () => ProjectModel(
            title: 'Unknown Project',
            clientId: '',
            clientName: '',
            hourlyRate: 0,
            startDate: DateTime.now(),
          ),
        );
        
        projectName = project.title;
        
        if (clientId == null) {
          clientId = project.clientId;
        }
        
        // Vind clientnaam op basis van clientId
        if (clientId != null && clientId.isNotEmpty) {
          final client = _clients.firstWhere(
            (c) => c.id == clientId,
            orElse: () => ClientModel(name: 'Unknown Client'),
          );
          clientName = client.name;
        }
        
        // Get task title if a task is selected
        if (taskId != null && taskId.isNotEmpty) {
          final tasks = _getTasksForProject(_selectedProjectId);
          final task = tasks.firstWhere(
            (t) => t['id'] == taskId,
            orElse: () => {'title': 'Unknown Task'},
          );
          taskTitle = task['title'] as String?;
          
          // If no description was entered, use the task title
          if (_descriptionController.text.isEmpty && taskTitle != null) {
            _descriptionController.text = taskTitle;
          }
        }
      }

      // Maak TimeEntry model
      final newTimeEntry = TimeEntryModel(
        description: _descriptionController.text,
        startTime: _startTime!,
        endTime: _endTime,
        duration: durationInSeconds.toDouble(),
        projectId: _selectedProjectId,
        projectName: projectName,
        clientId: clientId,
        clientName: clientName,
        billable: _isBillable,
        taskId: taskId,
        taskTitle: taskTitle,
      );

      print('Saving time entry: ${newTimeEntry.toMap()}');
      
      // Bewaar in Firebase via service
      try {
        final String entryId = await _firebaseService.addTimeEntry(newTimeEntry);
        print('Successfully saved time entry with ID: $entryId');
          // If this is linked to a task, refresh the project to update task status if needed
        if (taskId != null && _selectedProjectId != null) {
          _updateProjectTask(_selectedProjectId!, taskId);
        }
      } catch (e) {
        print('Error saving time entry: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving time entry: $e')),
        );
      }
      
      // Refresh time entries
      await _loadData();
      
    } catch (e) {
      print('Error in _addTimeEntry: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
        _descriptionController.clear();
        _selectedClientId = null;
        _selectedProjectId = null;
        _selectedTaskId = null;
        _startTime = null;
        _endTime = null;
        _isBillable = true;
        _tasksForSelectedProject = [];
      });
    }
  }
  
  // Method to update project task if needed (mark as in progress, etc.)
  Future<void> _updateProjectTask(String projectId, String taskId) async {
    try {
      // This is where you could update the task status to "in progress" or similar
      // For now, we'll just log it
      print('Time entry added for project $projectId, task $taskId');
    } catch (e) {
      print('Error updating project task: $e');
    }
  }

  Future<void> _deleteTimeEntry(String timeEntryId) async {
    try {
      // Gebruik FirebaseService voor verwijderen
      await _firebaseService.deleteTimeEntry(timeEntryId);
      
      // Vernieuw lijst
      _loadData();
      _calculateStats();
      
      // Toon succes melding
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Time entry deleted successfully')),
      );
    } catch (e) {
      print('Error deleting time entry: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting time entry: ${e.toString()}')),
      );
    }
  }

  void _showAddTimeEntryModal() {
    // Reset form state
    _descriptionController.clear();
    setState(() {
      _selectedProjectId = null;
      _selectedClientId = null;
      _startTime = null;
      _endTime = null;
      _isBillable = true;
    });
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Time Entry',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Client selection
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Client',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedClientId,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('No Client'),
                        ),
                        ..._clients.map((client) => DropdownMenuItem(
                          value: client.id,
                          child: Text(client.name),
                        )).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedClientId = value;
                          // Reset project when client changes
                          _selectedProjectId = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Project dropdown - filtered by client if selected
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Project',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedProjectId,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('No Project'),
                        ),
                        ..._projects
                          .where((project) => _selectedClientId == null || 
                            project.clientId == _selectedClientId)
                          .map((project) => DropdownMenuItem(
                            value: project.id,
                            child: Text(project.title),
                          )).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedProjectId = value;
                          
                          // If no client is selected, set the client based on the project
                          if (_selectedClientId == null && value != null) {
                            final project = _projects.firstWhere(
                              (p) => p.id == value,
                              orElse: () => ProjectModel(
                                title: '',
                                clientId: '',
                                clientName: '',
                                hourlyRate: 0,
                                startDate: DateTime.now(),
                              ),
                            );
                            
                            if (project.clientId != null && project.clientId!.isNotEmpty) {
                              _selectedClientId = project.clientId;
                            }
                          }
                          _tasksForSelectedProject = _getTasksForProject(value);
                          _selectedTaskId = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Task dropdown - filtered by selected project
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Task',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedTaskId,
                      items: [                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('No Task'),
                        ),
                        ..._tasksForSelectedProject.map((task) => DropdownMenuItem<String>(
                          value: task['id'],
                          child: Text(task['title']),
                        )).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedTaskId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (time != null) {
                                setState(() {
                                  _startTime = DateTime(
                                    _selectedDate.year,
                                    _selectedDate.month,
                                    _selectedDate.day,
                                    time.hour,
                                    time.minute,
                                  );
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start Time',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _startTime != null
                                    ? DateFormat('HH:mm').format(_startTime!)
                                    : 'Select time',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (time != null) {
                                setState(() {
                                  _endTime = DateTime(
                                    _selectedDate.year,
                                    _selectedDate.month,
                                    _selectedDate.day,
                                    time.hour,
                                    time.minute,
                                  );
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'End Time',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _endTime != null
                                    ? DateFormat('HH:mm').format(_endTime!)
                                    : 'Select time',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Billable'),
                      value: _isBillable,
                      onChanged: (value) {
                        setState(() {
                          _isBillable = value ?? true;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _isSaving
                              ? null
                              : () {
                                  _addTimeEntry().then((_) {
                                    Navigator.of(context).pop();
                                  });
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  // Get tasks for the selected project
  List<Map<String, dynamic>> _getTasksForProject(String? projectId) {
    if (projectId == null) return [];
    
    // Find the project with the matching ID
    final project = _projects.firstWhere(
      (p) => p.id == projectId, 
      orElse: () => ProjectModel(title: '', hourlyRate: 0, startDate: DateTime.now())
    );
    
    // Return todo items, filtering out completed ones
    return project.todoItems
        .where((task) => task['completed'] == false)
        .toList();
  }

  // Get tasks for the selected project
  void _updateTasksForProject(String? projectId, StateSetter dialogSetState) {
    if (projectId == null) {
      dialogSetState(() {
        _tasksForSelectedProject = [];
        _selectedTaskId = null;
      });
      return;
    }
    
    // Find the project with the matching ID
    final project = _projects.firstWhere(
      (p) => p.id == projectId, 
      orElse: () => ProjectModel(title: '', hourlyRate: 0, startDate: DateTime.now())
    );
    
    // Get todo items, filtering out completed ones
    final tasks = project.todoItems
        .where((task) => task['completed'] == false)
        .toList();
        
    dialogSetState(() {
      _tasksForSelectedProject = tasks;
      _selectedTaskId = tasks.isNotEmpty ? tasks.first['id'] : null;
    });
  }

  Widget _buildTimerSection() {
    return Consumer<TimerState>(
      builder: (context, timerState, child) {
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Timer',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                timerState.isRunning
                    ? _buildRunningTimer(timerState)
                    : _buildStoppedTimer(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRunningTimer(TimerState timerState) {
    final duration = Duration(seconds: timerState.secondsElapsed);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final formattedTime = 
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    // Find the project and client details
    String projectInfo = timerState.projectName ?? 'No Project';
    String clientInfo = timerState.clientName ?? 'No Client';
    
    // Alleen project- en clientgegevens ophalen als ze nog niet zijn ingesteld
    if (timerState.projectId != null && 
        (timerState.projectName == null || timerState.clientName == null)) {
      try {
        final project = _projects.firstWhere(
          (p) => p.id == timerState.projectId,
          orElse: () => ProjectModel(
            title: 'Unknown Project',
            clientId: '',
            clientName: '',
            hourlyRate: 0,
            startDate: DateTime.now(),
          ),
        );
        
        projectInfo = project.title;
        
        // Client ophalen als clientId beschikbaar is
        if (project.clientId != null && project.clientId!.isNotEmpty) {
          final client = _clients.firstWhere(
            (c) => c.id == project.clientId,
            orElse: () => ClientModel(name: 'Unknown Client'),
          );
          
          clientInfo = client.name;
        }
      } catch (e) {
        print('Error finding project/client details: $e');
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            timerState.description.isEmpty ? 'Time is running...' : timerState.description,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Chip(
                backgroundColor: Colors.blue.shade100,
                label: Text('Project: $projectInfo'),
                avatar: const Icon(Icons.folder, size: 16),
              ),
              const SizedBox(width: 8),
              Chip(
                backgroundColor: Colors.amber.shade100,
                label: Text('Client: $clientInfo'),
                avatar: const Icon(Icons.business, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedTime,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      timerState.stopTimer();
                      _descriptionController.text = timerState.description;
                      setState(() {
                        _selectedProjectId = timerState.projectId;
                        _startTime = timerState.startTime;
                        _endTime = DateTime.now();
                        _isBillable = timerState.isBillable;
                        
                        // Get client ID from project if available
                        if (timerState.projectId != null) {
                          final project = _projects.firstWhere(
                            (p) => p.id == timerState.projectId,
                            orElse: () => ProjectModel(
                              title: '',
                              clientId: '',
                              clientName: '',
                              hourlyRate: 0,
                              startDate: DateTime.now(),
                            ),
                          );
                          _selectedClientId = project.clientId;
                        }
                      });
                      _showAddTimeEntryModal();
                    },
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop & Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      timerState.resetTimer();
                    },
                    icon: const Icon(Icons.delete),
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStoppedTimer() {
    return Column(
      children: [
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'What are you working on?',
            border: OutlineInputBorder(),
            hintText: 'Enter task description...',
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Client',
                  border: OutlineInputBorder(),
                ),
                value: _selectedClientId,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('No Client'),
                  ),
                  ..._clients.map((client) => DropdownMenuItem(
                    value: client.id,
                    child: Text(client.name),
                  )).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedClientId = value;
                    // Reset project when client changes
                    _selectedProjectId = null;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Project',
                  border: OutlineInputBorder(),
                ),
                value: _selectedProjectId,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('No Project'),
                  ),
                  ..._projects
                    .where((project) => _selectedClientId == null || 
                      project.clientId == _selectedClientId)
                    .map((project) => DropdownMenuItem(
                      value: project.id,
                      child: Text(project.title),
                    )).toList(),
                ],                      onChanged: (value) {
                        setState(() {
                          _selectedProjectId = value;
                          
                          // If no client is selected, set the client based on the project
                          if (_selectedClientId == null && value != null) {
                            final project = _projects.firstWhere(
                              (p) => p.id == value,
                              orElse: () => ProjectModel(
                                title: '',
                                clientId: '',
                                clientName: '',
                                hourlyRate: 0,
                                startDate: DateTime.now(),
                              ),
                            );
                            
                            if (project.clientId != null && project.clientId!.isNotEmpty) {
                              _selectedClientId = project.clientId;
                            }
                          }
                        });
                        
                        // Update available tasks when project changes
                        _updateTasksForProject(value, setState);
                      },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: _isBillable,
              onChanged: (value) {
                setState(() {
                  _isBillable = value ?? true;
                });
              },
            ),
            const Text('Billable'),
            const Spacer(),
            Consumer<TimerState>(
              builder: (context, timerState, child) {
                return ElevatedButton.icon(
                  onPressed: () {
                    if (_descriptionController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a description')),
                      );
                      return;
                    }

                    String? projectName;
                    String? clientName;
                    
                    if (_selectedProjectId != null) {
                      final project = _projects.firstWhere(
                        (p) => p.id == _selectedProjectId,
                        orElse: () => ProjectModel(
                          title: 'Unknown Project',
                          clientId: '',
                          clientName: '',
                          hourlyRate: 0,
                          startDate: DateTime.now(),
                        ),
                      );
                      projectName = project.title;
                    }
                    
                    if (_selectedClientId != null) {
                      final client = _clients.firstWhere(
                        (c) => c.id == _selectedClientId,
                        orElse: () => ClientModel(name: 'Unknown Client'),
                      );
                      clientName = client.name;
                    }

                    timerState.startTimer(
                      description: _descriptionController.text,
                      projectId: _selectedProjectId,
                      projectName: projectName,
                      clientId: _selectedClientId,
                      clientName: clientName,
                      isBillable: _isBillable,
                    );
                    
                    print('Timer started for: ${_descriptionController.text} , ProjectID: ${_selectedProjectId}, ClientID: ${_selectedClientId}');
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Timer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _showAddTimeEntryModal,
              icon: const Icon(Icons.add),
              label: const Text('Add Manually'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Time Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Today', _formatDuration(_todayDuration), Colors.green),
                _buildStatItem('This Week', _formatDuration(_weekDuration), Colors.blue),
                _buildStatItem('This Month', _formatDuration(_monthDuration), Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildTimeEntriesSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Time Entries',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (date != null && date != _selectedDate) {
                              setState(() {
                                _selectedDate = date;
                              });
                              _loadData();
                            }
                          },
                        ),
                        Text(
                          DateFormat('MMM d, y').format(_selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {
                            setState(() {
                              _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                            });
                            _loadData();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: () {
                            setState(() {
                              _selectedDate = _selectedDate.add(const Duration(days: 1));
                            });
                            _loadData();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search entries...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        ),
                        onChanged: (value) {
                          setState(() {
                            // Search implementation will filter the entries list
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      hint: const Text('Filter by Client'),
                      value: _selectedClientFilter,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Clients'),
                        ),
                        ..._clients.map((client) => DropdownMenuItem<String>(
                          value: client.id,
                          child: Text(client.name),
                        )).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedClientFilter = value;
                          // Reset project filter if client changes
                          _selectedProjectFilter = null;
                        });
                      },
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      hint: const Text('Filter by Project'),
                      value: _selectedProjectFilter,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Projects'),
                        ),
                        ..._projects
                          .where((project) => _selectedClientFilter == null || 
                            project.clientId == _selectedClientFilter)
                          .map((project) => DropdownMenuItem<String>(
                            value: project.id,
                            child: Text(project.title),
                          )).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedProjectFilter = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[300]),
          TabBar(
            controller: _tabController,
            labelColor: primaryColor,
            tabs: const [
              Tab(text: 'List View'),
              Tab(text: 'Calendar View'),
            ],
          ),
          Container(
            height: 400, // Fixed height for the tab content
            padding: const EdgeInsets.all(16),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTimeEntriesList(),
                _buildTimeEntriesCalendar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeEntriesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    } else if (_timeEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No time entries for ${DateFormat('MMM d, y').format(_selectedDate)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Apply filters
    List<TimeEntryModel> filteredEntries = _timeEntries;

    // Apply client filter
    if (_selectedClientFilter != null) {
      filteredEntries = filteredEntries
        .where((entry) => entry.clientId == _selectedClientFilter)
        .toList();
    }

    // Apply project filter
    if (_selectedProjectFilter != null) {
      filteredEntries = filteredEntries
        .where((entry) => entry.projectId == _selectedProjectFilter)
        .toList();
    }

    // Apply search filter
    final searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      filteredEntries = filteredEntries
        .where((entry) => 
          entry.description.toLowerCase().contains(searchQuery) ||
          (entry.projectName?.toLowerCase().contains(searchQuery) ?? false) ||
          (entry.clientName?.toLowerCase().contains(searchQuery) ?? false)
        )
        .toList();
    }

    if (filteredEntries.isEmpty) {
      return Center(
        child: Text(
          'No entries match your filters',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredEntries.length,
      itemBuilder: (context, index) {
        final entry = filteredEntries[index];
        final duration = Duration(seconds: entry.duration.toInt());
        final hours = duration.inHours;
        final minutes = duration.inMinutes.remainder(60);
        final durationStr = '$hours:${minutes.toString().padLeft(2, '0')}';
        
        return Card(
          elevation: 0.5,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(entry.description),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (entry.clientName != null && entry.clientName!.isNotEmpty)
                      Chip(
                        backgroundColor: Colors.amber.shade100,
                        labelStyle: const TextStyle(fontSize: 12),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        label: Text(entry.clientName!),
                      ),
                    const SizedBox(width: 8),
                    if (entry.projectName != null && entry.projectName!.isNotEmpty)
                      Chip(
                        backgroundColor: Colors.blue.shade100,
                        labelStyle: const TextStyle(fontSize: 12),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        label: Text(entry.projectName!),
                      ),
                    if (entry.billable)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.attach_money, size: 16, color: Colors.green),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('HH:mm').format(entry.startTime)} - ' + 
                  (entry.endTime != null 
                    ? DateFormat('HH:mm').format(entry.endTime!) 
                    : 'now'),
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  durationStr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  color: Colors.red,
                  onPressed: () => _showDeleteConfirmation(entry),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(TimeEntryModel entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${entry.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteTimeEntry(entry.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeEntriesCalendar() {
    // Simple placeholder for calendar view - would be replaced with actual calendar widget
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_view_month, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Calendar view coming soon',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
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
                case 0:
                  Navigator.pushReplacementNamed(context, '/dashboard');
                  break;
                case 1:
                  setState(() => _selectedIndex = index);
                  break;
                default:
                  setState(() => _selectedIndex = index);
                  if (index == 2) Navigator.pushReplacementNamed(context, '/invoices');
                  if (index == 3) Navigator.pushReplacementNamed(context, '/clients');
                  if (index == 4) Navigator.pushReplacementNamed(context, '/reports');
                  if (index == 5) Navigator.pushReplacementNamed(context, '/settings');
                  if (index == 6) Navigator.pushReplacementNamed(context, '/projects');
              }
            },
          ),
          // Main Content
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Page header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Time Tracking',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _showAddTimeEntryModal,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Time Entry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Stats section
                    _buildStatsCard(),
                    const SizedBox(height: 24),
                    
                    // Timer section
                    _buildTimerSection(),
                    const SizedBox(height: 24),
                    
                    // Time entries section
                    _buildTimeEntriesSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
