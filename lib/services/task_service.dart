import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import '../models/task.dart';

class TaskService {
  static const String _boxName = 'tasks';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();
  late Box<Task> _taskBox;
  
  Future<void> initialize() async {
    _taskBox = await Hive.openBox<Task>(_boxName);
    _setupConnectivityListener();
  }

  void _setupConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        syncWithCloud();
      }
    });
  }

  Future<void> addTask(Task task) async {
    await _taskBox.put(task.id, task);
    await _syncTaskToCloud(task);
  }

  Future<void> updateTask(Task task) async {
    await _taskBox.put(task.id, task);
    await _syncTaskToCloud(task);
  }

  Future<void> deleteTask(String taskId) async {
    await _taskBox.delete(taskId);
    await _deleteTaskFromCloud(taskId);
  }

  List<Task> getAllTasks() {
    return _taskBox.values.toList();
  }

  Future<void> _syncTaskToCloud(Task task) async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        await _firestore
            .collection('tasks')
            .doc(task.id)
            .set(task.toJson());
      }
    } catch (e) {
      // Task will be synced later when connectivity is restored
      print('Error syncing task to cloud: $e');
    }
  }

  Future<void> _deleteTaskFromCloud(String taskId) async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        await _firestore.collection('tasks').doc(taskId).delete();
      }
    } catch (e) {
      print('Error deleting task from cloud: $e');
    }
  }

  Future<void> syncWithCloud() async {
    try {
      final snapshot = await _firestore.collection('tasks').get();
      final cloudTasks = snapshot.docs.map((doc) => Task.fromJson(doc.data())).toList();
      
      // Update local tasks
      for (var task in cloudTasks) {
        await _taskBox.put(task.id, task);
      }
      
      // Sync local tasks to cloud
      for (var task in _taskBox.values) {
        await _syncTaskToCloud(task);
      }
    } catch (e) {
      print('Error syncing with cloud: $e');
    }
  }

  void dispose() {
    _taskBox.close();
  }
} 