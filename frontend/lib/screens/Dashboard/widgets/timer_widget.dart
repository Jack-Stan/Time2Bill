import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/timer_state.dart';
import '../../../services/dashboard_refresh_service.dart';

class WorkTimerWidget extends StatefulWidget {
  const WorkTimerWidget({super.key});

  @override
  State<WorkTimerWidget> createState() => _WorkTimerWidgetState();
}

class _WorkTimerWidgetState extends State<WorkTimerWidget> {
  final _projectController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<String> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _projectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      // Just load existing projects without auto-generating
      final projectsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('projects');
      
      final snapshot = await projectsRef.get();
      final projectNames = snapshot.docs
          .map((doc) => doc.data()['title'] as String)
          .toList();
      
      setState(() {
        _projects = projectNames;
        if (_projects.isNotEmpty) {
          _projectController.text = _projects.first;
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading projects: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<void> _saveTimeEntry(int durationInSeconds) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      final now = DateTime.now();
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('timeTracking')
          .add({
            'projectId': _projectController.text,
            'projectName': _projectController.text,
            'description': _descriptionController.text,
            'duration': durationInSeconds,
            'startTime': Timestamp.fromDate(now),
            'createdAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
          });      // Clear description after saving
      _descriptionController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Time entry saved successfully')),
      );
      
      // Stuur een notificatie om de DashboardPage te vernieuwen
      Provider.of<TimerState>(context, listen: false).resetTimer();
      
      // Informeer het dashboard dat het moet vernieuwen
      DashboardRefreshService().refreshDashboard();
    } catch (e) {
      print('Error saving time entry: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving time entry: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerState = Provider.of<TimerState>(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Work Timer',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_projects.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_off, size: 40, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No projects available for time tracking',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/projects');
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create a Project'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Project Dropdown
                  DropdownButtonFormField<String>(
                    value: _projects.isEmpty ? null : (_projects.contains(_projectController.text) ? _projectController.text : _projects.first),
                    decoration: const InputDecoration(
                      labelText: 'Project',
                      border: OutlineInputBorder(),
                    ),
                    items: _projects.map((project) {
                      return DropdownMenuItem<String>(
                        value: project,
                        child: Text(project),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _projectController.text = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Description Field
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      hintText: 'What are you working on?',
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Timer Display
                  Center(
                    child: Column(
                      children: [
                        Text(
                          _formatTime(timerState.secondsElapsed),
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!timerState.isRunning)
                              ElevatedButton.icon(
                                onPressed: () {
                                  timerState.startTimer(
                                    description: _descriptionController.text,
                                    projectId: _projectController.text.isNotEmpty ? _projectController.text : null
                                  );
                                },
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Start'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              )
                            else
                              ElevatedButton.icon(
                                onPressed: () {
                                  timerState.stopTimer(); // Using stopTimer instead of pauseTimer
                                },
                                icon: const Icon(Icons.pause),
                                label: const Text('Pause'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: timerState.secondsElapsed > 0
                                ? () {
                                    final durationInSeconds = timerState.secondsElapsed;
                                    timerState.resetTimer();
                                    _saveTimeEntry(durationInSeconds);
                                  }
                                : null,
                              icon: const Icon(Icons.check),
                              label: const Text('Save'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  // Helper method to format seconds into HH:MM:SS
  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
