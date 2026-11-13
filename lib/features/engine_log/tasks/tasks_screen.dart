import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme.dart';
import '../../../core/section_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../domain/models/task.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _box = Hive.box('tasks');
  
  final _nameCtrl = TextEditingController();
  final _assigneeCtrl = TextEditingController();
  final _deadlineCtrl = TextEditingController();
  String _priority = 'Medium';

  void _addTask() {
    if (_nameCtrl.text.isEmpty) return;

    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text,
      assignee: _assigneeCtrl.text,
      priority: _priority,
      deadline: _deadlineCtrl.text,
      status: 'Open',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    _box.put(newTask.id, newTask.toMap());
    
    setState(() {
      _nameCtrl.clear();
      _assigneeCtrl.clear();
      _deadlineCtrl.clear();
      _priority = 'Medium';
    });
  }

  void _toggleStatus(String id, String currentStatus) {
    final task = Task.fromMap(_box.get(id));
        if (currentStatus == 'Open') {
      task.status = 'In Progress';
    } else if (currentStatus == 'In Progress') {
      task.status = 'Done';
    } else {
      task.status = 'Open';
    }
    
    _box.put(id, task.toMap());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tasksData = _box.values.map((e) => Task.fromMap(e)).toList();
    tasksData.sort((a, b) {
      // Сначала невыполненные, потом по приоритету
      if (a.status == 'Done' && b.status != 'Done') return 1;
      if (a.status != 'Done' && b.status == 'Done') return -1;
      return b.timestamp.compareTo(a.timestamp);
    });

        return AppScaffold(
      title: 'Crew Tasks',
      background: AppBackground.engineRoom,
      section: AppSection.engine,
      body: Column(
        children: [
          // Форма добавления
          Container(
            padding: const EdgeInsets.all(16),
            color: cardSolid,
            child: Column(
              children: [
                TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Task Name')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _assigneeCtrl, decoration: const InputDecoration(labelText: 'Assignee'))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context, 
                            initialDate: DateTime.now(), 
                            firstDate: DateTime.now(), 
                            lastDate: DateTime(2030)
                          );
                          if (picked != null) {
                            setState(() => _deadlineCtrl.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}");
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Deadline'),
                          child: Text(_deadlineCtrl.text.isEmpty ? 'Select date' : _deadlineCtrl.text, style: const TextStyle(color: text)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _priority,
                        dropdownColor: cardSolid,
                        decoration: const InputDecoration(labelText: 'Priority'),
                        items: const [
                          DropdownMenuItem(value: 'Low', child: Text('Low')),
                          DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                          DropdownMenuItem(value: 'High', child: Text('High')),
                        ],
                        onChanged: (val) => setState(() => _priority = val!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _addTask,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(100, 50)),
                      child: const Text('ADD'),
                    )
                  ],
                )
              ],
            ),
          ),

          // Список задач
          Expanded(
            child: tasksData.isEmpty
                ? const Center(child: Text('No tasks yet.', style: TextStyle(color: textMuted)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tasksData.length,
                    itemBuilder: (context, index) {
                      final task = tasksData[index];
                      final isDone = task.status == 'Done';
                      final isHigh = task.priority == 'High';
                      
                      Color statusColor = textMuted;
                      if (task.status == 'In Progress') statusColor = Colors.orangeAccent;
                      if (task.status == 'Done') statusColor = Colors.green;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDone ? cardSolid.withValues(alpha: 0.5) : cardSolid,
                          border: Border.all(color: isHigh && !isDone ? Colors.redAccent : border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Text(
                            task.name,
                            style: TextStyle(
                              color: isDone ? textMuted : text,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Assignee: ${task.assignee.isEmpty ? "-" : task.assignee}', style: const TextStyle(fontSize: 12)),
                              if (task.deadline.isNotEmpty) Text('Deadline: ${task.deadline}', style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(task.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  task.status == 'Open' ? Icons.radio_button_unchecked : (task.status == 'In Progress' ? Icons.timelapse : Icons.check_circle),
                                  color: statusColor,
                                ),
                                onPressed: () => _toggleStatus(task.id, task.status),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                onPressed: () {
                                  _box.delete(task.id);
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}