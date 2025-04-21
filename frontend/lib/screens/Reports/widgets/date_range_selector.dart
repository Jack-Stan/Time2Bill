import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateRangeSelector extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final Function(DateTime, DateTime) onDateRangeChanged;

  const DateRangeSelector({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onDateRangeChanged,
  });

  @override
  State<DateRangeSelector> createState() => _DateRangeSelectorState();
}

class _DateRangeSelectorState extends State<DateRangeSelector> {
  late DateTime _startDate;
  late DateTime _endDate;
  String _selectedPreset = 'Last 30 Days';

  final List<String> _presets = [
    'Last 7 Days',
    'Last 30 Days',
    'This Month',
    'Last Month',
    'This Quarter',
    'This Year',
    'Last Year',
    'Custom Range',
  ];

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  void _applyPreset(String preset) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    switch (preset) {
      case 'Last 7 Days':
        start = now.subtract(const Duration(days: 7));
        end = now;
        break;
      case 'Last 30 Days':
        start = now.subtract(const Duration(days: 30));
        end = now;
        break;
      case 'This Month':
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0);
        break;
      case 'Last Month':
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0);
        break;
      case 'This Quarter':
        final quarter = (now.month - 1) ~/ 3;
        start = DateTime(now.year, quarter * 3 + 1, 1);
        end = DateTime(now.year, (quarter + 1) * 3 + 1, 0);
        break;
      case 'This Year':
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31);
        break;
      case 'Last Year':
        start = DateTime(now.year - 1, 1, 1);
        end = DateTime(now.year - 1, 12, 31);
        break;
      case 'Custom Range':
        // Don't change dates for custom range - we'll show a date picker
        return;
      default:
        start = now.subtract(const Duration(days: 30));
        end = now;
    }

    setState(() {
      _startDate = start;
      _endDate = end;
      _selectedPreset = preset;
    });

    widget.onDateRangeChanged(start, end);
  }

  Future<void> _showCustomRangePicker() async {
    final initialDateRange = DateTimeRange(
      start: _startDate,
      end: _endDate,
    );
    
    final pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF0B5394),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      setState(() {
        _startDate = pickedRange.start;
        _endDate = pickedRange.end;
        _selectedPreset = 'Custom Range';
      });
      widget.onDateRangeChanged(pickedRange.start, pickedRange.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date Range',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Date range display
                Expanded(
                  child: InkWell(
                    onTap: _showCustomRangePicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Icon(Icons.calendar_today, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Presets dropdown
                DropdownButton<String>(
                  value: _selectedPreset,
                  onChanged: (String? value) {
                    if (value != null) {
                      if (value == 'Custom Range') {
                        _showCustomRangePicker();
                      } else {
                        _applyPreset(value);
                      }
                    }
                  },
                  items: _presets.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
