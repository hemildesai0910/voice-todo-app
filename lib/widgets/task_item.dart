import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class TaskItem extends StatefulWidget {
  final Task task;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const TaskItem({
    super.key,
    required this.task,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  State<TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return FadeTransition(
      opacity: _animation,
      child: SizeTransition(
        sizeFactor: _animation,
        child: Dismissible(
          key: Key(widget.task.id),
          onDismissed: (_) => widget.onDelete(),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: widget.task.isCompleted,
                  onChanged: (_) => widget.onToggle(),
                  shape: const CircleBorder(),
                ),
              ),
              title: Text(
                widget.task.title,
                style: TextStyle(
                  decoration: widget.task.isCompleted ? TextDecoration.lineThrough : null,
                  color: widget.task.isCompleted ? theme.disabledColor : null,
                ),
              ),
              subtitle: _buildSubtitle(),
              trailing: _buildPriorityIcon(),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildSubtitle() {
    if (widget.task.dueDate == null && !widget.task.isOverdue) {
      return null;
    }

    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, y');
    
    return Text(
      widget.task.dueDate != null
          ? 'Due: ${dateFormat.format(widget.task.dueDate!)}'
          : '',
      style: TextStyle(
        color: widget.task.isOverdue ? theme.colorScheme.error : null,
        fontWeight: widget.task.isOverdue ? FontWeight.bold : null,
      ),
    );
  }

  Widget? _buildPriorityIcon() {
    if (!widget.task.isHighPriority) return null;

    return const Icon(
      Icons.priority_high,
      color: Colors.orange,
    );
  }
} 