import 'package:flutter/material.dart';
import 'widgets/ablerite_loading_indicator.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/goal.dart';
import '../models/item.dart';
import '../services/goals_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'task_board_page.dart';
import 'vision_page.dart';
import 'widgets/auto_walkthrough.dart';
import 'widgets/confirmation_dialog.dart';
import 'widgets/smart_goal_fields.dart';
import 'widgets/spotlight_walkthrough.dart';

class GoalDetailPage extends StatefulWidget {
  final Goal goal;

  const GoalDetailPage({super.key, required this.goal});

  @override
  State<GoalDetailPage> createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends State<GoalDetailPage>
    with SingleTickerProviderStateMixin {
  final GoalsService _goalsService = GoalsService();
  final SupabaseClient _client = Supabase.instance.client;
  List<Item> tasks = [];
  List<Goal> relatedGoals = [];
  List<Item> visionBoards = [];
  bool isLoading = true;
  late TabController _taskTabController;

  // Local state for linked ids
  late List<String> _currentRelatedIds;
  late List<String> _currentVisionBoardIds;

  // Local state for goal details (to reflect edits immediately)
  late Goal _currentGoal;
  late String _currentGoalText;
  late String? _currentGoalCategory;
  late String? _currentGoalType;
  late String? _currentGoalWhy;
  late String _currentGoalSection;
  late bool _currentGoalIsPrimary;
  late String? _currentGoalStartDate;
  late String? _currentGoalDueDate;
  late double? _currentGoalCostEstimate;
  late String? _currentGoalCostType;
  late String? _currentGoalSpecific;
  late String? _currentGoalMeasurable;
  late String? _currentGoalAchievable;
  late String? _currentGoalRelevant;
  final GlobalKey _goalSummaryKey = GlobalKey();
  final GlobalKey _taskTabsKey = GlobalKey();
  final GlobalKey _taskListKey = GlobalKey();
  final GlobalKey _addTaskKey = GlobalKey();
  final GlobalKey _taskBoardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _taskTabController = TabController(length: 3, vsync: this);
    _currentGoal = widget.goal;
    _syncCurrentGoalState();
    _loadData();
  }

  void _syncCurrentGoalState() {
    _currentRelatedIds = _currentGoal.relatedIds ?? [];
    _currentVisionBoardIds = _currentGoal.relatedVisionBoardIds ?? [];
    _currentGoalText = _currentGoal.text;
    _currentGoalCategory = _currentGoal.category;
    _currentGoalType = _currentGoal.goalType;
    _currentGoalWhy = _currentGoal.why;
    _currentGoalSection = _currentGoal.section;
    _currentGoalIsPrimary = _currentGoal.isPrimary;
    _currentGoalStartDate = _currentGoal.startDate;
    _currentGoalDueDate = _currentGoal.dueDate;
    _currentGoalCostEstimate = _currentGoal.costEstimate;
    _currentGoalCostType = _currentGoal.costType;
    _currentGoalSpecific = _currentGoal.specific;
    _currentGoalMeasurable = _currentGoal.measurable;
    _currentGoalAchievable = _currentGoal.achievable;
    _currentGoalRelevant = _currentGoal.relevant;
  }

  @override
  void dispose() {
    _taskTabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AutoWalkthrough.maybeShowOnce(
      context,
      id: 'goal-detail',
      steps: _walkthroughSteps,
    );
  }

  void _showGoalDetailWalkthrough() {
    SpotlightWalkthrough.show(context, steps: _walkthroughSteps);
  }

  List<SpotlightStep> get _walkthroughSteps => [
    SpotlightStep(
      targetKey: _goalSummaryKey,
      title: 'Goal Summary',
      body:
          'Review your goal\'s SMART breakdown, target dates, estimated cost, linked vision boards, and motivation.',
    ),
    SpotlightStep(
      targetKey: _taskTabsKey,
      title: 'Task Stages',
      body:
          'Organize tasks into To Do, Doing, and Done to track progress toward this goal.',
    ),
    SpotlightStep(
      targetKey: _taskListKey,
      title: 'Task Order',
      body: 'Drag and drop tasks inside any stage tab to adjust their priority.',
    ),
    SpotlightStep(
      targetKey: _addTaskKey,
      title: 'Add Task',
      body: 'Create a new action item directly in the active stage.',
    ),
    SpotlightStep(
      targetKey: _taskBoardKey,
      title: 'Full Task Board',
      body: 'Switch to the full task board view to manage tasks across all your goals.',
    ),
  ];

  Future<void> _loadData() async {
    await Future.wait([_loadTasks(), _loadRelatedGoals(), _loadVisionBoards()]);
  }

  Future<void> _loadTasks() async {
    setState(() => isLoading = true);
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _client
          .from('items')
          .select()
          .eq('user_id', userId)
          .eq('section', 'tasks')
          .or(
            'parent_id.eq.${widget.goal.id},related_ids.cs.{${widget.goal.id}}',
          )
          .order('order_index', ascending: true);

      setState(() {
        tasks = response.map<Item>((json) => Item.fromJson(json)).toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading tasks: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _addTask(
    String taskText, {
    String status = 'todo',
    String? dueDate,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;
      final nextOrder = _tasksForStatus(status).fold<int>(
        0,
        (max, task) =>
            (task.orderIndex ?? 0) >= max ? (task.orderIndex ?? 0) + 1 : max,
      );

      final taskData = {
        'id': const Uuid().v4(),
        'user_id': userId,
        'text': taskText,
        'section': 'tasks',
        'parent_id': widget.goal.id,
        'completed': status == 'done',
        'status': status,
        'order_index': nextOrder,
        'due_date': dueDate,
      };

      await _client.from('items').insert(taskData);
      _loadTasks();
    } catch (e) {
      debugPrint('Error adding task: $e');
    }
  }

  Future<void> _toggleTask(Item task) async {
    try {
      final isDone = _taskStatus(task) == 'done';
      final newStatus = isDone ? 'todo' : 'done';
      await _client
          .from('items')
          .update({'status': newStatus, 'completed': newStatus == 'done'})
          .eq('id', task.id);
      _loadTasks();
    } catch (e) {
      debugPrint('Error toggling task: $e');
    }
  }

  Future<void> _updateTaskStatus(Item task, String status) async {
    try {
      await _client
          .from('items')
          .update({'status': status, 'completed': status == 'done'})
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

  Future<void> _reorderGoalTasks(
    String status,
    int oldIndex,
    int newIndex,
  ) async {
    final visibleTasks = _tasksForStatus(status);
    if (oldIndex < 0 ||
        oldIndex >= visibleTasks.length ||
        newIndex < 0 ||
        newIndex > visibleTasks.length) {
      return;
    }

    final reordered = visibleTasks.toList();
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    setState(() {
      for (var i = 0; i < reordered.length; i++) {
        final updatedTask = reordered[i].copyWith(orderIndex: i);
        final taskIndex = tasks.indexWhere((task) => task.id == updatedTask.id);
        if (taskIndex != -1) {
          tasks[taskIndex] = updatedTask;
        }
      }
    });

    try {
      await Future.wait(
        reordered.asMap().entries.map(
          (entry) => _client
              .from('items')
              .update({'order_index': entry.key})
              .eq('id', entry.value.id),
        ),
      );
    } catch (e) {
      debugPrint('Error reordering goal tasks: $e');
      _loadTasks();
    }
  }

  String _taskStatus(Item task) {
    if (task.status == 'done' || task.completed == true) return 'done';
    if (task.status == 'doing') return 'doing';
    return 'todo';
  }

  List<Item> _tasksForStatus(String status) {
    final filtered = tasks
        .where((task) => _taskStatus(task) == status)
        .toList();
    filtered.sort((a, b) => (a.orderIndex ?? 0).compareTo(b.orderIndex ?? 0));
    return filtered;
  }

  Future<void> _deleteTask(String taskId, String taskText) async {
    final confirm = await showDeleteBottomSheet(
      context,
      title: 'Delete Task?',
      subtitle: 'Delete "$taskText"? This cannot be undone.',
    );

    if (confirm != true) return;

    try {
      await _client.from('items').delete().eq('id', taskId);
      _loadTasks();
    } catch (e) {
      debugPrint('Error deleting task: $e');
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

  Future<void> _showEditTaskDialog(Item task) async {
    final textController = TextEditingController(text: task.text);
    String? dueDate = task.dueDate;
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text(
              'Edit Task',
              style: GoogleFonts.outfit(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    autofocus: true,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter task description',
                      hintStyle: const TextStyle(color: Colors.grey),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
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
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.outfit(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () {
                  final text = textController.text.trim();
                  if (text.isEmpty) return;
                  Navigator.pop(context, {'text': text, 'dueDate': dueDate});
                },
                child: Text(
                  'Save',
                  style: GoogleFonts.outfit(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result == null) return;
    final updatedText = result['text'];
    final updatedDueDate = result['dueDate'];
    if (updatedText == task.text.trim() && updatedDueDate == task.dueDate) {
      return;
    }

    try {
      await _client
          .from('items')
          .update({'text': updatedText, 'due_date': updatedDueDate})
          .eq('id', task.id);
      await _loadTasks();
    } catch (e) {
      debugPrint('Error editing task: $e');
    }
  }

  Future<void> _loadRelatedGoals() async {
    try {
      if (_currentRelatedIds.isEmpty) {
        setState(() => relatedGoals = []);
        return;
      }

      final active = await _goalsService.getActiveGoals();
      final longTerm = await _goalsService.getLongTermGoals();
      final allGoals = [...active, ...longTerm];

      setState(() {
        relatedGoals = allGoals
            .where((g) => _currentRelatedIds.contains(g.id))
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading related goals: $e');
    }
  }

  Future<void> _loadVisionBoards() async {
    try {
      if (_currentVisionBoardIds.isEmpty) {
        setState(() => visionBoards = []);
        return;
      }

      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _client
          .from('items')
          .select()
          .eq('user_id', userId)
          .eq('section', 'vision_boards')
          .inFilter('id', _currentVisionBoardIds);

      setState(() {
        visionBoards = response
            .map<Item>((json) => Item.fromJson(json))
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading vision boards: $e');
    }
  }

  Future<void> _showRelatedGoalsDialog() async {
    final active = await _goalsService.getActiveGoals();
    final longTerm = await _goalsService.getLongTermGoals();
    final allGoals = [...active, ...longTerm]
        .where((g) => g.id != widget.goal.id) // Exclude current goal
        .toList();

    final selectedIds = Set<String>.from(_currentRelatedIds);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text(
                'Link Related Goals',
                style: GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: allGoals.isEmpty
                    ? Text(
                        'No other goals available',
                        style: GoogleFonts.outfit(color: Colors.grey),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: allGoals.length,
                        itemBuilder: (context, index) {
                          final goal = allGoals[index];
                          final isSelected = selectedIds.contains(goal.id);
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (value) {
                              setDialogState(() {
                                if (value == true) {
                                  selectedIds.add(goal.id);
                                } else {
                                  selectedIds.remove(goal.id);
                                }
                              });
                            },
                            title: Text(
                              goal.text,
                              style: GoogleFonts.outfit(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              goal.category?.toUpperCase() ?? '',
                              style: GoogleFonts.outfit(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
                            ),
                            activeColor: Theme.of(context).colorScheme.primary,
                            checkColor: Theme.of(context).colorScheme.onPrimary,
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.outfit(color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      await _client
                          .from('items')
                          .update({'related_ids': selectedIds.toList()})
                          .eq('id', widget.goal.id);
                      // Update goal's relatedIds in memory
                      setState(() {
                        _currentRelatedIds = selectedIds.toList();
                      });
                      _loadRelatedGoals();
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      debugPrint('Error updating related goals: $e');
                    }
                  },
                  child: Text(
                    'Save',
                    style: GoogleFonts.outfit(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
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

  Future<void> _showVisionBoardsDialog() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final response = await _client
        .from('items')
        .select()
        .eq('user_id', userId)
        .eq('section', 'vision_boards')
        .order('created_at', ascending: false);

    final boards = response.map<Item>((json) => Item.fromJson(json)).toList();
    final selectedIds = Set<String>.from(_currentVisionBoardIds);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text(
                'Link Vision Boards',
                style: GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: boards.isEmpty
                    ? Text(
                        'No vision boards available',
                        style: GoogleFonts.outfit(color: Colors.grey),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: boards.length,
                        itemBuilder: (context, index) {
                          final board = boards[index];
                          final isSelected = selectedIds.contains(board.id);
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (value) {
                              setDialogState(() {
                                if (value == true) {
                                  selectedIds.add(board.id);
                                } else {
                                  selectedIds.remove(board.id);
                                }
                              });
                            },
                            title: Text(
                              board.text,
                              style: GoogleFonts.outfit(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            activeColor: Theme.of(context).colorScheme.primary,
                            checkColor: Theme.of(context).colorScheme.onPrimary,
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.outfit(color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      await _client
                          .from('items')
                          .update({
                            'related_vision_board_ids': selectedIds.toList(),
                          })
                          .eq('id', widget.goal.id);
                      // Update goal's vision board ids in memory
                      setState(() {
                        _currentVisionBoardIds = selectedIds.toList();
                      });
                      _loadVisionBoards();
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      debugPrint('Error updating vision boards: $e');
                    }
                  },
                  child: Text(
                    'Save',
                    style: GoogleFonts.outfit(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
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

  Future<void> _archiveGoal() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Archive Goal?',
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          'This will mark the goal as complete and move it to the Complete tab. All tasks will remain.',
          style: GoogleFonts.outfit(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Archive',
              style: GoogleFonts.outfit(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _goalsService.archiveGoal(widget.goal.id);
      if (mounted) {
        Navigator.pop(context); // Return to goals list
      }
    }
  }

  Future<void> _unarchiveGoal() async {
    try {
      await _client
          .from('items')
          .update({'archived': false})
          .eq('id', widget.goal.id);
      if (mounted) {
        Navigator.pop(context); // Return to goals list
      }
    } catch (e) {
      debugPrint('Error unarchiving goal: $e');
    }
  }

  Future<void> _deleteGoal() async {
    final confirm = await showDeleteBottomSheet(
      context,
      title: 'Delete Goal?',
      subtitle:
          'This action cannot be undone. All associated tasks will also be deleted.',
    );

    if (confirm == true) {
      // Delete all tasks first
      await _client.from('items').delete().eq('parent_id', widget.goal.id);

      // Delete the goal
      await _goalsService.deleteGoal(widget.goal.id);

      if (mounted) {
        Navigator.pop(context); // Return to goals list
      }
    }
  }

  Future<void> _editGoalDialog() async {
    final textController = TextEditingController(text: _currentGoalText);
    final whyController = TextEditingController(text: _currentGoalWhy ?? '');
    final specificController = TextEditingController(
      text: _currentGoalSpecific ?? '',
    );
    final measurableController = TextEditingController(
      text: _currentGoalMeasurable ?? '',
    );
    final achievableController = TextEditingController(
      text: _currentGoalAchievable ?? '',
    );
    final relevantController = TextEditingController(
      text: _currentGoalRelevant ?? '',
    );
    final costController = TextEditingController(
      text: _currentGoalCostEstimate == null
          ? ''
          : _formatNumberWithThousands(_currentGoalCostEstimate!),
    );
    String selectedCategory = _currentGoalCategory ?? 'health';
    String selectedType = _currentGoalType ?? 'desire';
    String selectedStatus = _currentGoalSection == 'longTermGoals'
        ? 'inactive'
        : 'active';
    bool isPrimary = _currentGoalIsPrimary;
    String? startDate = _currentGoalStartDate;
    String? dueDate = _currentGoalDueDate;
    String selectedCostType = _currentGoalCostType ?? 'one-time';
    bool isSaving = false;
    int currentStep = 0;

    final categories = [
      {'id': 'health', 'label': 'Health', 'icon': Icons.favorite},
      {'id': 'wealth', 'label': 'Wealth', 'icon': Icons.attach_money},
      {'id': 'relationships', 'label': 'Relationships', 'icon': Icons.people},
      {'id': 'experiences', 'label': 'Experiences', 'icon': Icons.explore},
      {'id': 'objects', 'label': 'Objects', 'icon': Icons.inventory_2},
    ];

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return SizedBox.expand(
              child: AlertDialog(
                backgroundColor: Theme.of(context).colorScheme.surface,
                surfaceTintColor: Colors.transparent,
                insetPadding: EdgeInsets.zero,
                constraints: BoxConstraints.tight(
                  Size(
                    MediaQuery.sizeOf(context).width,
                    MediaQuery.sizeOf(context).height -
                        MediaQuery.paddingOf(context).vertical,
                  ),
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                clipBehavior: Clip.antiAlias,
                titlePadding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
                contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Edit Goal',
                        style: GoogleFonts.outfit(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: isSaving
                          ? null
                          : () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                content: SizedBox.expand(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                switch (currentStep) {
                                  0 => 'Goal & motivation',
                                  1 => 'SMART breakdown',
                                  _ => 'Category & cost',
                                },
                                style: GoogleFonts.outfit(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              'Step ${currentStep + 1} of 3',
                              style: GoogleFonts.outfit(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(150),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: (currentStep + 1) / 3,
                          minHeight: 3,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        SizedBox(height: currentStep == 2 ? 12 : 20),
                        if (currentStep == 0) ...[
                          TextField(
                            controller: textController,
                            onChanged: (_) => setDialogState(() {}),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Goal Text',
                              labelStyle: TextStyle(color: Colors.grey),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: whyController,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Why is this important?',
                              labelStyle: TextStyle(color: Colors.grey),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Status',
                            style: GoogleFonts.outfit(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment<String>(
                                value: 'active',
                                label: Text('Active'),
                                icon: Icon(Icons.adjust),
                              ),
                              ButtonSegment<String>(
                                value: 'inactive',
                                label: Text('Inactive'),
                                icon: Icon(Icons.pause_circle_outline),
                              ),
                            ],
                            selected: {selectedStatus},
                            showSelectedIcon: false,
                            onSelectionChanged: (selection) {
                              setDialogState(() {
                                selectedStatus = selection.first;
                                if (selectedStatus == 'inactive') {
                                  isPrimary = false;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            title: Text(
                              'Primary Focus',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              selectedStatus == 'active'
                                  ? 'Feature this goal at the top of your active goals.'
                                  : 'Primary Focus is only available for active goals.',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(140),
                              ),
                            ),
                            value: isPrimary,
                            onChanged: selectedStatus == 'active'
                                ? (value) =>
                                      setDialogState(() => isPrimary = value)
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Dates',
                            style: GoogleFonts.outfit(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDateButton(
                                  context,
                                  label: 'Start Date',
                                  value: startDate,
                                  onChanged: (value) =>
                                      setDialogState(() => startDate = value),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDateButton(
                                  context,
                                  label: 'Due Date',
                                  value: dueDate,
                                  onChanged: (value) =>
                                      setDialogState(() => dueDate = value),
                                ),
                              ),
                            ],
                          ),
                        ] else if (currentStep == 1) ...[
                          SmartGoalFields(
                            specificController: specificController,
                            measurableController: measurableController,
                            achievableController: achievableController,
                            relevantController: relevantController,
                            initiallyExpanded: true,
                            collapsible: false,
                          ),
                        ] else ...[
                          Text(
                            'Category',
                            style: GoogleFonts.outfit(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: categories
                                .where((c) => c['id'] != 'all')
                                .map((category) {
                                  final isSelected =
                                      selectedCategory == category['id'];
                                  return GestureDetector(
                                    onTap: () {
                                      setDialogState(() {
                                        selectedCategory =
                                            category['id'] as String;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withAlpha(50)
                                            : Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isSelected
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : Colors.transparent,
                                        ),
                                      ),
                                      child: Text(
                                        category['label'] as String,
                                        style: GoogleFonts.outfit(
                                          color: isSelected
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withAlpha(150),
                                          fontSize: 12,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  );
                                })
                                .toList(),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Type',
                            style: GoogleFonts.outfit(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTypeChip(
                                  label: 'Need',
                                  value: 'need',
                                  selected: selectedType,
                                  selectedColor: Colors.amber,
                                  onSelect: (value) => setDialogState(
                                    () => selectedType = value,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTypeChip(
                                  label: 'Desire',
                                  value: 'desire',
                                  selected: selectedType,
                                  selectedColor: Colors.purpleAccent,
                                  onSelect: (value) => setDialogState(
                                    () => selectedType = value,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTypeChip(
                                  label: 'Asset',
                                  value: 'asset',
                                  selected: selectedType,
                                  selectedColor: _goalTypeColor('asset'),
                                  onSelect: (value) => setDialogState(
                                    () => selectedType = value,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTypeChip(
                                  label: 'Liability',
                                  value: 'liability',
                                  selected: selectedType,
                                  selectedColor: _goalTypeColor('liability'),
                                  onSelect: (value) => setDialogState(
                                    () => selectedType = value,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Estimated Cost',
                            style: GoogleFonts.outfit(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: costController,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9,.]'),
                                    ),
                                  ],
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Amount',
                                    prefixText: '\$ ',
                                    isDense: true,
                                    filled: true,
                                    fillColor: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withAlpha(70),
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.always,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                    labelStyle: const TextStyle(
                                      color: Colors.grey,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: selectedCostType,
                                  isExpanded: true,
                                  dropdownColor: Theme.of(
                                    context,
                                  ).colorScheme.surface,
                                  decoration: InputDecoration(
                                    labelText: 'Frequency',
                                    isDense: true,
                                    filled: true,
                                    fillColor: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withAlpha(70),
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.always,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  style: GoogleFonts.outfit(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'one-time',
                                      child: Text('Once'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'monthly',
                                      child: Text('Monthly'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'annual',
                                      child: Text('Yearly'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setDialogState(
                                        () => selectedCostType = value,
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  if (currentStep > 0)
                    TextButton(
                      onPressed: isSaving
                          ? null
                          : () => setDialogState(
                              () => currentStep = currentStep - 1,
                            ),
                      child: Text(
                        'Back',
                        style: GoogleFonts.outfit(color: Colors.grey),
                      ),
                    ),
                  TextButton(
                    onPressed:
                        isSaving ||
                            (currentStep == 0 &&
                                textController.text.trim().isEmpty)
                        ? null
                        : currentStep < 2
                        ? () => setDialogState(
                            () => currentStep = currentStep + 1,
                          )
                        : () async {
                            if (textController.text.trim().isEmpty) return;
                            setDialogState(() => isSaving = true);

                            try {
                              final parsedCost =
                                  costController.text.trim().isEmpty
                                  ? null
                                  : double.tryParse(
                                      costController.text.trim().replaceAll(
                                        ',',
                                        '',
                                      ),
                                    );
                              final updatedGoal = Goal(
                                id: _currentGoal.id,
                                text: textController.text.trim(),
                                userId: _currentGoal.userId,
                                section: selectedStatus == 'active'
                                    ? 'activeGoals'
                                    : 'longTermGoals',
                                category: selectedCategory,
                                parentId: _currentGoal.parentId,
                                completed: _currentGoal.completed,
                                archived: _currentGoal.archived,
                                orderIndex: _currentGoal.orderIndex,
                                dueDate: dueDate,
                                startDate: startDate,
                                value: _currentGoal.value,
                                goalType: selectedType,
                                why: whyController.text.trim().isEmpty
                                    ? null
                                    : whyController.text.trim(),
                                isPrimary:
                                    selectedStatus == 'active' && isPrimary,
                                costEstimate: parsedCost,
                                costType: selectedCostType,
                                relatedIds: _currentRelatedIds,
                                relatedVisionBoardIds: _currentVisionBoardIds,
                                specific: specificController.text.trim().isEmpty
                                    ? null
                                    : specificController.text.trim(),
                                measurable:
                                    measurableController.text.trim().isEmpty
                                    ? null
                                    : measurableController.text.trim(),
                                achievable:
                                    achievableController.text.trim().isEmpty
                                    ? null
                                    : achievableController.text.trim(),
                                relevant: relevantController.text.trim().isEmpty
                                    ? null
                                    : relevantController.text.trim(),
                              );

                              final updates = {
                                'text': updatedGoal.text,
                                'section': updatedGoal.section,
                                'category': updatedGoal.category,
                                'due_date': updatedGoal.dueDate,
                                'start_date': updatedGoal.startDate,
                                'goal_type': updatedGoal.goalType,
                                'why': updatedGoal.why,
                                'is_primary': updatedGoal.isPrimary,
                                'cost_estimate': updatedGoal.costEstimate,
                                'cost_type': updatedGoal.costType,
                                'specific': updatedGoal.specific,
                                'measurable': updatedGoal.measurable,
                                'achievable': updatedGoal.achievable,
                                'relevant': updatedGoal.relevant,
                              };
                              final saved = await _goalsService
                                  .updateGoalFields(updatedGoal.id, updates);
                              if (!saved) {
                                if (!context.mounted) return;
                                setDialogState(() => isSaving = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Could not save goal changes',
                                    ),
                                  ),
                                );
                                return;
                              }

                              if (!mounted || !dialogContext.mounted) return;
                              setState(() {
                                _currentGoal = updatedGoal;
                                _syncCurrentGoalState();
                              });

                              final dialogRoute = ModalRoute.of(dialogContext);
                              if (dialogRoute?.isCurrent == true) {
                                Navigator.of(dialogContext).pop();
                              }
                            } catch (e) {
                              debugPrint('Error updating goal: $e');
                              if (context.mounted) {
                                setDialogState(() => isSaving = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Could not save goal changes',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            currentStep < 2 ? 'Next' : 'Save',
                            style: GoogleFonts.outfit(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTypeChip({
    required String label,
    required String value,
    required String selected,
    required Color selectedColor,
    required ValueChanged<String> onSelect,
  }) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withAlpha(50)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? selectedColor : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: isSelected
                ? selectedColor
                : Theme.of(context).colorScheme.onSurface.withAlpha(150),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDateButton(
    BuildContext context, {
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayValue = value == null || value.isEmpty ? label : value;
    return InkWell(
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
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outline.withAlpha(45)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayValue,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  color: value == null || value.isEmpty
                      ? colorScheme.onSurface.withAlpha(150)
                      : colorScheme.onSurface,
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
                  color: colorScheme.onSurface.withAlpha(120),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _goalTypeColor(String goalType) {
    switch (goalType) {
      case 'need':
        return Colors.amber;
      case 'asset':
        return const Color(0xFF10B981);
      case 'liability':
        return const Color(0xFFEF4444);
      case 'desire':
      default:
        return Colors.purpleAccent;
    }
  }

  String _costTypeLabel(String? costType) {
    switch (costType) {
      case 'monthly':
        return '/mo';
      case 'annual':
        return '/yr';
      case 'one-time':
      default:
        return 'once';
    }
  }

  String _formatNumberWithThousands(double amount) {
    final fixed = amount % 1 == 0
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts.first;
    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      final remaining = whole.length - i;
      buffer.write(whole[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }
    return parts.length == 1
        ? buffer.toString()
        : '${buffer.toString()}.${parts.last}';
  }

  Widget _buildDetailPill(IconData icon, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(180),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outline.withAlpha(35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: colorScheme.onSurface.withAlpha(190),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartGoalSummary() {
    final parts = [
      (
        letter: 'S',
        label: 'Specific',
        value: _currentGoalSpecific,
        prompt: 'Describe the exact outcome.',
      ),
      (
        letter: 'M',
        label: 'Measurable',
        value: _currentGoalMeasurable,
        prompt: 'Add a measure of progress or success.',
      ),
      (
        letter: 'A',
        label: 'Achievable',
        value: _currentGoalAchievable,
        prompt: 'Explain why this is realistic.',
      ),
      (
        letter: 'R',
        label: 'Relevant',
        value: _currentGoalRelevant,
        prompt: 'Connect it to what matters to you.',
      ),
      (
        letter: 'T',
        label: 'Time-bound',
        value: _currentGoalDueDate,
        prompt: 'Add a due date.',
      ),
    ];
    final completedParts = parts
        .where((part) => part.value != null && part.value!.trim().isNotEmpty)
        .length;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withAlpha(35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SMART GOAL',
                      style: GoogleFonts.outfit(
                        color: colorScheme.onSurface.withAlpha(170),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$completedParts of 5 parts complete',
                      style: GoogleFonts.outfit(
                        color: colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _editGoalDialog,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: completedParts / parts.length,
              minHeight: 6,
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 12),
          ...parts.map((part) {
            final isComplete =
                part.value != null && part.value!.trim().isNotEmpty;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isComplete
                        ? colorScheme.primary.withAlpha(30)
                        : colorScheme.surfaceContainerHighest,
                    child: Text(
                      part.letter,
                      style: GoogleFonts.outfit(
                        color: isComplete
                            ? colorScheme.primary
                            : colorScheme.onSurface.withAlpha(110),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          part.label,
                          style: GoogleFonts.outfit(
                            color: colorScheme.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isComplete ? part.value! : part.prompt,
                          style: GoogleFonts.outfit(
                            color: colorScheme.onSurface.withAlpha(
                              isComplete ? 180 : 110,
                            ),
                            fontSize: 13,
                            fontStyle: isComplete
                                ? FontStyle.normal
                                : FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isComplete
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 18,
                    color: isComplete
                        ? colorScheme.primary
                        : colorScheme.onSurface.withAlpha(80),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _showAddTaskDialog({String? status}) async {
    final textController = TextEditingController();
    final targetStatus = status ?? _statusForTab(_taskTabController.index);
    String? dueDate;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text(
              'Add Task',
              style: GoogleFonts.outfit(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter task description',
                      hintStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
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
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.outfit(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (textController.text.isNotEmpty) {
                    _addTask(
                      textController.text,
                      status: targetStatus,
                      dueDate: dueDate,
                    );
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  'Add',
                  style: GoogleFonts.outfit(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _statusForTab(int index) {
    switch (index) {
      case 1:
        return 'doing';
      case 2:
        return 'done';
      case 0:
      default:
        return 'todo';
    }
  }

  Widget _buildTaskStageTab(String label, List<Item> stageTasks, Color color) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withAlpha(45),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${stageTasks.length}',
              style: GoogleFonts.outfit(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalTaskStageList(
    List<Item> stageTasks,
    String status,
    Color accentColor,
  ) {
    if (stageTasks.isEmpty) {
      return Container(
        key: ValueKey('empty-$status'),
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.fact_check_outlined, size: 48, color: Colors.grey[800]),
            const SizedBox(height: 12),
            Text(
              'No tasks yet',
              style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Add a task or move one into this stage',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      key: ValueKey('tasks-$status'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: stageTasks.length,
      onReorderItem: (oldIndex, newIndex) =>
          _reorderGoalTasks(status, oldIndex, newIndex),
      itemBuilder: (context, index) {
        final task = stageTasks[index];
        return _buildInlineTaskCard(
          key: ValueKey(task.id),
          task: task,
          accentColor: accentColor,
          index: index,
        );
      },
    );
  }

  Widget _buildInlineTaskCard({
    required Key key,
    required Item task,
    required Color accentColor,
    required int index,
  }) {
    final isDone = _taskStatus(task) == 'done';
    return GestureDetector(
      key: key,
      onLongPress: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                TaskBoardPage(goal: widget.goal, parentTask: task),
          ),
        ).then((_) => _loadData());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withAlpha(55)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
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
                  GestureDetector(
                    onTap: () => _toggleTask(task),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDone
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(50),
                          width: 2,
                        ),
                        color: isDone
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                      ),
                      child: isDone
                          ? Icon(
                              Icons.check,
                              size: 16,
                              color: Theme.of(context).colorScheme.onPrimary,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.text,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: isDone
                                ? Colors.grey[600]
                                : Theme.of(context).colorScheme.onSurface,
                            decoration: isDone
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
                  IconButton(
                    onPressed: () => _showGoalTaskOptions(task),
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'Task Options',
                    visualDensity: VisualDensity.compact,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(160),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showGoalTaskOptions(Item task) async {
    final currentStatus = _taskStatus(task);
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                task.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.calendar_today_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                task.dueDate == null || task.dueDate!.isEmpty
                    ? 'Set Due Date'
                    : 'Change Due Date',
              ),
              onTap: () => Navigator.pop(sheetContext, 'due-date'),
            ),
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: Color(0xFF10B981),
              ),
              title: const Text('Edit Task'),
              onTap: () => Navigator.pop(sheetContext, 'edit'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'MOVE TO',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(130),
                  ),
                ),
              ),
            ),
            if (currentStatus != 'todo')
              ListTile(
                leading: const Icon(Icons.list_alt_outlined),
                title: const Text('To Do'),
                onTap: () => Navigator.pop(sheetContext, 'todo'),
              ),
            if (currentStatus != 'doing')
              ListTile(
                leading: const Icon(
                  Icons.pending_actions_outlined,
                  color: Colors.amber,
                ),
                title: const Text('Doing'),
                onTap: () => Navigator.pop(sheetContext, 'doing'),
              ),
            if (currentStatus != 'done')
              ListTile(
                leading: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                ),
                title: const Text('Done'),
                onTap: () => Navigator.pop(sheetContext, 'done'),
              ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Color(0xFFEF4444),
              ),
              title: Text(
                'Delete Task',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFEF4444),
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => Navigator.pop(sheetContext, 'delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;
    switch (action) {
      case 'due-date':
        await _pickTaskDueDate(task);
      case 'edit':
        await _showEditTaskDialog(task);
      case 'todo':
      case 'doing':
      case 'done':
        await _updateTaskStatus(task, action);
      case 'delete':
        await _deleteTask(task.id, task.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final todoTasks = _tasksForStatus('todo');
    final doingTasks = _tasksForStatus('doing');
    final doneTasks = _tasksForStatus('done');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Goal Details',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
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
            tooltip: 'Goal walkthrough',
            onPressed: _showGoalDetailWalkthrough,
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            color: Theme.of(context).colorScheme.surface,
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editGoalDialog();
                  break;
                case 'archive':
                  _archiveGoal();
                  break;
                case 'unarchive':
                  _unarchiveGoal();
                  break;
                case 'delete':
                  _deleteGoal();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit, size: 18, color: Colors.blueAccent),
                    const SizedBox(width: 8),
                    Text(
                      'Edit Goal',
                      style: GoogleFonts.outfit(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.goal.archived != true)
                PopupMenuItem(
                  value: 'archive',
                  child: Row(
                    children: [
                      Icon(
                        Icons.archive,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Archive Goal',
                        style: GoogleFonts.outfit(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                )
              else
                PopupMenuItem(
                  value: 'unarchive',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.unarchive,
                        size: 18,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Unarchive Goal',
                        style: GoogleFonts.outfit(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, size: 18, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      'Delete Goal',
                      style: GoogleFonts.outfit(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: AbleriteLoadingIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Goal Card
                  Container(
                    key: _goalSummaryKey,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withAlpha(50),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (_currentGoalIsPrimary)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withAlpha(40),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 12,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'PRIMARY',
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const Spacer(),
                            if (_currentGoalType != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _goalTypeColor(
                                    _currentGoalType!,
                                  ).withAlpha(40),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _currentGoalType!.toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _goalTypeColor(_currentGoalType!),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _currentGoalText,
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (_currentGoalCategory != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _currentGoalCategory!.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.grey[600],
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                        if (_currentGoalStartDate != null ||
                            _currentGoalDueDate != null ||
                            _currentGoalCostEstimate != null) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (_currentGoalStartDate != null)
                                _buildDetailPill(
                                  Icons.play_arrow_rounded,
                                  'Start ${_currentGoalStartDate!}',
                                ),
                              if (_currentGoalDueDate != null)
                                _buildDetailPill(
                                  Icons.flag_rounded,
                                  'Due ${_currentGoalDueDate!}',
                                ),
                              if (_currentGoalCostEstimate != null)
                                _buildDetailPill(
                                  Icons.payments_outlined,
                                  '\$${_formatNumberWithThousands(_currentGoalCostEstimate!)} ${_costTypeLabel(_currentGoalCostType)}',
                                ),
                            ],
                          ),
                        ],
                        if (_currentGoalWhy != null &&
                            _currentGoalWhy!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withAlpha(40),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'WHY THIS MATTERS',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _currentGoalWhy!,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSmartGoalSummary(),
                  const SizedBox(height: 24),

                  // Related Goals and Vision Boards Unified Section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Related Goals (Left Side)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RELATED GOALS',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ...relatedGoals.map(
                                  (g) => GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              GoalDetailPage(goal: g),
                                        ),
                                      ).then((_) => _loadData());
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary.withAlpha(50),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.flag,
                                            size: 14,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withAlpha(200),
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              g.text,
                                              style: GoogleFonts.outfit(
                                                fontSize: 12,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _showRelatedGoalsDialog,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary.withAlpha(30),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary.withAlpha(50),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.add,
                                          size: 14,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Link Goal',
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Vision Boards (Right Side)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LINKED VISION BOARDS',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ...visionBoards.map(
                                  (board) => GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => VisionPage(
                                            initialBoardId: board.id,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.purpleAccent.withAlpha(
                                            50,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.image,
                                            size: 14,
                                            color: Colors.purpleAccent,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              board.text,
                                              style: GoogleFonts.outfit(
                                                fontSize: 12,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _showVisionBoardsDialog,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.purpleAccent.withAlpha(30),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.purpleAccent.withAlpha(
                                          50,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.add,
                                          size: 14,
                                          color: Colors.purpleAccent,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Link Board',
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            color: Colors.purpleAccent
                                                .withAlpha(200),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Tasks Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TASKS',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                          letterSpacing: 1.2,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            key: _taskBoardKey,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TaskBoardPage(goal: widget.goal),
                                ),
                              ).then((_) => _loadData());
                            },
                            icon: const Icon(
                              Icons.dashboard_outlined,
                              size: 18,
                              color: Colors.amber,
                            ),
                            tooltip: 'View as Board',
                          ),
                          ElevatedButton.icon(
                            key: _addTaskKey,
                            onPressed: () => _showAddTaskDialog(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.add, size: 16),
                            label: Text(
                              'Add Task',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Container(
                    key: _taskTabsKey,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _taskTabController,
                      indicatorColor: Theme.of(context).colorScheme.primary,
                      labelColor: Theme.of(context).colorScheme.primary,
                      unselectedLabelColor: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(150),
                      labelStyle: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      tabs: [
                        _buildTaskStageTab(
                          'TO DO',
                          todoTasks,
                          Theme.of(context).colorScheme.primary,
                        ),
                        _buildTaskStageTab('DOING', doingTasks, Colors.amber),
                        _buildTaskStageTab(
                          'DONE',
                          doneTasks,
                          Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  KeyedSubtree(
                    key: _taskListKey,
                    child: AnimatedBuilder(
                      animation: _taskTabController,
                      builder: (context, _) {
                        final status = _statusForTab(_taskTabController.index);
                        final stageTasks = switch (status) {
                          'doing' => doingTasks,
                          'done' => doneTasks,
                          _ => todoTasks,
                        };
                        final accentColor = status == 'doing'
                            ? Colors.amber
                            : Theme.of(context).colorScheme.primary;
                        return _buildGoalTaskStageList(
                          stageTasks,
                          status,
                          accentColor,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
