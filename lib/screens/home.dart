import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../helpers/adaptor.dart';
import '../widgets/task_card.dart';
import '../widgets/task_form.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late Box<Task> _taskBox;
  late Box _settingsBox;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _taskBox = Hive.box<Task>('tasks');
    _settingsBox = Hive.box('settings');
    _isDarkMode = _settingsBox.get('isDarkMode', defaultValue: false);
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
      _settingsBox.put('isDarkMode', _isDarkMode);
    });
    _showCoolSnackBar(_isDarkMode ? "Dark mode enabled" : "Light mode enabled");
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // final brightness = Theme.of(context).brightness;

    ///* [ValueListenableBuilder] ideally our state manager with hive boxes
    return ValueListenableBuilder(
        valueListenable: _taskBox.listenable(),
        builder: (context, Box<Task> box, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'TASKS manager',
                style: TextStyle(color: colorScheme.primary, fontSize: 18),
              ),
              actions: [
                Row(
                  children: [
                    Switch(
                      value: _isDarkMode,
                      onChanged: (value) {
                        _toggleTheme();
                      },
                    ),
                    Icon(
                      _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      size: 20,
                    ),
                    const SizedBox(width: 5)
                  ],
                ),
              ],
            ),
            body: box.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.book_outlined,
                          size: 60,
                          color: colorScheme.primary,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'No tasks yet. Add one!',
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      if (box.length > 2)
                        Card.outlined(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              '${box.values.where((task) => task.isCompleted).length} out of ${box.length} tasks completed',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium!
                                  .copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                            ),
                          ),
                        ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: box.length,
                          itemBuilder: (context, index) {
                            ///* just reverse to sort new ones first, but we have the [DateTime], should make more sense using that
                            final reverseIndex = box.length - 1 - index;
                            final task = box.getAt(reverseIndex)!;
                            return TaskCard(
                              task: task,
                              onDelete: () => _deleteTask(reverseIndex),
                              onToggle: () =>
                                  _toggleTaskStatus(reverseIndex, task),
                              onEdit: () => _showTaskForm(context,
                                  existingTask: task, index: reverseIndex),
                            );
                          },
                        ),
                      ),
                      if (box.length > 6) const SizedBox(height: 20)
                    ],
                  ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showTaskForm(context),
              child: const Icon(Icons.add),
            ),
          );
        });
  }

  void _deleteTask(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed) {
        await _taskBox.deleteAt(index);
        _showCoolSnackBar("Task deleted successfully");
      }
    });
  }

  void _toggleTaskStatus(int index, Task task) async {
    final updatedTask = Task(
      title: task.title,
      description: task.description,
      isCompleted: !task.isCompleted,
    );
    await _taskBox.putAt(index, updatedTask);
    if (kDebugMode) {
      _showCoolSnackBar("Updating status...");
    }
  }

  void _showTaskForm(BuildContext context, {Task? existingTask, int? index}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TaskForm(
        existingTask: existingTask,
        onSubmit: (title, description) {
          if (existingTask != null && index != null) {
            _updateTask(index, title, description, existingTask.isCompleted);
          } else {
            _addTask(title, description);
          }
        },
      ),
    );
  }

  void _addTask(String title, String description) {
    final task = Task(
      title: title,
      description: description,
    );
    _taskBox.add(task);
  }

  void _updateTask(
      int index, String title, String description, bool isCompleted) {
    final task = Task(
      title: title,
      description: description,
      isCompleted: isCompleted,
    );
    _taskBox.putAt(index, task);
  }

  void _showCoolSnackBar(String details) {
    final snackBar = SnackBar(
      content: Text(details),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
