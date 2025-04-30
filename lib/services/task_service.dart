import 'package:hive/hive.dart';
import '../models/task.dart';

class TaskService {
  static const String _boxName = 'tasks';
  late Box<Task> _taskBox;
  
  Future<void> initialize() async {
    _taskBox = await Hive.openBox<Task>(_boxName);
  }

  Future<void> addTask(Task task) async {
    await _taskBox.put(task.id, task);
  }

  Future<void> updateTask(Task task) async {
    await _taskBox.put(task.id, task);
  }

  Future<void> deleteTask(String taskId) async {
    await _taskBox.delete(taskId);
  }

  List<Task> getAllTasks() {
    return _taskBox.values.toList();
  }

  void dispose() {
    _taskBox.close();
  }
} 