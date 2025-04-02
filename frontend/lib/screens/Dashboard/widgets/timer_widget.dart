import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/timer_state.dart';
import 'dart:async';

class WorkTimerWidget extends StatefulWidget {
  const WorkTimerWidget({super.key});

  @override
  State<WorkTimerWidget> createState() => _WorkTimerWidgetState();
}

class _WorkTimerWidgetState extends State<WorkTimerWidget> {
  Timer? _timer;
  final List<String> _projects = ['Project A', 'Project B', 'Project C'];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), _updateTimer);
  }

  void _updateTimer(Timer timer) {
    final timerState = Provider.of<TimerState>(context, listen: false);
    if (timerState.isRunning) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerState>(
      builder: (context, timerState, child) {
        final duration = timerState.elapsed;
        final hours = duration.inHours;
        final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
        final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                const SizedBox(height: 16),
                Text(
                  '$hours:$minutes:$seconds',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B5394),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: timerState.selectedProject,
                  decoration: const InputDecoration(
                    labelText: 'Select Project',
                    border: OutlineInputBorder(),
                  ),
                  items: _projects.map((project) {
                    return DropdownMenuItem(
                      value: project,
                      child: Text(project),
                    );
                  }).toList(),
                  onChanged: (value) => timerState.selectProject(value!),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: timerState.selectedProject == null
                        ? null
                        : () {
                            if (timerState.isRunning) {
                              timerState.stopTimer();
                            } else {
                              timerState.startTimer();
                            }
                          },
                    icon: Icon(
                      timerState.isRunning ? Icons.stop : Icons.play_arrow,
                    ),
                    label: Text(
                      timerState.isRunning ? 'Stop Timer' : 'Start Timer',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B5394),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
