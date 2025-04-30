import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/voice_service.dart';
import '../services/command_parser.dart';

// Service Providers
final taskServiceProvider = Provider<TaskService>((ref) {
  return TaskService();
});

final voiceServiceProvider = Provider<VoiceService>((ref) {
  return VoiceService();
});

final commandParserProvider = Provider<CommandParser>((ref) {
  return CommandParser();
});

// State Providers
final tasksProvider = StateNotifierProvider<TasksNotifier, List<Task>>((ref) {
  final taskService = ref.watch(taskServiceProvider);
  return TasksNotifier(taskService);
});

final isListeningProvider = StateProvider<bool>((ref) => false);

// Task State Notifier
class TasksNotifier extends StateNotifier<List<Task>> {
  final TaskService _taskService;

  TasksNotifier(this._taskService) : super([]) {
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    state = _taskService.getAllTasks();
  }

  Future<void> addTask(Task task) async {
    await _taskService.addTask(task);
    await _loadTasks();
  }

  Future<void> updateTask(Task task) async {
    await _taskService.updateTask(task);
    await _loadTasks();
  }

  Future<void> deleteTask(String taskId) async {
    await _taskService.deleteTask(taskId);
    await _loadTasks();
  }

  Future<void> toggleTaskComplete(String taskId) async {
    final taskIndex = state.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      final task = state[taskIndex];
      task.toggleComplete();
      await _taskService.updateTask(task);
      await _loadTasks();
    }
  }

  Future<void> syncWithCloud() async {
    await _taskService.syncWithCloud();
    await _loadTasks();
  }
} 