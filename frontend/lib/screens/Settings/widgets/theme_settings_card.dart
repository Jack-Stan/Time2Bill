import 'package:flutter/material.dart';

class ThemeSettingsCard extends StatefulWidget {
  final Map<String, dynamic> settings;
  final Function(Map<String, dynamic>) onSave;

  const ThemeSettingsCard({
    super.key,
    required this.settings,
    required this.onSave,
  });

  @override
  State<ThemeSettingsCard> createState() => _ThemeSettingsCardState();
}

class _ThemeSettingsCardState extends State<ThemeSettingsCard> {
  bool _darkMode = false;
  bool _compactMode = false;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _darkMode = widget.settings['darkMode'] ?? false;
    _compactMode = widget.settings['compactMode'] ?? false;
  }

  @override
  void didUpdateWidget(ThemeSettingsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _initializeFields();
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final settings = {
        'darkMode': _darkMode,
        'compactMode': _compactMode,
      };
      
      await widget.onSave(settings);
      
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Theme Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.palette, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Customize the appearance of the application',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            
            // Dark Mode Switch
            SwitchListTile(
              title: const Text(
                'Dark Mode',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Enable dark theme'),
              value: _darkMode,
              onChanged: (bool value) {
                setState(() {
                  _darkMode = value;
                });
              },
              secondary: Icon(
                _darkMode ? Icons.dark_mode : Icons.light_mode,
                color: _darkMode ? Colors.amber : Colors.blueGrey,
              ),
            ),
            
            const Divider(),
            
            // Compact Mode Switch
            SwitchListTile(
              title: const Text(
                'Compact Mode',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Reduce spacing for denser UI'),
              value: _compactMode,
              onChanged: (bool value) {
                setState(() {
                  _compactMode = value;
                });
              },
              secondary: Icon(
                _compactMode ? Icons.compress : Icons.expand,
                color: Colors.blueGrey,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Note that theme changes require app restart
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Some theme changes may require restarting the app to take full effect.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        onPressed: _saveSettings,
                        icon: const Icon(Icons.save),
                        label: const Text('Save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B5394),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
