import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
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

class _TimeTrackingPageState extends State<TimeTrackingPage>
    with SingleTickerProviderStateMixin {
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
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs != null && routeArgs is Map<String, dynamic>) {
      if (routeArgs.containsKey('selectedProjectId')) {
        _selectedProjectId = routeArgs['selectedProjectId'] as String?;
        _selectedProjectFilter = _selectedProjectId;
        _safeSetState(() {
          _selectedProjectId = _selectedProjectFilter;
        });
      }
      if (routeArgs.containsKey('selectedClientId')) {
        _selectedClientId = routeArgs['selectedClientId'] as String?;
        _selectedClientFilter = _selectedClientId;
        _safeSetState(() {
          _selectedClientId = _selectedClientFilter;
        });
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
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // For the calendar view, we want to load data for the entire month
      final startOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
      final endOfMonth = DateTime(
        _selectedDate.year,
        _selectedDate.month + 1,
        0,
        23,
        59,
        59,
      );

      List<TimeEntryModel> timeEntries = await _firebaseService.getTimeEntries(
        startDate: startOfMonth,
        endDate: endOfMonth,
      );
      List<ProjectModel> projects = await _firebaseService.getProjects();
      _safeSetState(() {
        _timeEntries = timeEntries;
        _projects = projects;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading time tracking data: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Fout bij laden van tijdregistraties.';
      });
    }
  }

  Future<void> _loadClients() async {
    try {
      List<ClientModel> clients = await _firebaseService.getClients();
      _safeSetState(() {
        _clients = clients;
      });
    } catch (e) {
      print('Error loading clients: $e');
      _safeSetState(() {
        _errorMessage = 'Fout bij laden van klanten.';
      });
    }
  }

  Future<void> _calculateStats() async {
    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final startOfWeek = startOfToday.subtract(
        Duration(days: startOfToday.weekday - 1),
      );
      final startOfMonth = DateTime(now.year, now.month, 1);

      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final endOfWeek = startOfWeek.add(
        const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
      );
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final todayEntries = await _firebaseService.getTimeEntries(
        startDate: startOfToday,
        endDate: endOfDay,
      );

      final weekEntries = await _firebaseService.getTimeEntries(
        startDate: startOfWeek,
        endDate: endOfWeek,
      );

      final monthEntries = await _firebaseService.getTimeEntries(
        startDate: startOfMonth,
        endDate: endOfMonth,
      );

      Duration today = Duration(
        seconds: todayEntries.fold(0, (sum, e) => sum + e.duration.toInt()),
      );
      Duration week = Duration(
        seconds: weekEntries.fold(0, (sum, e) => sum + e.duration.toInt()),
      );
      Duration month = Duration(
        seconds: monthEntries.fold(0, (sum, e) => sum + e.duration.toInt()),
      );

      _safeSetState(() {
        _todayDuration = today;
        _weekDuration = week;
        _monthDuration = month;
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
    if (_descriptionController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Beschrijving is verplicht.';
      });
      return;
    }
    if (_startTime == null || _endTime == null) {
      setState(() {
        _errorMessage = 'Start- en eindtijd zijn verplicht.';
      });
      return;
    }
    if (_endTime!.isBefore(_startTime!)) {
      setState(() {
        _errorMessage = 'Eindtijd mag niet voor starttijd liggen.';
      });
      return;
    }
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final duration = _endTime!.difference(_startTime!).inSeconds.toDouble();
      final project = _projects.firstWhere(
        (p) => p.id == _selectedProjectId,
        orElse:
            () => ProjectModel(
              id: '',
              title: '',
              clientId: '',
              todoItems: [],
              hourlyRate: 0,
              startDate: DateTime.now(),
            ),
      );
      final client = _clients.firstWhere(
        (c) => c.id == _selectedClientId,
        orElse: () => ClientModel(id: '', name: ''),
      );
      final entry = TimeEntryModel(
        description: _descriptionController.text,
        startTime: _startTime!,
        endTime: _endTime!,
        duration: duration,
        projectId: _selectedProjectId,
        projectName: project.title,
        clientId: _selectedClientId,
        clientName: client.name,
        billable: _isBillable,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        taskId: _selectedTaskId,
        taskTitle:
            _tasksForSelectedProject.firstWhere(
              (t) => t['id'] == _selectedTaskId,
              orElse: () => {'title': null},
            )['title'],
      );
      await _firebaseService.addTimeEntry(entry);
      if (_selectedProjectId != null && _selectedTaskId != null) {
        await _updateProjectTask(_selectedProjectId!, _selectedTaskId!);
      }
      await _loadData();
      await _calculateStats();
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _errorMessage = 'Fout bij opslaan van tijdregistratie.';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // Method to update project task if needed (mark as in progress, etc.)
  Future<void> _updateProjectTask(String projectId, String taskId) async {
    try {
      await _firebaseService.markTaskInProgress(projectId, taskId);
      print('Time entry added for project $projectId, task $taskId');
    } catch (e) {
      print('Error updating project task: $e');
    }
  }

  Future<void> _deleteTimeEntry(String timeEntryId) async {
    try {
      await _firebaseService.deleteTimeEntry(timeEntryId);
      await _loadData();
      await _calculateStats();
    } catch (e) {
      setState(() {
        _errorMessage = 'Fout bij verwijderen van tijdregistratie.';
      });
    }
  }

  void _updateTasksForProject(String? projectId, StateSetter dialogSetState) {
    if (projectId == null) {
      dialogSetState(() {
        _tasksForSelectedProject = [];
        _selectedTaskId = null;
      });
      return;
    }
    final project = _projects.firstWhere(
      (p) => p.id == projectId,
      orElse:
          () => ProjectModel(
            id: '',
            title: '',
            clientId: '',
            todoItems: [],
            hourlyRate: 0,
            startDate: DateTime.now(),
          ),
    );
    final tasks =
        project.todoItems.where((t) => !(t['completed'] ?? false)).toList();
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Timer',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
          orElse:
              () => ProjectModel(
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
        color: Color.fromRGBO(
          Colors.red.r.toInt(),
          Colors.red.g.toInt(),
          Colors.red.b.toInt(),
          0.1,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            timerState.description.isEmpty
                ? 'Time is running...'
                : timerState.description,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                            orElse:
                                () => ProjectModel(
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
              child: DropdownButtonFormField<String?>(
                decoration: const InputDecoration(
                  labelText: 'Client',
                  border: OutlineInputBorder(),
                ),
                value: _selectedClientId,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('No Client'),
                  ),
                  ..._clients
                      .map(
                        (client) => DropdownMenuItem<String?>(
                          value: client.id,
                          child: Text(client.name),
                        ),
                      )
                      .toList(),
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
              child: DropdownButtonFormField<String?>(
                decoration: const InputDecoration(
                  labelText: 'Project',
                  border: OutlineInputBorder(),
                ),
                value: _selectedProjectId,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('No Project'),
                  ),
                  ..._projects
                      .where(
                        (project) =>
                            _selectedClientId == null ||
                            project.clientId == _selectedClientId,
                      )
                      .map(
                        (project) => DropdownMenuItem<String?>(
                          value: project.id,
                          child: Text(project.title),
                        ),
                      )
                      .toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedProjectId = value;

                    // If no client is selected, set the client based on the project
                    if (_selectedClientId == null && value != null) {
                      final project = _projects.firstWhere(
                        (p) => p.id == value,
                        orElse:
                            () => ProjectModel(
                              title: '',
                              clientId: '',
                              clientName: '',
                              hourlyRate: 0,
                              startDate: DateTime.now(),
                            ),
                      );

                      if (project.clientId != null &&
                          project.clientId!.isNotEmpty) {
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
                        const SnackBar(
                          content: Text('Please enter a description'),
                        ),
                      );
                      return;
                    }

                    String? projectName;
                    String? clientName;

                    if (_selectedProjectId != null) {
                      final project = _projects.firstWhere(
                        (p) => p.id == _selectedProjectId,
                        orElse:
                            () => ProjectModel(
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

                    print(
                      'Timer started for: ${_descriptionController.text} , ProjectID: ${_selectedProjectId}, ClientID: ${_selectedClientId}',
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Timer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  'Today',
                  _formatDuration(_todayDuration),
                  Colors.green,
                ),
                _buildStatItem(
                  'This Week',
                  _formatDuration(_weekDuration),
                  Colors.blue,
                ),
                _buildStatItem(
                  'This Month',
                  _formatDuration(_monthDuration),
                  Colors.purple,
                ),
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
            color: Color.fromRGBO(
              color.r.toInt(),
              color.g.toInt(),
              color.b.toInt(),
              0.1,
            ),
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
                              _selectedDate = _selectedDate.subtract(
                                const Duration(days: 1),
                              );
                            });
                            _loadData();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: () {
                            setState(() {
                              _selectedDate = _selectedDate.add(
                                const Duration(days: 1),
                              );
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
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 16,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            // Search implementation will filter the entries list
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String?>(
                      hint: const Text('Filter by Client'),
                      value: _selectedClientFilter,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Clients'),
                        ),
                        ..._clients
                            .map(
                              (client) => DropdownMenuItem<String?>(
                                value: client.id,
                                child: Text(client.name),
                              ),
                            )
                            .toList(),
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
                    DropdownButton<String?>(
                      hint: const Text('Filter by Project'),
                      value: _selectedProjectFilter,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Projects'),
                        ),
                        ..._projects
                            .where(
                              (project) =>
                                  _selectedClientFilter == null ||
                                  project.clientId == _selectedClientFilter,
                            )
                            .map(
                              (project) => DropdownMenuItem<String?>(
                                value: project.id,
                                child: Text(project.title),
                              ),
                            )
                            .toList(),
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
            tabs: const [Tab(text: 'List View'), Tab(text: 'Calendar View')],
          ),
          SizedBox(
            height: 500, // Fixed height instead of Expanded
            child: TabBarView(
              controller: _tabController,
              children: [_buildTimeEntriesList(), _buildTimeEntriesCalendar()],
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
      return const Center(child: Text('Geen tijdregistraties gevonden.'));
    }
    List<TimeEntryModel> filteredEntries = _timeEntries;
    if (_selectedClientFilter != null) {
      filteredEntries =
          filteredEntries
              .where((e) => e.clientId == _selectedClientFilter)
              .toList();
    }
    if (_selectedProjectFilter != null) {
      filteredEntries =
          filteredEntries
              .where((e) => e.projectId == _selectedProjectFilter)
              .toList();
    }
    final searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      filteredEntries =
          filteredEntries
              .where(
                (e) =>
                    e.description.toLowerCase().contains(searchQuery) ||
                    (e.projectName?.toLowerCase().contains(searchQuery) ??
                        false) ||
                    (e.clientName?.toLowerCase().contains(searchQuery) ??
                        false),
              )
              .toList();
    }
    if (filteredEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_off, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No time entries match your filters',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        itemCount: filteredEntries.length,
        itemBuilder: (context, index) {
          final entry = filteredEntries[index];
          final duration = Duration(seconds: entry.duration.toInt());
          final hours = duration.inHours;
          final minutes = duration.inMinutes % 60;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Color.fromRGBO(
                  (primaryColor.r * 255.0).round() & 0xff,
                  (primaryColor.g * 255.0).round() & 0xff,
                  (primaryColor.b * 255.0).round() & 0xff,
                  0.2
                ),
                child: Icon(Icons.access_time, color: primaryColor),
              ),
              title: Text(
                entry.description,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(DateFormat('MMM d, y').format(entry.startTime)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.business, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          entry.clientName ?? 'No client',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.folder, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          entry.projectName ?? 'No project',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$hours:${minutes.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (entry.billable)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Billable',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              onTap: () {
                // Option to edit the entry
              },
              onLongPress: () {
                _showDeleteConfirmation(entry);
              },
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(TimeEntryModel entry) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: Text(
              'Are you sure you want to delete "${entry.description}"?',
            ),
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
    // Group time entries by date for the calendar
    Map<DateTime, List<TimeEntryModel>> groupedEntries = {};

    for (var entry in _timeEntries) {
      // Apply the same filters as the list view
      if (_selectedClientFilter != null &&
          entry.clientId != _selectedClientFilter) {
        continue;
      }
      if (_selectedProjectFilter != null &&
          entry.projectId != _selectedProjectFilter) {
        continue;
      }
      final searchQuery = _searchController.text.toLowerCase();
      if (searchQuery.isNotEmpty &&
          !entry.description.toLowerCase().contains(searchQuery) &&
          !(entry.projectName?.toLowerCase().contains(searchQuery) ?? false) &&
          !(entry.clientName?.toLowerCase().contains(searchQuery) ?? false)) {
        continue;
      }

      // Convert to date only (no time)
      final entryDate = DateTime(
        entry.startTime.year,
        entry.startTime.month,
        entry.startTime.day,
      );

      if (groupedEntries[entryDate] == null) {
        groupedEntries[entryDate] = [];
      }
      groupedEntries[entryDate]!.add(entry);
    }

    // Get the total duration for each day
    Map<DateTime, Duration> dailyDurations = {};
    groupedEntries.forEach((date, entries) {
      final totalSeconds = entries.fold<double>(
        0,
        (sum, entry) => sum + entry.duration,
      );
      dailyDurations[date] = Duration(seconds: totalSeconds.toInt());
    });

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _selectedDate,
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            rowHeight: 45, // Reduce row height to save space
            daysOfWeekHeight: 20, // Reduce height of days of week header
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                color: primaryColor,
                fontSize: 16, // Smaller font size
                fontWeight: FontWeight.bold,
              ),
              headerPadding: const EdgeInsets.symmetric(
                vertical: 8.0,
              ), // Reduce padding
              leftChevronPadding: const EdgeInsets.all(4.0),
              rightChevronPadding: const EdgeInsets.all(4.0),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: true,
              markersMaxCount: 3,
              markerDecoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Color.fromRGBO(
                  (primaryColor.r * 255.0).round() & 0xff,
                  (primaryColor.g * 255.0).round() & 0xff,
                  (primaryColor.b * 255.0).round() & 0xff,
                  0.3,
                ),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              // Reduce cell margins
              cellMargin: const EdgeInsets.all(2),
              // Smaller text for day numbers
              defaultTextStyle: const TextStyle(fontSize: 12),
              weekendTextStyle: const TextStyle(fontSize: 12),
              outsideTextStyle: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
              selectedTextStyle: const TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
              todayTextStyle: const TextStyle(
                fontSize: 12,
                color: Colors.black,
              ),
            ),
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDate, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = selectedDay;
              });
              _loadData();
            },
            eventLoader: (day) {
              // Return events for this day
              return groupedEntries[DateTime(day.year, day.month, day.day)] ??
                  [];
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return null;

                final duration =
                    dailyDurations[DateTime(date.year, date.month, date.day)] ??
                    Duration.zero;
                final hours = duration.inHours;
                final minutes = duration.inMinutes % 60;

                // Show a badge with the total hours for the day
                return Positioned(
                  bottom: 1,
                  right: 1,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Center(
                      child: Text(
                        '$hours:${minutes.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Show entries for the selected day
          Expanded(
            child: _buildSelectedDayEntries(
              groupedEntries[_selectedDate] ?? [],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayEntries(List<TimeEntryModel> entries) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No time entries for ${DateFormat('MMMM d, y').format(_selectedDate)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
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
      );
    }

    // Sort entries by start time
    entries.sort((a, b) => a.startTime.compareTo(b.startTime));

    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final duration = Duration(seconds: entry.duration.toInt());
        final hours = duration.inHours;
        final minutes = duration.inMinutes % 60;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color.fromRGBO(
                (primaryColor.r * 255.0).round() & 0xff,
                (primaryColor.g * 255.0).round() & 0xff,
                (primaryColor.b * 255.0).round() & 0xff,
                0.2
              ),
              child: Icon(Icons.access_time, color: primaryColor),
            ),
            title: Text(
              entry.description,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.business, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(entry.clientName ?? 'No client'),
                    const SizedBox(width: 16),
                    Icon(Icons.folder, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(entry.projectName ?? 'No project'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${DateFormat('HH:mm').format(entry.startTime)} - ${entry.endTime != null ? DateFormat('HH:mm').format(entry.endTime!) : 'ongoing'}',
                    ),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$hours:${minutes.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (entry.billable)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Billable',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            onTap: () {
              // Option to edit the entry
            },
            onLongPress: () {
              _showDeleteConfirmation(entry);
            },
          ),
        );
      },
    );
  }

  void _showAddTimeEntryModal() {
    // Reset form state
    _descriptionController.clear();
    setState(() {
      _selectedProjectId = null;
      _selectedClientId = null;
      _selectedTaskId = null;
      _tasksForSelectedProject = [];
      _startTime = DateTime.now().subtract(const Duration(hours: 1));
      _endTime = DateTime.now();
      _isBillable = true;
      _errorMessage = null;
    });

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: const Text('Add Time Entry'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        hintText: 'What did you work on?',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            decoration: const InputDecoration(
                              labelText: 'Client',
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedClientId,
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('No Client'),
                              ),
                              ..._clients
                                  .map(
                                    (client) => DropdownMenuItem<String?>(
                                      value: client.id,
                                      child: Text(client.name),
                                    ),
                                  )
                                  .toList(),
                            ],
                            onChanged: (value) {
                              dialogSetState(() {
                                _selectedClientId = value;
                                // Reset project when client changes
                                _selectedProjectId = null;
                                _selectedTaskId = null;
                                _tasksForSelectedProject = [];
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String?>(
                      decoration: const InputDecoration(
                        labelText: 'Project',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedProjectId,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('No Project'),
                        ),
                        ..._projects
                            .where(
                              (project) =>
                                  _selectedClientId == null ||
                                  project.clientId == _selectedClientId,
                            )
                            .map(
                              (project) => DropdownMenuItem<String?>(
                                value: project.id,
                                child: Text(project.title),
                              ),
                            )
                            .toList(),
                      ],
                      onChanged: (value) {
                        dialogSetState(() {
                          _selectedProjectId = value;
                          // Update available tasks                          _updateTasksForProject(value, dialogSetState);
                        });
                      },
                    ),
                    if (_tasksForSelectedProject.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String?>(
                        decoration: const InputDecoration(
                          labelText: 'Task',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedTaskId,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('No Task'),
                          ),
                          ..._tasksForSelectedProject
                              .map(
                                (task) => DropdownMenuItem<String?>(
                                  value: task['id'],
                                  child: Text(task['title']),
                                ),
                              )
                              .toList(),
                        ],
                        onChanged: (value) {
                          dialogSetState(() {
                            _selectedTaskId = value;
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Start Time',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.access_time),
                            ),
                            controller: TextEditingController(
                              text:
                                  _startTime != null
                                      ? DateFormat('HH:mm').format(_startTime!)
                                      : '',
                            ),
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime:
                                    _startTime != null
                                        ? TimeOfDay.fromDateTime(_startTime!)
                                        : TimeOfDay.now(),
                              );
                              if (time != null) {
                                dialogSetState(() {
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
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'End Time',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.access_time),
                            ),
                            controller: TextEditingController(
                              text:
                                  _endTime != null
                                      ? DateFormat('HH:mm').format(_endTime!)
                                      : '',
                            ),
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime:
                                    _endTime != null
                                        ? TimeOfDay.fromDateTime(_endTime!)
                                        : TimeOfDay.now(),
                              );
                              if (time != null) {
                                dialogSetState(() {
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
                            dialogSetState(() {
                              _isBillable = value ?? true;
                            });
                          },
                        ),
                        const Text('Billable'),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                _isSaving
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                      onPressed: _addTimeEntry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save'),
                    ),
              ],
            );
          },
        );
      },
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
                  if (index == 2)
                    Navigator.pushReplacementNamed(context, '/invoices');
                  if (index == 3)
                    Navigator.pushReplacementNamed(context, '/clients');
                  if (index == 4)
                    Navigator.pushReplacementNamed(context, '/reports');
                  if (index == 5)
                    Navigator.pushReplacementNamed(context, '/settings');
                  if (index == 6)
                    Navigator.pushReplacementNamed(context, '/projects');
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
