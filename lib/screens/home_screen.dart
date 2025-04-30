import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../models/task.dart';
import '../services/command_parser.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/task_item.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _micAnimationController;
  bool _isLoading = false;
  String? _loadingMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _micAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _initializeServices();
  }

  @override
  void dispose() {
    _micAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    _setLoading(true, 'Initializing voice services...');
    try {
      final voiceService = ref.read(voiceServiceProvider);
      await voiceService.initialize();
    } catch (e) {
      _showError('Failed to initialize voice services. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading, [String? message]) {
    setState(() {
      _isLoading = loading;
      _loadingMessage = message;
      _errorMessage = null;
    });
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _isLoading = false;
      _loadingMessage = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleVoiceCommand(String command) async {
    final commandParser = ref.read(commandParserProvider);
    final tasksNotifier = ref.read(tasksProvider.notifier);
    final voiceService = ref.read(voiceServiceProvider);

    try {
      final result = commandParser.parseCommand(command);

      switch (result.type) {
        case CommandType.add:
          if (result.task != null) {
            _setLoading(true, 'Adding task...');
            await tasksNotifier.addTask(result.task!);
            await voiceService.speak('Task added: ${result.task!.title}');
          }
          break;
        case CommandType.complete:
          if (result.taskTitle != null) {
            _setLoading(true, 'Updating task...');
            final tasks = ref.read(tasksProvider);
            try {
              final task = tasks.firstWhere(
                (task) => task.title.toLowerCase().contains(result.taskTitle!.toLowerCase()),
              );
              await tasksNotifier.toggleTaskComplete(task.id);
              await voiceService.speak(
                task.isCompleted ? 'Task completed: ${task.title}' : 'Task uncompleted: ${task.title}',
              );
            } catch (e) {
              await voiceService.speak('Task not found: ${result.taskTitle}');
            }
          }
          break;
        case CommandType.delete:
          if (result.taskTitle != null) {
            _setLoading(true, 'Deleting task...');
            final tasks = ref.read(tasksProvider);
            try {
              final task = tasks.firstWhere(
                (task) => task.title.toLowerCase().contains(result.taskTitle!.toLowerCase()),
              );
              await tasksNotifier.deleteTask(task.id);
              await voiceService.speak('Task deleted: ${task.title}');
            } catch (e) {
              await voiceService.speak('Task not found: ${result.taskTitle}');
            }
          }
          break;
        case CommandType.list:
          final tasks = ref.read(tasksProvider);
          final filteredTasks = switch (result.filter) {
            TaskFilter.completed => tasks.where((t) => t.isCompleted),
            TaskFilter.pending => tasks.where((t) => !t.isCompleted),
            TaskFilter.priority => tasks.where((t) => t.isHighPriority),
            _ => tasks,
          };
          
          if (filteredTasks.isEmpty) {
            await voiceService.speak('No tasks found.');
          } else {
            final taskList = filteredTasks.map((task) => task.title).join(', ');
            await voiceService.speak('Your tasks are: $taskList');
          }
          break;
        case CommandType.help:
          await voiceService.speak(result.helpMessage ?? 'No help available.');
          break;
        case CommandType.search:
          if (result.searchQuery != null) {
            final tasks = ref.read(tasksProvider);
            final matchingTasks = tasks.where(
              (task) => task.title.toLowerCase().contains(result.searchQuery!.toLowerCase()),
            );
            if (matchingTasks.isEmpty) {
              await voiceService.speak('No tasks found matching: ${result.searchQuery}');
            } else {
              final taskList = matchingTasks.map((task) => task.title).join(', ');
              await voiceService.speak('Found tasks: $taskList');
            }
          }
          break;
        case CommandType.unknown:
          await voiceService.speak(result.errorMessage ?? 'Sorry, I didn\'t understand that command.');
          break;
      }
    } catch (e) {
      _showError('Error processing command: $e');
    } finally {
      _setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);
    final isListening = ref.watch(isListeningProvider);

    return LoadingOverlay(
      isLoading: _isLoading,
      message: _loadingMessage,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Voice Todo'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () async {
                _setLoading(true, 'Syncing tasks...');
                try {
                  await ref.read(tasksProvider.notifier).syncWithCloud();
                } catch (e) {
                  _showError('Failed to sync tasks: $e');
                } finally {
                  _setLoading(false);
                }
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.task_alt,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No tasks yet!\nTry adding one with your voice.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: tasks.length,
                      padding: const EdgeInsets.only(bottom: 88),
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return TaskItem(
                          key: ValueKey(task.id),
                          task: task,
                          onDelete: () {
                            ref.read(tasksProvider.notifier).deleteTask(task.id);
                          },
                          onToggle: () {
                            ref.read(tasksProvider.notifier).toggleTaskComplete(task.id);
                          },
                        );
                      },
                    ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  isListening ? 'Listening...' : 'Tap the microphone to start',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final voiceService = ref.read(voiceServiceProvider);
            final isListeningNotifier = ref.read(isListeningProvider.notifier);

            if (!isListening) {
              isListeningNotifier.state = true;
              _micAnimationController.repeat(reverse: true);
              await voiceService.startListening(_handleVoiceCommand);
            } else {
              isListeningNotifier.state = false;
              _micAnimationController.stop();
              await voiceService.stopListening();
            }
          },
          child: AnimatedBuilder(
            animation: _micAnimationController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_micAnimationController.value * 0.2),
                child: Icon(isListening ? Icons.mic : Icons.mic_none),
              );
            },
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
} 