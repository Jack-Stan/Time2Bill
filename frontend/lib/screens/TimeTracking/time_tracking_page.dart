import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Dashboard/models/timer_state.dart';
import '../Dashboard/widgets/sidebar.dart';

class TimeTrackingPage extends StatefulWidget {
  const TimeTrackingPage({super.key});

  @override
  State<TimeTrackingPage> createState() => _TimeTrackingPageState();
}

class _TimeTrackingPageState extends State<TimeTrackingPage> {
  int _selectedIndex = 1; // Time Tracking selected
  final Color primaryColor = const Color(0xFF0B5394);
  
  // Gebruik dezelfde controllers als in de timer_widget
  final _projectController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final timerState = Provider.of<TimerState>(context); // Dit gebruikt de bestaande TimerState

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
                case 1: // Time Tracking - al op deze pagina
                  setState(() => _selectedIndex = index);
                  break;
                // ... andere navigatie-items ...
                default:
                  setState(() => _selectedIndex = index);
                  // Navigeer naar de juiste pagina
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
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'Time Tracking',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Timer Widget
                  // Hier gebruiken we dezelfde timerState als in het dashboard
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Active Timer',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          // Timer UI
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  timerState.formattedTime, // Dezelfde timer als in het dashboard
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
                                          timerState.startTimer(); // Dezelfde start functie
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
                                          timerState.pauseTimer(); // Dezelfde pause functie
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
                                      onPressed: timerState.seconds > 0
                                        ? () {
                                            // Hier kun je de volledige save functionaliteit implementeren
                                            final durationInSeconds = timerState.seconds;
                                            timerState.resetTimer(); // Dezelfde reset functie
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Time entry saved: $durationInSeconds seconds')),
                                            );
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
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Time Entries List - hier zou je een lijst met time entries kunnen tonen
                  // ...
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
