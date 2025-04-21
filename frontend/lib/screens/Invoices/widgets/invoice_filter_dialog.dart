import 'package:flutter/material.dart';

class InvoiceFilterDialog extends StatefulWidget {
  final String currentSortBy;
  final bool currentSortAscending;
  final String currentStatusFilter;
  final Function(String sortBy, bool sortAscending, String statusFilter) onApplyFilters;

  const InvoiceFilterDialog({
    super.key,
    required this.currentSortBy,
    required this.currentSortAscending,
    required this.currentStatusFilter,
    required this.onApplyFilters,
  });

  @override
  State<InvoiceFilterDialog> createState() => _InvoiceFilterDialogState();
}

class _InvoiceFilterDialogState extends State<InvoiceFilterDialog> {
  late String _sortBy;
  late bool _sortAscending;
  late String _statusFilter;

  @override
  void initState() {
    super.initState();
    _sortBy = widget.currentSortBy;
    _sortAscending = widget.currentSortAscending;
    _statusFilter = widget.currentStatusFilter;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Invoices'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort By',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildSortOptions(),
            
            const SizedBox(height: 16),
            const Text(
              'Sort Direction',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildSortDirectionToggle(),
            
            const SizedBox(height: 16),
            const Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildStatusFilter(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApplyFilters(_sortBy, _sortAscending, _statusFilter);
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildSortOptions() {
    return Wrap(
      spacing: 8,
      children: [
        _buildSortChip('date', 'Date'),
        _buildSortChip('number', 'Invoice #'),
        _buildSortChip('amount', 'Amount'),
        _buildSortChip('client', 'Client'),
      ],
    );
  }

  Widget _buildSortChip(String value, String label) {
    return FilterChip(
      label: Text(label),
      selected: _sortBy == value,
      onSelected: (selected) {
        setState(() {
          _sortBy = value;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: const Color(0xFF0B5394).withOpacity(0.2),
    );
  }

  Widget _buildSortDirectionToggle() {
    return ToggleButtons(
      isSelected: [_sortAscending, !_sortAscending],
      onPressed: (index) {
        setState(() {
          _sortAscending = index == 0;
        });
      },
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(Icons.arrow_upward, size: 18),
              SizedBox(width: 4),
              Text('Ascending'),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(Icons.arrow_downward, size: 18),
              SizedBox(width: 4),
              Text('Descending'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    return Wrap(
      spacing: 8,
      children: [
        _buildStatusChip('all', 'All'),
        _buildStatusChip('draft', 'Draft'),
        _buildStatusChip('sent', 'Sent'),
        _buildStatusChip('paid', 'Paid'),
        _buildStatusChip('overdue', 'Overdue'),
      ],
    );
  }

  Widget _buildStatusChip(String value, String label) {
    return FilterChip(
      label: Text(label),
      selected: _statusFilter == value,
      onSelected: (selected) {
        setState(() {
          _statusFilter = value;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: const Color(0xFF0B5394).withOpacity(0.2),
    );
  }
}
