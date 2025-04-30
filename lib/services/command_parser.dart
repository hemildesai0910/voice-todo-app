import '../models/task.dart';

class CommandParser {
  static const List<String> _addKeywords = [
    'add',
    'create',
    'new',
    'make',
    'set up',
    'remind me to',
    'i need to'
  ];
  static const List<String> _completeKeywords = [
    'complete',
    'finish',
    'done with',
    'mark as done',
    'completed',
    'mark complete'
  ];
  static const List<String> _deleteKeywords = [
    'delete',
    'remove',
    'get rid of',
    'eliminate'
  ];
  static const List<String> _listKeywords = [
    'list',
    'show',
    'what are',
    'tell me',
    'show me',
    'what do i have'
  ];
  static const List<String> _searchKeywords = [
    'find',
    'search',
    'look for',
    'where is'
  ];
  static const List<String> _priorityKeywords = [
    'important',
    'urgent',
    'priority',
    'critical'
  ];

  CommandResult parseCommand(String command) {
    final lowercaseCommand = command.toLowerCase();

    // Check for help command
    if (lowercaseCommand.contains('help') || 
        lowercaseCommand.contains('what can you do') ||
        lowercaseCommand.contains('commands')) {
      return CommandResult(
        type: CommandType.help,
        helpMessage: _getHelpMessage(),
      );
    }

    // Check for search command
    if (_containsAnyKeyword(lowercaseCommand, _searchKeywords)) {
      return _parseSearchCommand(command);
    }

    if (_containsAnyKeyword(lowercaseCommand, _addKeywords)) {
      return _parseAddCommand(command);
    } else if (_containsAnyKeyword(lowercaseCommand, _completeKeywords)) {
      return _parseCompleteCommand(command);
    } else if (_containsAnyKeyword(lowercaseCommand, _deleteKeywords)) {
      return _parseDeleteCommand(command);
    } else if (_containsAnyKeyword(lowercaseCommand, _listKeywords)) {
      return _parseListCommand(command);
    }

    return CommandResult(
      type: CommandType.unknown,
      errorMessage: "I didn't understand that command. Say 'help' to see available commands.",
    );
  }

  bool _containsAnyKeyword(String command, List<String> keywords) {
    return keywords.any((keyword) => command.contains(keyword));
  }

  CommandResult _parseAddCommand(String command) {
    final lowercaseCommand = command.toLowerCase();
    
    // Remove common add task phrases
    var cleanedCommand = lowercaseCommand
        .replaceAll(RegExp(_addKeywords.join('|')), '')
        .replaceAll('task', '')
        .trim();

    if (cleanedCommand.isEmpty) {
      return CommandResult(
        type: CommandType.unknown,
        errorMessage: "What task would you like to add?",
      );
    }

    // Check for priority indicators
    bool isHighPriority = _containsAnyKeyword(lowercaseCommand, _priorityKeywords);
    
    // Extract due date if present
    DateTime? dueDate = _extractDueDate(lowercaseCommand);
    
    // Clean the task title
    cleanedCommand = cleanedCommand
        .replaceAll(RegExp(_priorityKeywords.join('|')), '')
        .replaceAll(RegExp(r'by|due|on|at'), '')
        .replaceAll(RegExp(r'\b(today|tomorrow|next week)\b'), '')
        .trim();

    return CommandResult(
      type: CommandType.add,
      task: Task(
        title: cleanedCommand,
        isHighPriority: isHighPriority,
        dueDate: dueDate,
      ),
    );
  }

  DateTime? _extractDueDate(String command) {
    final now = DateTime.now();
    
    if (command.contains('today')) {
      return DateTime(now.year, now.month, now.day, 23, 59);
    } else if (command.contains('tomorrow')) {
      return DateTime(now.year, now.month, now.day + 1, 23, 59);
    } else if (command.contains('next week')) {
      return DateTime(now.year, now.month, now.day + 7, 23, 59);
    }
    
    return null;
  }

  CommandResult _parseListCommand(String command) {
    final lowercaseCommand = command.toLowerCase();
    
    if (lowercaseCommand.contains('completed') || 
        lowercaseCommand.contains('done')) {
      return CommandResult(type: CommandType.list, filter: TaskFilter.completed);
    } else if (lowercaseCommand.contains('pending') || 
               lowercaseCommand.contains('incomplete') ||
               lowercaseCommand.contains('not done')) {
      return CommandResult(type: CommandType.list, filter: TaskFilter.pending);
    } else if (_containsAnyKeyword(lowercaseCommand, _priorityKeywords)) {
      return CommandResult(type: CommandType.list, filter: TaskFilter.priority);
    }
    
    return CommandResult(type: CommandType.list, filter: TaskFilter.all);
  }

  CommandResult _parseSearchCommand(String command) {
    final cleanedCommand = command.toLowerCase()
        .replaceAll(RegExp(_searchKeywords.join('|')), '')
        .replaceAll('task', '')
        .trim();

    if (cleanedCommand.isEmpty) {
      return CommandResult(
        type: CommandType.unknown,
        errorMessage: "What would you like to search for?",
      );
    }

    return CommandResult(
      type: CommandType.search,
      searchQuery: cleanedCommand,
    );
  }

  CommandResult _parseCompleteCommand(String command) {
    final cleanedCommand = command.toLowerCase()
        .replaceAll(RegExp(_completeKeywords.join('|')), '')
        .replaceAll('task', '')
        .trim();

    if (cleanedCommand.isEmpty) {
      return CommandResult(
        type: CommandType.unknown,
        errorMessage: "Which task would you like to mark as complete?",
      );
    }

    return CommandResult(
      type: CommandType.complete,
      taskTitle: cleanedCommand,
    );
  }

  CommandResult _parseDeleteCommand(String command) {
    final cleanedCommand = command.toLowerCase()
        .replaceAll(RegExp(_deleteKeywords.join('|')), '')
        .replaceAll('task', '')
        .trim();

    if (cleanedCommand.isEmpty) {
      return CommandResult(
        type: CommandType.unknown,
        errorMessage: "Which task would you like to delete?",
      );
    }

    return CommandResult(
      type: CommandType.delete,
      taskTitle: cleanedCommand,
    );
  }

  String _getHelpMessage() {
    return '''
Here are the commands I understand:
- Add a task: "Add [task]" or "Remind me to [task]"
- Complete a task: "Mark [task] as complete"
- Delete a task: "Delete [task]"
- List tasks: "Show my tasks" or "What do I have to do?"
- List completed tasks: "Show completed tasks"
- List priority tasks: "Show important tasks"
- Search tasks: "Find [task]" or "Search for [task]"
- Add priority task: "Add important task [task]"
- Add task with due date: "Add [task] due tomorrow"
''';
  }
}

enum CommandType {
  add,
  complete,
  delete,
  list,
  search,
  help,
  unknown,
}

enum TaskFilter {
  all,
  completed,
  pending,
  priority,
}

class CommandResult {
  final CommandType type;
  final Task? task;
  final String? taskTitle;
  final String? errorMessage;
  final String? helpMessage;
  final String? searchQuery;
  final TaskFilter? filter;

  CommandResult({
    required this.type,
    this.task,
    this.taskTitle,
    this.errorMessage,
    this.helpMessage,
    this.searchQuery,
    this.filter,
  });
} 