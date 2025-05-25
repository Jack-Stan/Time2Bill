import 'package:flutter/material.dart';

class NotificationSettingsCard extends StatefulWidget {
  final Map<String, dynamic> settings;
  final Function(Map<String, dynamic>) onSave;

  const NotificationSettingsCard({
    super.key,
    required this.settings,
    required this.onSave,
  });

  @override
  State<NotificationSettingsCard> createState() => _NotificationSettingsCardState();
}

class _NotificationSettingsCardState extends State<NotificationSettingsCard> {
  bool _emailNotifications = true;
  bool _invoiceReminders = true;
  bool _overdueInvoices = true;
  bool _weeklyReports = false;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _emailNotifications = widget.settings['emailNotifications'] ?? true;
    _invoiceReminders = widget.settings['invoiceReminders'] ?? true;
    _overdueInvoices = widget.settings['overdueInvoices'] ?? true;
    _weeklyReports = widget.settings['weeklyReports'] ?? false;
  }

  @override
  void didUpdateWidget(NotificationSettingsCard oldWidget) {
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
        'emailNotifications': _emailNotifications,
        'invoiceReminders': _invoiceReminders,
        'overdueInvoices': _overdueInvoices,
        'weeklyReports': _weeklyReports,
      };
      
      await widget.onSave(settings);
      
      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Notification Settings',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.notifications, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Control which notifications you receive',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            
            // Email Notifications Master Switch
            SwitchListTile(
              title: const Text(
                'Email Notifications',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Enable all email notifications'),
              value: _emailNotifications,
              onChanged: (bool value) {
                setState(() {
                  _emailNotifications = value;
                  if (!value) {
                    _invoiceReminders = false;
                    _overdueInvoices = false;
                    _weeklyReports = false;
                  }
                });
              },
            ),
            const Divider(),
            
            // Individual notification types
            SwitchListTile(
              title: const Text('Invoice Reminders'),
              subtitle: const Text('Receive reminders about upcoming invoice due dates'),
              value: _emailNotifications && _invoiceReminders,
              onChanged: _emailNotifications 
                  ? (bool value) {
                      setState(() {
                        _invoiceReminders = value;
                      });
                    }
                  : null,
            ),
            
            SwitchListTile(
              title: const Text('Overdue Invoices'),
              subtitle: const Text('Get notified when invoices become overdue'),
              value: _emailNotifications && _overdueInvoices,
              onChanged: _emailNotifications 
                  ? (bool value) {
                      setState(() {
                        _overdueInvoices = value;
                      });
                    }
                  : null,
            ),
            
            SwitchListTile(
              title: const Text('Weekly Reports'),
              subtitle: const Text('Receive a weekly summary of your activity'),
              value: _emailNotifications && _weeklyReports,
              onChanged: _emailNotifications 
                  ? (bool value) {
                      setState(() {
                        _weeklyReports = value;
                      });
                    }
                  : null,
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
