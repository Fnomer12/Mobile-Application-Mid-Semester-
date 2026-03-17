import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> tasks = [];

  final TextEditingController titleController = TextEditingController();
  final TextEditingController courseCodeController = TextEditingController();
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  @override
  void dispose() {
    titleController.dispose();
    courseCodeController.dispose();
    super.dispose();
  }

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedTasks = prefs.getStringList('tasks');

    if (savedTasks != null && savedTasks.isNotEmpty) {
      setState(() {
        tasks = savedTasks.map((taskString) {
          final Map<String, dynamic> taskMap = jsonDecode(taskString);
          return Task(
            title: taskMap['title'],
            courseCode: taskMap['courseCode'],
            dueDate: DateTime.parse(taskMap['dueDate']),
            isComplete: taskMap['isComplete'],
          );
        }).toList();
      });
    } else {
      setState(() {
        tasks = [
          Task(
            title: 'Study Flutter Widgets',
            courseCode: 'DCIT 318',
            dueDate: DateTime(2026, 3, 20),
          ),
          Task(
            title: 'Submit Midsem Project',
            courseCode: 'DCIT 308',
            dueDate: DateTime(2026, 3, 25),
          ),
          Task(
            title: 'Read About Firebase',
            courseCode: 'DCIT 315',
            dueDate: DateTime(2026, 3, 28),
          ),
        ];
      });
      await saveTasks();
    }
  }

  Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> taskStrings = tasks.map((task) {
      return jsonEncode({
        'title': task.title,
        'courseCode': task.courseCode,
        'dueDate': task.dueDate.toIso8601String(),
        'isComplete': task.isComplete,
      });
    }).toList();

    await prefs.setStringList('tasks', taskStrings);
  }

  Future<void> pickDate(StateSetter setDialogState) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setDialogState(() {
        selectedDate = picked;
      });
    }
  }

  void showAddTaskDialog() {
    titleController.clear();
    courseCodeController.clear();
    selectedDate = null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text('Add New Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Task Title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: courseCodeController,
                      decoration: InputDecoration(
                        labelText: 'Course Code',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => pickDate(setDialogState),
                        icon: const Icon(Icons.calendar_month),
                        label: const Text('Pick Due Date'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedDate == null
                          ? 'No date selected'
                          : 'Selected: ${DateFormat('dd/MM/yyyy').format(selectedDate!)}',
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty &&
                        courseCodeController.text.isNotEmpty &&
                        selectedDate != null) {
                      setState(() {
                        tasks.add(
                          Task(
                            title: titleController.text,
                            courseCode: courseCodeController.text,
                            dueDate: selectedDate!,
                          ),
                        );
                      });
                      await saveTasks();
                      if (mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void toggleTask(int index, bool? value) async {
    setState(() {
      tasks[index].isComplete = value ?? false;
    });
    await saveTasks();
  }

  int get completedTasks => tasks.where((task) => task.isComplete).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task List Screen'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.indigo, Colors.blueAccent],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Task Summary',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Completed: $completedTasks / ${tasks.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor:
                          task.isComplete ? Colors.green : Colors.indigo,
                      child: Icon(
                        task.isComplete ? Icons.check : Icons.book,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: task.isComplete
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Course Code: ${task.courseCode}'),
                          Text(
                            'Due Date: ${DateFormat('dd/MM/yyyy').format(task.dueDate)}',
                          ),
                        ],
                      ),
                    ),
                    trailing: Checkbox(
                      value: task.isComplete,
                      onChanged: (value) => toggleTask(index, value),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddTaskDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }
}