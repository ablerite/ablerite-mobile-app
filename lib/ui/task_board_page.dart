import 'package:flutter/material.dart';
import 'widgets/ablerite_loading_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'widgets/auto_walkthrough.dart';
import 'widgets/confirmation_dialog.dart';
import 'widgets/spotlight_walkthrough.dart';
import '../models/goal.dart';
import '../models/item.dart';

class TaskBoardPage extends StatefulWidget {
  final Goal goal;
  final Item? parentTask;
  final String? initialTaskId;

  const TaskBoardPage({
    super.key,
    required this.goal,
    this.parentTask,
    this.initialTaskId,
  });

  @override
  State<TaskBoardPage> createState() => _TaskBoardPageState();
}

class _TaskBoardPageState extends State<TaskBoardPage>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _client = Supabase.instance.client;
  List<Item> todoTasks = [];
  List<Item> doingTasks = [];
  List<Item> doneTasks = [];
  bool isLoading = true;
  late TabController _tabController;
  final GlobalKey _progressKey = GlobalKey();
  final GlobalKey _tabsKey = GlobalKey();
  final GlobalKey _taskListKey = GlobalKey();
  final GlobalKey _addTaskKey = GlobalKey();
  bool _hasSnappedToInitialTask = false;
  String? _highlightedTaskId;
  final Map<String, GlobalKey> _taskKeys = {};
  final Map<String, ScrollController> _taskScrollControllers = {
    'todo': ScrollController(),
    'doing': ScrollController(),
    'done': ScrollController(),
  };

  String get _parentId => widget.parentTask?.id ?? widget.goal.id;
  String get _boardTitle =>
      widget.parentTask == null ? 'Task Board' : 'Sub-Task Board';
  String get _boardSubtitle => widget.parentTask?.text ?? widget.goal.text;
  bool get _isSubTaskBoard => widget.parentTask != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final controller in _taskScrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  List<Item> _tasksForStatus(String status) => switch (status) {
    'doing' => doingTasks,
    'done' => doneTasks,
    _ => todoTasks,
  };

  void _snapToTask(Item task) {
    final status = switch (task.status) {
      'doing' => 'doing',
      'done' => 'done',
      _ when task.completed == true => 'done',
      _ => 'todo',
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = _taskScrollControllers[status];
      final taskIndex = _tasksForStatus(
        status,
      ).indexWhere((candidate) => candidate.id == task.id);
      if (controller == null || taskIndex < 0 || !controller.hasClients) return;

      final position = controller.position;
      final estimatedOffset = (taskIndex * 156.0).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      controller.jumpTo(estimatedOffset);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final taskContext = _taskKeys[task.id]?.currentContext;
        if (taskContext != null) {
          Scrollable.ensureVisible(
            taskContext,
            alignment: 0.35,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AutoWalkthrough.maybeShowOnce(
      context,
      id: 'goal-task-board',
      steps: _walkthroughSteps,
    );
  }

  void _showTaskBoardWalkthrough() {
    SpotlightWalkthrough.show(context, steps: _walkthroughSteps);
  }

  List<SpotlightStep> get _walkthroughSteps => [
    SpotlightStep(
      targetKey: _progressKey,
      title: 'Board Progress',
      body: 'Displays overall completion progress for all tasks on this board.',
    ),
    SpotlightStep(
      targetKey: _tabsKey,
      title: 'Task Stages',
      body:
          'Switch between To Do, Doing, and Done to track task progression.',
    ),
    SpotlightStep(
      targetKey: _addTaskKey,
      title: 'Add to Stage',
      body:
          'Tap to add a new task to the selected stage and optionally link it to a goal.',
    ),
    SpotlightStep(
      targetKey: _taskListKey,
      title: 'Reorder & Manage',
      body:
          'Drag tasks to reorder them, move them between stages, or edit linked goals.',
    ),
  ];

  Future<void> _loadTasks() async {
    setState(() => isLoading = true);
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      final baseQuery = _client
          .from('items')
          .select()
          .eq('user_id', userId)
          .eq('section', 'tasks');
      final response = _isSubTaskBoard
          ? await baseQuery
                .eq('parent_id', _parentId)
                .order('order_index', ascending: true)
          : await baseQuery
                .or(
                  'parent_id.eq.${widget.goal.id},related_ids.cs.{${widget.goal.id}}',
                )
                .order('order_index', ascending: true);

      final tasks = response.map<Item>((json) => Item.fromJson(json)).toList();

      setState(() {
        todoTasks = tasks
            .where((t) => t.status == 'todo' || t.status == null)
            .toList();
        doingTasks = tasks.where((t) => t.status == 'doing').toList();
        doneTasks = tasks
            .where((t) => t.status == 'done' || t.completed == true)
            .toList();
        isLoading = false;
      });

      if (!_hasSnappedToInitialTask && widget.initialTaskId != null) {
        final matches = tasks.where((t) => t.id == widget.initialTaskId);
        if (matches.isNotEmpty) {
          _hasSnappedToInitialTask = true;
          final task = matches.first;
          final tabIndex = switch (task.status) {
            'doing' => 1,
            'done' => 2,
            _ when task.completed == true => 2,
            _ => 0,
          };
          _tabController.index = tabIndex;
          setState(() => _highlightedTaskId = task.id);
          _snapToTask(task);
          Future<void>.delayed(const Duration(seconds: 3), () {
            if (mounted && _highlightedTaskId == task.id) {
              setState(() => _highlightedTaskId = null);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading tasks: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateTaskStatus(Item task, String newStatus) async {
    try {
      await _client
          .from('items')
          .update({'status': newStatus, 'completed': newStatus == 'done'})
          .eq('id', task.id);
      _loadTasks();
    } catch (e) {
      debugPrint('Error updating task status: $e');
    }
  }

  Future<void> _pickTaskDueDate(Item task) async {
    final initialDate = task.dueDate == null || task.dueDate!.isEmpty
        ? DateTime.now()
        : DateTime.tryParse(task.dueDate!) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    await _updateTaskDueDate(task, picked.toIso8601String().split('T').first);
  }

  Future<void> _updateTaskDueDate(Item task, String? dueDate) async {
    try {
      await _client
          .from('items')
          .update({'due_date': dueDate})
          .eq('id', task.id);
      _loadTasks();
    } catch (e) {
      debugPrint('Error updating task due date: $e');
    }
  }

  Widget _buildDueDateField({
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    final displayValue = value == null || value.isEmpty ? 'Due Date' : value;
    return Builder(
      builder: (context) => InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          final initialDate = value == null || value.isEmpty
              ? DateTime.now()
              : DateTime.tryParse(value) ?? DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: initialDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            onChanged(picked.toIso8601String().split('T').first);
          }
        },
        onLongPress: () => onChanged(null),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).dividerColor.withAlpha(50),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayValue,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: value == null || value.isEmpty
                        ? Theme.of(context).colorScheme.onSurface.withAlpha(150)
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: value == null || value.isEmpty
                        ? FontWeight.normal
                        : FontWeight.w600,
                  ),
                ),
              ),
              if (value != null && value.isNotEmpty)
                GestureDetector(
                  onTap: () => onChanged(null),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(150),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addTask(String columnStatus) async {
    final textController = TextEditingController();
    List<Goal> availableGoals = [];
    Set<String> selectedGoalIds = {};
    String? dueDate;
    bool isLoadingGoals = true;

    // Fetch goals when the dialog opens
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId != null) {
        final goalsResponse = await _client
            .from('items')
            .select()
            .eq('user_id', userId)
            .inFilter('section', ['activeGoals', 'longTermGoals'])
            .neq('status', 'deleted')
            .neq('status', 'trashed');

        availableGoals = goalsResponse.map((g) => Goal.fromJson(g)).toList();
        // Remove the current goal from the linkable list so they don't link it to itself redundantly
        availableGoals.removeWhere((g) => g.id == widget.goal.id);
      }
    } catch (e) {
      debugPrint('Error loading goals: $e');
    }
    isLoadingGoals = false;

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text(
                'Add Task',
                style: GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: textController,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Enter task description',
                          hintStyle: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(120),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(
                                context,
                              ).dividerColor.withAlpha(50),
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        autofocus: true,
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 180,
                          child: _buildDueDateField(
                            value: dueDate,
                            onChanged: (value) =>
                                setDialogState(() => dueDate = value),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          iconColor: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(150),
                          collapsedIconColor: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(150),
                          title: Text(
                            'Link Goals',
                            style: GoogleFonts.outfit(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(150),
                            ),
                          ),
                          children: [
                            if (isLoadingGoals)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: AbleriteLoadingIndicator(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              )
                            else if (availableGoals.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  "No goals found",
                                  style: GoogleFonts.outfit(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withAlpha(150),
                                  ),
                                ),
                              )
                            else
                              ...availableGoals.map((Goal goal) {
                                return CheckboxListTile(
                                  title: Text(
                                    goal.text,
                                    style: GoogleFonts.outfit(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                  ),
                                  value: selectedGoalIds.contains(goal.id),
                                  activeColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  checkColor: Colors.white,
                                  onChanged: (bool? checked) {
                                    setDialogState(() {
                                      if (checked == true) {
                                        selectedGoalIds.add(goal.id);
                                      } else {
                                        selectedGoalIds.remove(goal.id);
                                      }
                                    });
                                  },
                                );
                              }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.outfit(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    if (textController.text.isNotEmpty) {
                      try {
                        final userId = _client.auth.currentUser?.id;
                        if (userId == null) return;

                        final taskData = {
                          'id': const Uuid().v4(),
                          'user_id': userId,
                          'text': textController.text,
                          'section': 'tasks',
                          'parent_id': _parentId,
                          'status': columnStatus,
                          'completed': columnStatus == 'done',
                          'due_date': dueDate,
                          if (selectedGoalIds.isNotEmpty)
                            'related_ids': selectedGoalIds.toList(),
                        };

                        await _client.from('items').insert(taskData);
                        _loadTasks();
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        debugPrint('Error adding task: $e');
                      }
                    }
                  },
                  child: Text(
                    'Add',
                    style: GoogleFonts.outfit(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteTask(String taskId) async {
    final confirm = await showDeleteBottomSheet(
      context,
      title: 'Delete Task?',
      subtitle: 'This cannot be undone.',
    );
    if (confirm != true) return;
    try {
      await _client.from('items').delete().eq('id', taskId);
      _loadTasks();
    } catch (e) {
      debugPrint('Error deleting task: $e');
    }
  }

  Future<void> _showEditTaskDialog(Item task) async {
    final textController = TextEditingController(text: task.text);
    List<Goal> availableGoals = [];
    Set<String> selectedGoalIds = task.relatedIds != null
        ? task.relatedIds!.toSet()
        : {};
    String? dueDate = task.dueDate;
    bool isLoadingGoals = true;

    try {
      final userId = _client.auth.currentUser?.id;
      if (userId != null) {
        final goalsResponse = await _client
            .from('items')
            .select()
            .eq('user_id', userId)
            .inFilter('section', ['activeGoals', 'longTermGoals'])
            .neq('status', 'deleted')
            .neq('status', 'trashed');

        availableGoals = goalsResponse.map((g) => Goal.fromJson(g)).toList();
        availableGoals.removeWhere((g) => g.id == widget.goal.id);
      }
    } catch (e) {
      debugPrint('Error loading goals: $e');
    }
    isLoadingGoals = false;

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text(
                'Edit Task',
                style: GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: textController,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Enter task description',
                          hintStyle: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(120),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(
                                context,
                              ).dividerColor.withAlpha(50),
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        autofocus: true,
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 180,
                          child: _buildDueDateField(
                            value: dueDate,
                            onChanged: (value) =>
                                setDialogState(() => dueDate = value),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          iconColor: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(150),
                          collapsedIconColor: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(150),
                          title: Text(
                            'Link Goals',
                            style: GoogleFonts.outfit(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(150),
                            ),
                          ),
                          children: [
                            if (isLoadingGoals)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: AbleriteLoadingIndicator(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              )
                            else if (availableGoals.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  "No goals found",
                                  style: GoogleFonts.outfit(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withAlpha(150),
                                  ),
                                ),
                              )
                            else
                              ...availableGoals.map((Goal goal) {
                                return CheckboxListTile(
                                  title: Text(
                                    goal.text,
                                    style: GoogleFonts.outfit(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                  ),
                                  value: selectedGoalIds.contains(goal.id),
                                  activeColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  checkColor: Colors.white,
                                  onChanged: (bool? checked) {
                                    setDialogState(() {
                                      if (checked == true) {
                                        selectedGoalIds.add(goal.id);
                                      } else {
                                        selectedGoalIds.remove(goal.id);
                                      }
                                    });
                                  },
                                );
                              }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.outfit(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    if (textController.text.trim().isNotEmpty &&
                        textController.text != task.text) {
                      try {
                        await _client
                            .from('items')
                            .update({
                              'text': textController.text.trim(),
                              'related_ids': selectedGoalIds.toList(),
                              'due_date': dueDate,
                            })
                            .eq('id', task.id);
                        _loadTasks();
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        debugPrint('Error editing task: $e');
                      }
                    } else if (textController.text.trim().isNotEmpty) {
                      try {
                        await _client
                            .from('items')
                            .update({
                              'related_ids': selectedGoalIds.toList(),
                              'due_date': dueDate,
                            })
                            .eq('id', task.id);
                        _loadTasks();
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        debugPrint('Error editing task: $e');
                      }
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    'Save',
                    style: GoogleFonts.outfit(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _onReorder(String status, int oldIndex, int newIndex) async {
    setState(() {
      late List<Item> targetList;
      if (status == 'todo') {
        targetList = todoTasks;
      } else if (status == 'doing') {
        targetList = doingTasks;
      } else {
        targetList = doneTasks;
      }

      final Item item = targetList.removeAt(oldIndex);
      targetList.insert(newIndex, item);

      for (int i = 0; i < targetList.length; i++) {
        targetList[i] = targetList[i].copyWith(orderIndex: i);
      }
    });

    try {
      final targetList = status == 'todo'
          ? todoTasks
          : (status == 'doing' ? doingTasks : doneTasks);

      final updates = <Future>[];
      for (int i = 0; i < targetList.length; i++) {
        updates.add(
          _client
              .from('items')
              .update({'order_index': i})
              .eq('id', targetList[i].id),
        );
      }
      await Future.wait(updates);
    } catch (e) {
      debugPrint('Error reordering tasks: $e');
      _loadTasks();
    }
  }

  Widget _buildTaskList(List<Item> tasks, String status, Color accentColor) {
    return Column(
      children: [
        // Add button at top
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: status == _statusForCurrentTab() ? _addTaskKey : null,
              onPressed: () => _addTask(status),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                'Add Task',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        // Task list
        Expanded(
          child: tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(80),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tasks yet',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(150),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap "Add Task" to get started',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(120),
                        ),
                      ),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  scrollController: _taskScrollControllers[status],
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  buildDefaultDragHandles: false,
                  itemCount: tasks.length,
                  onReorderItem: (oldIndex, newIndex) =>
                      _onReorder(status, oldIndex, newIndex),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Container(
                      key: _taskKeys.putIfAbsent(task.id, () => GlobalKey()),
                      child: _buildTaskCard(task, status, accentColor, index),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _statusForCurrentTab() {
    switch (_tabController.index) {
      case 1:
        return 'doing';
      case 2:
        return 'done';
      case 0:
      default:
        return 'todo';
    }
  }

  Widget _buildDueDateBadge(String dueDate) {
    final parsed = DateTime.tryParse(dueDate);
    final today = DateTime.now();
    final isOverdue =
        parsed != null &&
        DateTime(
          parsed.year,
          parsed.month,
          parsed.day,
        ).isBefore(DateTime(today.year, today.month, today.day));
    final label = parsed == null
        ? dueDate
        : '${parsed.day}/${parsed.month}/${parsed.year.toString().substring(2)}';
    final color = isOverdue ? Colors.redAccent : Colors.grey;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.event_outlined, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          'Due $label',
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(
    Item task,
    String currentStatus,
    Color accentColor,
    int index,
  ) {
    final isHighlighted = _highlightedTaskId == task.id;
    return GestureDetector(
      onLongPress: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                TaskBoardPage(goal: widget.goal, parentTask: task),
          ),
        ).then((_) => _loadTasks());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHighlighted
                ? Theme.of(context).colorScheme.primary
                : accentColor.withAlpha(75),
            width: isHighlighted ? 2.5 : 1.5,
          ),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withAlpha(80),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: Icon(
                      Icons.drag_indicator,
                      size: 22,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(90),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.text,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            height: 1.5,
                            color: task.completed == true
                                ? Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withAlpha(120)
                                : Theme.of(context).colorScheme.onSurface,
                            decoration: task.completed == true
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (task.dueDate != null &&
                            task.dueDate!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => _pickTaskDueDate(task),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildDueDateBadge(task.dueDate!),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => _updateTaskDueDate(task, null),
                                  child: Icon(
                                    Icons.close,
                                    size: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withAlpha(120),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Actions Row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withAlpha(25),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Move buttons
                  Row(
                    children: [
                      if (currentStatus != 'todo')
                        TextButton.icon(
                          onPressed: () {
                            final newStatus = currentStatus == 'done'
                                ? 'doing'
                                : 'todo';
                            _updateTaskStatus(task, newStatus);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          icon: const Icon(Icons.chevron_left, size: 18),
                          label: Text(
                            'Back',
                            style: GoogleFonts.outfit(fontSize: 12),
                          ),
                        ),
                      if (currentStatus != 'done')
                        TextButton.icon(
                          onPressed: () {
                            final newStatus = currentStatus == 'todo'
                                ? 'doing'
                                : 'done';
                            _updateTaskStatus(task, newStatus);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: accentColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          icon: Text(
                            'Next',
                            style: GoogleFonts.outfit(fontSize: 12),
                          ),
                          label: const Icon(Icons.chevron_right, size: 18),
                        ),
                    ],
                  ),
                  // Due date, Edit, and Delete buttons
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _pickTaskDueDate(task),
                        icon: Icon(
                          Icons.calendar_today_outlined,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        tooltip: 'Set Due Date',
                      ),
                      IconButton(
                        onPressed: () => _showEditTaskDialog(task),
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: Colors.blue[400],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _deleteTask(task.id),
                        icon: Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: Colors.red[400],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = doneTasks.length;
    final totalCount = todoTasks.length + doingTasks.length + doneTasks.length;
    final progress = totalCount == 0 ? 0.0 : (completedCount / totalCount);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _boardTitle,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              _boardSubtitle,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Task board walkthrough',
            onPressed: _showTaskBoardWalkthrough,
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: AbleriteLoadingIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : Column(
              children: [
                // Progress Bar
                Container(
                  key: _progressKey,
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha(50),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PROGRESS',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(120),
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Theme.of(
                            context,
                          ).dividerColor.withAlpha(30),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                // Tab Bar
                TabBar(
                  key: _tabsKey,
                  controller: _tabController,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  indicatorWeight: 3,
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withAlpha(150),
                  labelStyle: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('TO DO'),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).dividerColor.withAlpha(30),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${todoTasks.length}',
                              style: GoogleFonts.outfit(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('DOING'),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withAlpha(50),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${doingTasks.length}',
                              style: GoogleFonts.outfit(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('DONE'),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withAlpha(50),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${doneTasks.length}',
                              style: GoogleFonts.outfit(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Tab Views
                Expanded(
                  key: _taskListKey,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTaskList(
                        todoTasks,
                        'todo',
                        Theme.of(context).colorScheme.primary,
                      ),
                      _buildTaskList(doingTasks, 'doing', Colors.amber),
                      _buildTaskList(
                        doneTasks,
                        'done',
                        Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
