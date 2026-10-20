import 'package:flutter/material.dart';
import 'widgets/ablerite_loading_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/focus_app_bar_actions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/goal.dart';
import '../models/item.dart';
import '../services/navigation_service.dart';
import 'widgets/confirmation_dialog.dart';

class TodoPage extends StatefulWidget {
  final String? initialBoardId;
  final String? initialListId;
  final String? initialTaskId;

  const TodoPage({
    super.key,
    this.initialBoardId,
    this.initialListId,
    this.initialTaskId,
  });

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TaskList {
  final String id;
  final String title;
  _TaskList({required this.id, required this.title});
}

class _Board {
  final String id;
  final String title;
  final List<_TaskList> lists;
  final int sortOrder;
  _Board({
    required this.id,
    required this.title,
    required this.lists,
    this.sortOrder = 0,
  });
}

class _TaskDestination {
  final _Board board;
  final _TaskList list;

  const _TaskDestination({required this.board, required this.list});
}

class _TodoPageState extends State<TodoPage> {
  List<Item> _allTasks = [];
  List<_Board> _boards = [];
  String? _selectedBoardId;
  String? _selectedListId;
  String _statusFilter = 'active'; // 'active' or 'complete'
  bool _isLoading = true;
  bool _hasSnappedToInitialTask = false;
  String? _highlightedTaskId;
  final Map<String, _TaskLocation> _taskLocations = {};

  final ScrollController _boardScrollController = ScrollController();
  final ScrollController _listScrollController = ScrollController();
  final ScrollController _taskScrollController = ScrollController();
  final Map<String, GlobalKey> _boardKeys = {};
  final Map<String, GlobalKey> _listKeys = {};
  final Map<String, GlobalKey> _taskKeys = {};

  @override
  void initState() {
    super.initState();
    pushPage();
    _fetchTasks();
  }

  @override
  void dispose() {
    _boardScrollController.dispose();
    _listScrollController.dispose();
    _taskScrollController.dispose();
    popPage();
    super.dispose();
  }

  void _snapToTask(String taskId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final taskIndex = _filteredTasks.indexWhere((task) => task.id == taskId);
      if (taskIndex < 0 || !_taskScrollController.hasClients) return;

      final position = _taskScrollController.position;
      final estimatedOffset = (taskIndex * 148.0).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      _taskScrollController.jumpTo(estimatedOffset);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final taskContext = _taskKeys[taskId]?.currentContext;
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

  void _highlightAndSnapToTask(Item task) {
    final location = _taskLocations[task.id];
    if (location == null) return;
    setState(() {
      _selectedBoardId = location.boardId;
      _selectedListId = location.listId;
      _statusFilter = task.completed == true ? 'complete' : 'active';
      _highlightedTaskId = task.id;
    });
    _snapToTask(task.id);
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted && _highlightedTaskId == task.id) {
        setState(() => _highlightedTaskId = null);
      }
    });
  }

  Future<void> _fetchTasks() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final boardsResponse = await Supabase.instance.client
          .from('task_boards')
          .select()
          .eq('user_id', userId)
          .order('sort_order', ascending: true);

      final List<Item> loadedTasks = [];
      final List<_Board> loadedBoards = [];
      _taskLocations.clear();

      for (final board in boardsResponse) {
        // Use board_id (logical ID from desktop) instead of id (DB primary key)
        final boardId = board['board_id'] ?? board['id'];
        final boardTitle = board['title'] ?? 'Board';
        final listsData = board['lists'] as List? ?? [];

        final List<_TaskList> boardLists = [];

        for (final list in listsData) {
          final listId = list['id'];
          final listTitle = list['title'] ?? 'List';
          boardLists.add(_TaskList(id: listId, title: listTitle));

          final tasksJson = list['tasks'] as List? ?? [];

          for (final t in tasksJson) {
            final taskId = t['id']?.toString() ?? DateTime.now().toString();

            final item = Item(
              id: taskId,
              text: t['content'] ?? '',
              completed: t['completed'] ?? false,
              status: t['status'],
              section: boardTitle,
              userId: userId,
              boardId: boardId,
              listId: listId,
              // Desktop (FreeformBoards.tsx) stores this JSON blob field as
              // camelCase 'dueDate'; fall back to legacy 'due_date' for any
              // rows written before this fix.
              dueDate: t['dueDate'] ?? t['due_date'],
            );

            loadedTasks.add(item);

            _taskLocations[taskId] = _TaskLocation(
              boardId: boardId,
              listId: listId,
              taskId: taskId,
              fullBoardData: board,
            );
          }
        }

        loadedBoards.add(
          _Board(
            id: boardId,
            title: boardTitle,
            lists: boardLists,
            sortOrder: board['sort_order'] ?? 0,
          ),
        );
      }

      // Ensure Quick Tasks board always exists
      final hasQuickTasksBoard = loadedBoards.any(
        (b) => b.id == 'quick-tasks-board',
      );
      if (!hasQuickTasksBoard) {
        const quickTasksBoardId = 'quick-tasks-board';
        const defaultListId = 'quick-tasks-default-list';
        try {
          await Supabase.instance.client.from('task_boards').insert({
            'board_id': quickTasksBoardId,
            'user_id': userId,
            'title': 'Quick Tasks',
            'sort_order': -1,
            'lists': [
              {'id': defaultListId, 'title': 'My Tasks', 'tasks': []},
            ],
          });
        } catch (_) {
          // Board may already exist under a different id — just add locally
        }
        loadedBoards.insert(
          0,
          _Board(
            id: quickTasksBoardId,
            title: 'Quick Tasks',
            lists: [_TaskList(id: defaultListId, title: 'My Tasks')],
            sortOrder: -1,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _allTasks = loadedTasks;
          // Pin Quick Tasks board first, then sort by sort_order
          loadedBoards.sort((a, b) {
            if (a.id == 'quick-tasks-board') return -1;
            if (b.id == 'quick-tasks-board') return 1;
            return a.sortOrder.compareTo(b.sortOrder);
          });
          _boards = loadedBoards;

          if (_selectedListId == null && _boards.isNotEmpty) {
            _Board targetBoard = _boards.firstWhere(
              (b) => b.id == widget.initialBoardId,
              orElse: () => _boards.firstWhere(
                (b) => b.id == 'quick-tasks-board',
                orElse: () => _boards.first,
              ),
            );

            _selectedBoardId = targetBoard.id;
            if (widget.initialListId != null &&
                targetBoard.lists.any((l) => l.id == widget.initialListId)) {
              _selectedListId = widget.initialListId;
            } else if (targetBoard.lists.isNotEmpty) {
              _selectedListId = targetBoard.lists.first.id;
            }
          }

          _isLoading = false;
        });

        if (!_hasSnappedToInitialTask && widget.initialTaskId != null) {
          final task = _allTasks
              .where((t) => t.id == widget.initialTaskId)
              .toList();
          if (task.isNotEmpty) {
            _hasSnappedToInitialTask = true;
            _highlightAndSnapToTask(task.first);
          }
        }
      }
    } catch (error, stackTrace) {
      if (mounted) {
        debugPrint('Error loading tasks: $error');
        debugPrint('$stackTrace');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading tasks: $error')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleTask(Item task) async {
    final location = _taskLocations[task.id];
    if (location == null) return;

    try {
      setState(() {
        final index = _allTasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _allTasks[index] = Item(
            id: task.id,
            text: task.text,
            completed: !(task.completed ?? false),
            status: !(task.completed ?? false) ? 'done' : 'todo',
            section: task.section,
            userId: task.userId,
            orderIndex: task.orderIndex,
            boardId: task.boardId,
            listId: task.listId,
          );
        }
      });

      final boardData = location.fullBoardData;
      final lists = boardData['lists'] as List;
      for (var list in lists) {
        if (list['id'] == location.listId) {
          final tasks = list['tasks'] as List;
          for (var t in tasks) {
            if (t['id'].toString() == location.taskId) {
              t['completed'] = !(task.completed ?? false);
              t['status'] = !(task.completed ?? false) ? 'done' : 'todo';
              break;
            }
          }
          break;
        }
      }

      await Supabase.instance.client
          .from('task_boards')
          .update({'lists': lists})
          .eq('board_id', location.boardId);
    } catch (error) {
      _fetchTasks();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error updating task')));
      }
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

  Future<void> _addTask() async {
    if (_selectedListId == null || _selectedBoardId == null) return;

    final textController = TextEditingController();
    List<Goal> availableGoals = [];
    Set<String> selectedGoalIds = {};
    String? dueDate;
    bool isLoadingGoals = true;

    // Fetch goals when the dialog opens
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final goalsResponse = await Supabase.instance.client
            .from('items')
            .select()
            .eq('user_id', userId)
            .inFilter('section', ['activeGoals', 'longTermGoals'])
            .neq('status', 'deleted')
            .neq('status', 'trashed');

        availableGoals = goalsResponse.map((g) => Goal.fromJson(g)).toList();
      }
    } catch (e) {
      debugPrint('Error loading goals: $e');
    }
    isLoadingGoals = false;

    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (dialogContext) {
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
                        style: GoogleFonts.outfit(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Enter task description',
                          hintStyle: GoogleFonts.outfit(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(150),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(50),
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
                          iconColor: Colors.grey,
                          collapsedIconColor: Colors.grey,
                          title: Text(
                            'Link Goals',
                            style: GoogleFonts.outfit(color: Colors.grey),
                          ),
                          children: [
                            if (isLoadingGoals)
                              Padding(
                                padding: EdgeInsets.all(16.0),
                                child: AbleriteLoadingIndicator(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              )
                            else if (availableGoals.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  "No goals found",
                                  style: GoogleFonts.outfit(color: Colors.grey),
                                ),
                              )
                            else
                              ...availableGoals.map((Goal goal) {
                                return CheckboxListTile(
                                  title: Text(
                                    goal.text,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                    ),
                                  ),
                                  value: selectedGoalIds.contains(goal.id),
                                  activeColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  checkColor: Colors.black,
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
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.outfit(color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    if (textController.text.isEmpty) return;

                    try {
                      final res = await Supabase.instance.client
                          .from('task_boards')
                          .select()
                          .eq('board_id', _selectedBoardId!)
                          .single();

                      final currentLists = List.from(res['lists'] ?? []);

                      for (var list in currentLists) {
                        if (list['id'] == _selectedListId) {
                          final tasks = List.from(list['tasks'] ?? []);
                          tasks.add({
                            'id': const Uuid().v4(),
                            'content': textController.text,
                            'completed': false,
                            'status': 'todo',
                            'dueDate': dueDate,
                            if (selectedGoalIds.isNotEmpty)
                              'related_ids': selectedGoalIds.toList(),
                          });
                          list['tasks'] = tasks;
                          break;
                        }
                      }

                      await Supabase.instance.client
                          .from('task_boards')
                          .update({'lists': currentLists})
                          .eq('board_id', _selectedBoardId!);

                      if (context.mounted) Navigator.pop(dialogContext);
                      _fetchTasks();
                    } catch (e) {
                      debugPrint('Error adding task: $e');
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

  Future<void> _createBoard() async {
    final titleController = TextEditingController();
    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'New Board',
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: TextField(
          controller: titleController,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Board Name',
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor.withAlpha(50),
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
              'Create',
              style: GoogleFonts.outfit(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldCreate == true && titleController.text.isNotEmpty) {
      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId == null) return;

        final newId = const Uuid().v4();

        // Get max sort_order to place new board at the end
        final maxSortOrder = _boards.isEmpty
            ? 0
            : _boards.map((b) => b.sortOrder).reduce((a, b) => a > b ? a : b);

        await Supabase.instance.client.from('task_boards').insert({
          'id': newId,
          'board_id': newId,
          'user_id': userId,
          'title': titleController.text,
          'lists': [],
          'sort_order': maxSortOrder + 1,
        });

        _fetchTasks();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error creating board: $e')));
        }
      }
    }
  }

  Future<void> _createList(String boardId) async {
    final titleController = TextEditingController();
    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('New List', style: GoogleFonts.outfit(color: Colors.white)),
        content: TextField(
          controller: titleController,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'List Name',
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor.withAlpha(50),
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
              'Create',
              style: GoogleFonts.outfit(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldCreate == true && titleController.text.isNotEmpty) {
      try {
        final res = await Supabase.instance.client
            .from('task_boards')
            .select()
            .eq('board_id', boardId)
            .single();
        final currentLists = List.from(res['lists'] ?? []);

        final newListId = DateTime.now().millisecondsSinceEpoch.toString();
        currentLists.add({
          'id': newListId,
          'title': titleController.text,
          'tasks': [],
        });

        await Supabase.instance.client
            .from('task_boards')
            .update({'lists': currentLists})
            .eq('board_id', boardId);

        // Auto-select the newly created list
        _selectedBoardId = boardId;
        _selectedListId = newListId;
        _fetchTasks();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error creating list: $e')));
        }
      }
    }
  }

  void _showBoardOptions(_Board board) {
    if (board.id == 'quick-tasks-board') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot edit or delete the Quick Tasks board.'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.edit_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  'Edit Board',
                  style: GoogleFonts.outfit(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _editBoardDialog(board);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                title: Text(
                  'Delete Board',
                  style: GoogleFonts.outfit(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteBoard(board);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editBoardDialog(_Board board) async {
    final textController = TextEditingController(text: board.title);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'Edit Board',
            style: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: TextField(
            controller: textController,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Board Name',
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).dividerColor.withAlpha(50),
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
                final newName = textController.text.trim();
                if (newName.isNotEmpty && newName != board.title) {
                  try {
                    await Supabase.instance.client
                        .from('task_boards')
                        .update({'board_name': newName})
                        .eq('board_id', board.id);
                    _fetchTasks();
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    debugPrint('Error editing board: $e');
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
  }

  Future<void> _deleteBoard(_Board board) async {
    if (board.id == 'quick-tasks-board') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete the Quick Tasks board.')),
      );
      return;
    }

    final shouldDelete = await showDeleteBottomSheet(
      context,
      title: 'Delete Board?',
      subtitle:
          'Delete "${board.title}" and all its lists? This cannot be undone.',
    );

    if (shouldDelete == true) {
      try {
        await Supabase.instance.client
            .from('task_boards')
            .delete()
            .eq('board_id', board.id);

        // Reset selection if we deleted the active board
        if (_selectedBoardId == board.id) {
          _selectedBoardId = null;
          _selectedListId = null;
        }
        _fetchTasks();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting board: $e')));
        }
      }
    }
  }

  void _showListOptions(_Board board, _TaskList list) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.drive_file_move_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  'Move to Board',
                  style: GoogleFonts.outfit(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _moveListDialog(board, list);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.edit_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  'Edit List',
                  style: GoogleFonts.outfit(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _editListDialog(board, list);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                title: Text(
                  'Delete List',
                  style: GoogleFonts.outfit(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteList(board, list);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editListDialog(_Board board, _TaskList list) async {
    final textController = TextEditingController(text: list.title);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'Edit List Name',
            style: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: TextField(
            controller: textController,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'List Name',
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).dividerColor.withAlpha(50),
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
                final newName = textController.text.trim();
                if (newName.isNotEmpty && newName != list.title) {
                  try {
                    final res = await Supabase.instance.client
                        .from('task_boards')
                        .select()
                        .eq('board_id', board.id)
                        .single();
                    final currentLists = List.from(res['lists'] ?? []);
                    for (var l in currentLists) {
                      if (l['id'] == list.id) {
                        l['title'] = newName;
                        break;
                      }
                    }

                    await Supabase.instance.client
                        .from('task_boards')
                        .update({'lists': currentLists})
                        .eq('board_id', board.id);

                    _fetchTasks();
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    debugPrint('Error editing list: $e');
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
  }

  Future<void> _moveListDialog(_Board sourceBoard, _TaskList list) async {
    final availableBoards = _boards
        .where((b) => b.id != sourceBoard.id)
        .toList();
    if (availableBoards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other boards available')),
      );
      return;
    }

    _Board? selectedBoard = availableBoards.first;

    final shouldMove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text(
                'Move List',
                style: GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              content: DropdownButtonFormField<_Board>(
                initialValue: selectedBoard,
                dropdownColor: Theme.of(context).colorScheme.surface,
                items: availableBoards
                    .map(
                      (b) => DropdownMenuItem(
                        value: b,
                        child: Text(
                          b.title,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setDialogState(() => selectedBoard = val),
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
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
                    'Move',
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

    if (shouldMove == true && selectedBoard != null) {
      try {
        final sourceRes = await Supabase.instance.client
            .from('task_boards')
            .select()
            .eq('board_id', sourceBoard.id)
            .single();
        final targetRes = await Supabase.instance.client
            .from('task_boards')
            .select()
            .eq('board_id', selectedBoard!.id)
            .single();

        final sourceLists = List.from(sourceRes['lists'] ?? []);
        final targetLists = List.from(targetRes['lists'] ?? []);

        final listToMove = sourceLists.firstWhere(
          (l) => l['id'] == list.id,
          orElse: () => null,
        );
        if (listToMove == null) return;

        sourceLists.removeWhere((l) => l['id'] == list.id);
        targetLists.add(listToMove);

        await Future.wait([
          Supabase.instance.client
              .from('task_boards')
              .update({'lists': sourceLists})
              .eq('board_id', sourceBoard.id),
          Supabase.instance.client
              .from('task_boards')
              .update({'lists': targetLists})
              .eq('board_id', selectedBoard!.id),
        ]);

        if (_selectedBoardId == sourceBoard.id && _selectedListId == list.id) {
          _selectedBoardId = selectedBoard!.id;
        }

        _fetchTasks();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error moving list: $e')));
        }
      }
    }
  }

  Future<void> _deleteList(_Board board, _TaskList list) async {
    final shouldDelete = await showDeleteBottomSheet(
      context,
      title: 'Delete List?',
      subtitle:
          'Delete "${list.title}" and all its tasks? This cannot be undone.',
    );

    if (shouldDelete == true) {
      try {
        final res = await Supabase.instance.client
            .from('task_boards')
            .select()
            .eq('board_id', board.id)
            .single();
        final currentLists = List.from(res['lists'] ?? []);
        currentLists.removeWhere((l) => l['id'] == list.id);

        await Supabase.instance.client
            .from('task_boards')
            .update({'lists': currentLists})
            .eq('board_id', board.id);

        // Reset selection if we deleted the active list
        if (_selectedListId == list.id) {
          _selectedListId = null;
        }
        _fetchTasks();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting list: $e')));
        }
      }
    }
  }

  List<Item> get _filteredTasks {
    final listTasks = _allTasks
        .where((t) => t.listId == _selectedListId)
        .toList();
    if (_statusFilter == 'active') {
      return listTasks.where((t) => t.completed != true).toList();
    } else {
      return listTasks.where((t) => t.completed == true).toList();
    }
  }

  Future<void> _onReorderTasks(int oldIndex, int newIndex) async {
    if (_selectedBoardId == null || _selectedListId == null) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final tasksList = _filteredTasks;
    if (oldIndex >= tasksList.length || newIndex >= tasksList.length) return;

    final Item item = tasksList.removeAt(oldIndex);
    tasksList.insert(newIndex, item);

    setState(() {
      _allTasks.removeWhere(
        (t) =>
            t.listId == _selectedListId &&
            (t.completed == true) == (_statusFilter == 'complete'),
      );
      _allTasks.addAll(tasksList);
    });

    try {
      final res = await Supabase.instance.client
          .from('task_boards')
          .select()
          .eq('board_id', _selectedBoardId!)
          .single();

      final currentLists = List.from(res['lists'] ?? []);

      for (var list in currentLists) {
        if (list['id'] == _selectedListId) {
          final tasksJson = List<Map<String, dynamic>>.from(
            list['tasks'] ?? [],
          );

          final isCompleteFilter = _statusFilter == 'complete';
          final targetStatusTasks = tasksJson
              .where((t) => (t['completed'] == true) == isCompleteFilter)
              .toList();
          final otherStatusTasks = tasksJson
              .where((t) => (t['completed'] == true) != isCompleteFilter)
              .toList();

          final movedTask = targetStatusTasks.removeAt(oldIndex);
          targetStatusTasks.insert(newIndex, movedTask);

          list['tasks'] = [...targetStatusTasks, ...otherStatusTasks];
          break;
        }
      }

      await Supabase.instance.client
          .from('task_boards')
          .update({'lists': currentLists})
          .eq('board_id', _selectedBoardId!);
    } catch (e) {
      debugPrint('Error reordering tasks: $e');
      _fetchTasks();
    }
  }

  void _showSortBoardsDialog() {
    final List<_Board> localBoards = List.from(_boards);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text(
                'Sort Task Boards',
                style: GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  itemCount: localBoards.length,
                  onReorder: (oldIndex, newIndex) {
                    if (oldIndex < newIndex) newIndex -= 1;

                    final movedBoard = localBoards[oldIndex];
                    if (movedBoard.id == 'quick-tasks-board' ||
                        (newIndex == 0 &&
                            localBoards.any(
                              (b) => b.id == 'quick-tasks-board',
                            ))) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Quick Tasks must remain first.'),
                        ),
                      );
                      return;
                    }

                    setDialogState(() {
                      final b = localBoards.removeAt(oldIndex);
                      localBoards.insert(newIndex, b);
                    });
                  },
                  itemBuilder: (context, index) {
                    final board = localBoards[index];
                    return ListTile(
                      key: ValueKey(board.id),
                      title: Text(
                        board.title,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.drag_handle,
                        color: Colors.grey,
                      ),
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
                    Navigator.pop(context);
                    setState(() {
                      _boards = localBoards;
                    });
                    try {
                      final updates = <Future>[];
                      for (int i = 0; i < _boards.length; i++) {
                        final bd = _boards[i];
                        if (bd.id == 'quick-tasks-board') continue;
                        updates.add(
                          Supabase.instance.client
                              .from('task_boards')
                              .update({'sort_order': i})
                              .eq('board_id', bd.id),
                        );
                      }
                      await Future.wait(updates);
                    } catch (e) {
                      debugPrint('Error saving board order: $e');
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

  void _showSortListsDialog() {
    if (_selectedBoardId == null) return;

    final boardNode = _boards.firstWhere((b) => b.id == _selectedBoardId);
    final List<_TaskList> localLists = List.from(boardNode.lists);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: Text(
                'Sort Lists',
                style: GoogleFonts.outfit(color: Colors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  itemCount: localLists.length,
                  onReorder: (oldIndex, newIndex) {
                    if (oldIndex < newIndex) newIndex -= 1;

                    setDialogState(() {
                      final movedList = localLists.removeAt(oldIndex);
                      localLists.insert(newIndex, movedList);
                    });
                  },
                  itemBuilder: (context, index) {
                    final list = localLists[index];
                    return ListTile(
                      key: ValueKey(list.id),
                      title: Text(
                        list.title,
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: const Icon(
                        Icons.drag_handle,
                        color: Colors.grey,
                      ),
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
                    Navigator.pop(context);
                    setState(() {
                      boardNode.lists.clear();
                      boardNode.lists.addAll(localLists);
                    });
                    try {
                      final res = await Supabase.instance.client
                          .from('task_boards')
                          .select()
                          .eq('board_id', _selectedBoardId!)
                          .single();

                      final currentLists = List.from(res['lists'] ?? []);

                      // Match the ordered list components
                      final Map<String, dynamic> idToData = {};
                      for (var cl in currentLists) {
                        idToData[cl['id']] = cl;
                      }

                      final newOrderedListsData = localLists
                          .map((l) => idToData[l.id])
                          .toList();

                      await Supabase.instance.client
                          .from('task_boards')
                          .update({'lists': newOrderedListsData})
                          .eq('board_id', _selectedBoardId!);
                    } catch (e) {
                      debugPrint('Error saving lists order: $e');
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

  @override
  Widget build(BuildContext context) {
    final currentBoard = _boards.isEmpty
        ? null
        : _boards.firstWhere(
            (b) => b.id == _selectedBoardId,
            orElse: () => _boards.first,
          );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        title: FocusAwareAppBarTitle(
          child: Text(
            'Task Lists',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
        ),
        leading: const FocusAwareBackButton(),
        actions: [
          const FocusAppBarActions(guide: FocusHelpGuide.actionCenter),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.sort,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            tooltip: 'Sort Options',
            color: Theme.of(context).colorScheme.surface,
            onSelected: (value) {
              if (value == 'boards') {
                _showSortBoardsDialog();
              } else if (value == 'lists') {
                _showSortListsDialog();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'boards',
                child: Text(
                  'Sort Boards',
                  style: GoogleFonts.outfit(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (_selectedBoardId != null)
                PopupMenuItem<String>(
                  value: 'lists',
                  child: Text(
                    'Sort Lists',
                    style: GoogleFonts.outfit(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
            ],
          ),
          // Add Board button
          IconButton(
            icon: Icon(
              Icons.space_dashboard_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: 'New Board',
            onPressed: _createBoard,
          ),
          // Add List button (if board selected)
          if (_selectedBoardId != null) ...[
            IconButton(
              icon: Icon(
                Icons.playlist_add,
                color: Theme.of(context).colorScheme.primary,
              ),
              tooltip: 'New List',
              onPressed: () => _createList(_selectedBoardId!),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Status Tab Switcher (Active / Complete)
          _buildStatusTabs(),

          // Board Selector Chips
          if (_boards.isNotEmpty) _buildBoardSelector(),

          // List Selector Chips
          if (currentBoard != null && currentBoard.lists.isNotEmpty)
            _buildListSelector(currentBoard),

          const SizedBox(height: 8),

          // Task List
          Expanded(
            child: _isLoading
                ? Center(
                    child: AbleriteLoadingIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : _filteredTasks.isEmpty
                ? _buildEmptyState()
                : ReorderableListView.builder(
                    scrollController: _taskScrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = _filteredTasks[index];
                      return Container(
                        key: _taskKeys.putIfAbsent(task.id, () => GlobalKey()),
                        child: _buildTaskCard(task),
                      );
                    },
                    onReorder: (oldIndex, newIndex) {
                      _onReorderTasks(oldIndex, newIndex);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: (_selectedListId != null)
          ? FloatingActionButton.extended(
              onPressed: _addTask,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: Text(
                'Add Task',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _buildStatusTabs() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withAlpha(20)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTab('Active', 'active')),
          Expanded(child: _buildTab('Complete', 'complete')),
        ],
      ),
    );
  }

  Widget _buildTab(String label, String value) {
    final isSelected = _statusFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface.withAlpha(150),
          ),
        ),
      ),
    );
  }

  Widget _buildBoardSelector() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        controller: _boardScrollController,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(
          left: 16,
          right: MediaQuery.of(context).size.width * 0.75,
        ),
        itemCount: _boards.length,
        itemBuilder: (context, index) {
          final board = _boards[index];
          final isSelected = _selectedBoardId == board.id;

          // Ensure we have a key for this board
          _boardKeys.putIfAbsent(board.id, () => GlobalKey());

          return Padding(
            key: _boardKeys[board.id],
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onLongPress: () => _showBoardOptions(board),
              child: FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.dashboard_outlined,
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(150),
                    ),
                    const SizedBox(width: 6),
                    Text(board.title),
                  ],
                ),
                labelStyle: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface.withAlpha(150),
                ),
                selectedColor: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).colorScheme.surface,
                onSelected: (selected) {
                  setState(() {
                    _selectedBoardId = board.id;
                    if (board.lists.isNotEmpty) {
                      _selectedListId = board.lists.first.id;
                    } else {
                      _selectedListId = null;
                    }
                  });
                  Future.delayed(const Duration(milliseconds: 50), () {
                    final keyContext = _boardKeys[board.id]?.currentContext;
                    if (keyContext != null && keyContext.mounted) {
                      final box = keyContext.findRenderObject() as RenderBox?;
                      if (box != null && _boardScrollController.hasClients) {
                        final screenX = box.localToGlobal(Offset.zero).dx;

                        final listViewBox =
                            _boardScrollController
                                    .position
                                    .context
                                    .storageContext
                                    .findRenderObject()
                                as RenderBox?;
                        final viewportScreenX =
                            listViewBox?.localToGlobal(Offset.zero).dx ?? 0.0;

                        final targetScreenX = viewportScreenX + 16.0;
                        final shift = screenX - targetScreenX;

                        final targetOffset =
                            _boardScrollController.offset + shift;

                        final maxScroll =
                            _boardScrollController.position.maxScrollExtent;
                        final minScroll =
                            _boardScrollController.position.minScrollExtent;
                        final clampedOffset = targetOffset.clamp(
                          minScroll,
                          maxScroll,
                        );

                        _boardScrollController.animateTo(
                          clampedOffset,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    }
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListSelector(_Board board) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 42,
        child: ListView.builder(
          controller: _listScrollController,
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.only(
            right: MediaQuery.of(context).size.width * 0.75,
          ),
          itemCount: board.lists.length,
          itemBuilder: (context, index) {
            final list = board.lists[index];
            final isSelected = _selectedListId == list.id;
            final taskCount = _allTasks
                .where((t) => t.listId == list.id)
                .length;

            _listKeys.putIfAbsent(list.id, () => GlobalKey());

            return Padding(
              key: _listKeys[list.id],
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onLongPress: () => _showListOptions(board, list),
                onTap: () {
                  setState(() => _selectedListId = list.id);
                  Future.delayed(const Duration(milliseconds: 50), () {
                    final keyContext = _listKeys[list.id]?.currentContext;
                    if (keyContext != null && keyContext.mounted) {
                      final box = keyContext.findRenderObject() as RenderBox?;
                      if (box != null && _listScrollController.hasClients) {
                        final screenX = box.localToGlobal(Offset.zero).dx;

                        final listViewBox =
                            _listScrollController
                                    .position
                                    .context
                                    .storageContext
                                    .findRenderObject()
                                as RenderBox?;
                        final viewportScreenX =
                            listViewBox?.localToGlobal(Offset.zero).dx ?? 0.0;

                        final targetScreenX =
                            viewportScreenX +
                            0.0; // Lists have 0 left internal padding
                        final shift = screenX - targetScreenX;

                        final targetOffset =
                            _listScrollController.offset + shift;

                        final maxScroll =
                            _listScrollController.position.maxScrollExtent;
                        final minScroll =
                            _listScrollController.position.minScrollExtent;
                        final clampedOffset = targetOffset.clamp(
                          minScroll,
                          maxScroll,
                        );

                        _listScrollController.animateTo(
                          clampedOffset,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary.withAlpha(40)
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).dividerColor.withAlpha(20),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        list.title,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(150),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.3)
                              : Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$taskCount',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[500],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Removed the inner GestureDetector for delete icon, as long press on the chip handles deletion
                      Icon(
                        Icons.close,
                        size: 14,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[500],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _deleteTask(Item task) async {
    final shouldDelete = await showDeleteBottomSheet(
      context,
      title: 'Delete Task?',
      subtitle: 'Delete "${task.text}"? This cannot be undone.',
    );

    if (shouldDelete != true) return;

    try {
      final location = _taskLocations[task.id];
      if (location == null) return;

      final currentLists = List.from(location.fullBoardData['lists'] ?? []);

      for (var list in currentLists) {
        if (list['id'] == location.listId) {
          final tasks = List.from(list['tasks'] ?? []);
          tasks.removeWhere((t) => t['id'].toString() == location.taskId);
          list['tasks'] = tasks;
          break;
        }
      }

      await Supabase.instance.client
          .from('task_boards')
          .update({'lists': currentLists})
          .eq('board_id', location.boardId);

      _fetchTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting task: $e')));
      }
    }
  }

  Future<void> _moveTaskDialog(Item task) async {
    final source = _taskLocations[task.id];
    if (source == null) return;

    final destinations = <_TaskDestination>[
      for (final board in _boards)
        for (final list in board.lists)
          if (board.id != source.boardId || list.id != source.listId)
            _TaskDestination(board: board, list: list),
    ];

    if (destinations.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No other lists available')));
      return;
    }

    _TaskDestination selectedDestination = destinations.first;
    final shouldMove = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'Move Task',
            style: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: DropdownButtonFormField<_TaskDestination>(
            initialValue: selectedDestination,
            isExpanded: true,
            dropdownColor: Theme.of(context).colorScheme.surface,
            items: destinations
                .map(
                  (destination) => DropdownMenuItem(
                    value: destination,
                    child: Text(
                      '${destination.board.title} — ${destination.list.title}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (destination) {
              if (destination != null) {
                setDialogState(() => selectedDestination = destination);
              }
            },
            decoration: InputDecoration(
              labelText: 'Destination list',
              border: const OutlineInputBorder(),
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
            ),
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
                'Move',
                style: GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (shouldMove != true) return;
    await _moveTask(task, source, selectedDestination);
  }

  Future<void> _moveTask(
    Item task,
    _TaskLocation source,
    _TaskDestination destination,
  ) async {
    try {
      final sourceResponse = await Supabase.instance.client
          .from('task_boards')
          .select()
          .eq('board_id', source.boardId)
          .single();
      final sourceLists = List.from(sourceResponse['lists'] ?? []);

      dynamic taskData;
      for (final list in sourceLists) {
        if (list['id'] == source.listId) {
          final tasks = List.from(list['tasks'] ?? []);
          final taskIndex = tasks.indexWhere(
            (entry) => entry['id'].toString() == source.taskId,
          );
          if (taskIndex >= 0) taskData = tasks.removeAt(taskIndex);
          list['tasks'] = tasks;
          break;
        }
      }
      if (taskData == null) {
        throw StateError('Task could not be found in its current list.');
      }

      if (source.boardId == destination.board.id) {
        var destinationFound = false;
        for (final list in sourceLists) {
          if (list['id'] == destination.list.id) {
            final tasks = List.from(list['tasks'] ?? []);
            tasks.add(taskData);
            list['tasks'] = tasks;
            destinationFound = true;
            break;
          }
        }
        if (!destinationFound) {
          throw StateError('The destination list is no longer available.');
        }
        await Supabase.instance.client
            .from('task_boards')
            .update({'lists': sourceLists})
            .eq('board_id', source.boardId);
      } else {
        final destinationResponse = await Supabase.instance.client
            .from('task_boards')
            .select()
            .eq('board_id', destination.board.id)
            .single();
        final destinationLists = List.from(destinationResponse['lists'] ?? []);
        var destinationFound = false;
        for (final list in destinationLists) {
          if (list['id'] == destination.list.id) {
            final tasks = List.from(list['tasks'] ?? []);
            tasks.add(taskData);
            list['tasks'] = tasks;
            destinationFound = true;
            break;
          }
        }
        if (!destinationFound) {
          throw StateError('The destination list is no longer available.');
        }

        await Future.wait([
          Supabase.instance.client
              .from('task_boards')
              .update({'lists': sourceLists})
              .eq('board_id', source.boardId),
          Supabase.instance.client
              .from('task_boards')
              .update({'lists': destinationLists})
              .eq('board_id', destination.board.id),
        ]);
      }

      if (!mounted) return;
      setState(() {
        _selectedBoardId = destination.board.id;
        _selectedListId = destination.list.id;
      });
      await _fetchTasks();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('"${task.text}" moved.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error moving task: $e')));
      }
    }
  }

  Future<void> _editTaskDialog(Item task) async {
    final textController = TextEditingController(text: task.text);
    List<Goal> availableGoals = [];
    Set<String> selectedGoalIds = task.relatedIds != null
        ? task.relatedIds!.toSet()
        : {};
    String? dueDate = task.dueDate;
    bool isLoadingGoals = true;

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final goalsResponse = await Supabase.instance.client
            .from('items')
            .select()
            .eq('user_id', userId)
            .inFilter('section', ['activeGoals', 'longTermGoals'])
            .neq('status', 'deleted')
            .neq('status', 'trashed');

        availableGoals = goalsResponse.map((g) => Goal.fromJson(g)).toList();
      }
    } catch (e) {
      debugPrint('Error loading goals: $e');
    }
    isLoadingGoals = false;

    if (!context.mounted) return;
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
                                padding: EdgeInsets.all(16.0),
                                child: AbleriteLoadingIndicator(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              )
                            else if (availableGoals.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  "No goals found",
                                  style: GoogleFonts.outfit(color: Colors.grey),
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
                        final location = _taskLocations[task.id];
                        if (location == null) {
                          Navigator.pop(context);
                          return;
                        }

                        final currentLists = List.from(
                          location.fullBoardData['lists'] ?? [],
                        );

                        for (var list in currentLists) {
                          if (list['id'] == location.listId) {
                            final tasks = List.from(list['tasks'] ?? []);
                            for (var t in tasks) {
                              if (t['id'].toString() == location.taskId) {
                                t['content'] = textController.text.trim();
                                t['related_ids'] = selectedGoalIds.toList();
                                t['dueDate'] = dueDate;
                                break;
                              }
                            }
                            list['tasks'] = tasks;
                            break;
                          }
                        }

                        await Supabase.instance.client
                            .from('task_boards')
                            .update({'lists': currentLists})
                            .eq('board_id', location.boardId);

                        _fetchTasks();
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        debugPrint('Error editing task: $e');
                      }
                    } else if (textController.text.trim().isNotEmpty) {
                      // Update related IDs even if text hasn't changed
                      try {
                        final location = _taskLocations[task.id];
                        if (location != null) {
                          final currentLists = List.from(
                            location.fullBoardData['lists'] ?? [],
                          );
                          for (var list in currentLists) {
                            if (list['id'] == location.listId) {
                              final tasks = List.from(list['tasks'] ?? []);
                              for (var t in tasks) {
                                if (t['id'].toString() == location.taskId) {
                                  t['related_ids'] = selectedGoalIds.toList();
                                  t['dueDate'] = dueDate;
                                  break;
                                }
                              }
                              list['tasks'] = tasks;
                              break;
                            }
                          }

                          await Supabase.instance.client
                              .from('task_boards')
                              .update({'lists': currentLists})
                              .eq('board_id', location.boardId);

                          _fetchTasks();
                        }
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        debugPrint('Error updating related goals: $e');
                      }
                    } else {
                      // No changes made, just close the dialog
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

  Widget _buildTaskCard(Item task) {
    final isDone = task.completed == true;
    final isHighlighted = _highlightedTaskId == task.id;

    return GestureDetector(
      onTap: () {}, // No-op: only checkbox toggles
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlighted
                ? Theme.of(context).colorScheme.primary
                : isDone
                ? Theme.of(context).colorScheme.primary.withAlpha(80)
                : Theme.of(context).dividerColor.withAlpha(20),
            width: isHighlighted ? 2.5 : 1,
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox icon — only this toggles completion
                GestureDetector(
                  onTap: () => _toggleTask(task),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDone
                          ? Theme.of(context).colorScheme.primary.withAlpha(40)
                          : Theme.of(context).dividerColor.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDone ? Icons.check_circle : Icons.circle_outlined,
                      color: isDone
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(120),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Task text + due date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.text,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDone
                              ? Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(120)
                              : Theme.of(context).colorScheme.onSurface,
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : null,
                          height: 1.3,
                        ),
                      ),
                      if (task.dueDate != null && task.dueDate!.isNotEmpty) ...[
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
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (task.status != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(
                            task.status,
                          ).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (task.status ?? 'todo').toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _statusColor(task.status),
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onPressed: () => _showTaskOptions(task),
                      tooltip: 'Task Options',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 36,
                        height: 36,
                      ),
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(160),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskOptions(Item task) {
    showModalBottomSheet<void>(
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
                style: GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickTaskDueDate(task);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: Color(0xFF10B981),
              ),
              title: Text(
                'Edit Task',
                style: GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _editTaskDialog(task);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.drive_file_move_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Move Task',
                style: GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _moveTaskDialog(task);
              },
            ),
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
              onTap: () {
                Navigator.pop(sheetContext);
                _deleteTask(task);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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
      final location = _taskLocations[task.id];
      if (location == null) return;

      final currentLists = List.from(location.fullBoardData['lists'] ?? []);
      for (var list in currentLists) {
        if (list['id'] == location.listId) {
          final tasks = List.from(list['tasks'] ?? []);
          for (var t in tasks) {
            if (t['id'].toString() == location.taskId) {
              t['dueDate'] = dueDate;
              break;
            }
          }
          list['tasks'] = tasks;
          break;
        }
      }

      await Supabase.instance.client
          .from('task_boards')
          .update({'lists': currentLists})
          .eq('board_id', location.boardId);

      _fetchTasks();
    } catch (e) {
      debugPrint('Error updating task due date: $e');
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'doing':
        return Colors.amber;
      case 'done':
        return Theme.of(context).colorScheme.primary;
      default:
        return Colors.grey;
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _statusFilter == 'active'
                ? Icons.task_alt
                : Icons.check_circle_outline,
            size: 64,
            color: Colors.grey[800],
          ),
          const SizedBox(height: 16),
          Text(
            _statusFilter == 'active'
                ? 'No active tasks'
                : 'No completed tasks',
            style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            _statusFilter == 'active'
                ? 'Tap the + button to add a list'
                : 'Complete some tasks to see them here',
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}

class _TaskLocation {
  final String boardId;
  final String listId;
  final String taskId;
  final Map<String, dynamic> fullBoardData;

  _TaskLocation({
    required this.boardId,
    required this.listId,
    required this.taskId,
    required this.fullBoardData,
  });
}
