import 'package:flutter/material.dart';

class ProjectCard extends StatelessWidget {
  final String id;
  final String title;
  final String client;
  final String description;
  final String status;
  final List<Map<String, dynamic>>? todoItems; // Add todoItems parameter
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onView;

  const ProjectCard({
    super.key,
    required this.id,
    required this.title,
    required this.client,
    required this.description,
    required this.status,
    this.todoItems,
    required this.onDelete,
    required this.onEdit,
    required this.onView,
  });

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
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

  // Calculate how many todos are not completed
  int _getIncompleteTodoCount() {
    if (todoItems == null) return 0;
    return todoItems!.where((todo) => todo['completed'] == false).length;
  }

  @override
  Widget build(BuildContext context) {
    final incompleteTodos = _getIncompleteTodoCount();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.business, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      client,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                // Only show todo badge if there are incomplete todos
                if (incompleteTodos > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.orange,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_box_outlined,
                          size: 12,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$incompleteTodos todo${incompleteTodos == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, size: 20),
                  onPressed: onView,
                  tooltip: 'Bekijken',
                  color: const Color(0xFF0B5394),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: onEdit,
                  tooltip: 'Bewerken',
                  color: Colors.orange,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () {
                    // Show confirmation dialog
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Project verwijderen'),
                          content: Text('Weet u zeker dat u "$title" wilt verwijderen?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Annuleren'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                onDelete();
                              },
                              child: const Text(
                                'Verwijderen',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  tooltip: 'Verwijderen',
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
