import 'package:flutter/material.dart';
import 'widgets/ablerite_loading_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/goal.dart';
import '../services/goals_service.dart';
import '../services/navigation_service.dart';
import 'goal_detail_page.dart';
import 'task_board_page.dart';
import 'todo_page.dart';
import 'widgets/focus_app_bar_actions.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarItem {
  final String id;
  final String title;
  final DateTime dueDate;
  final bool completed;
  final String type; // 'goal' | 'task'
  final Goal? goal;
  final Goal? parentGoal;
  final String? boardId;
  final String? listId;

  _CalendarItem({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.completed,
    required this.type,
    this.goal,
    this.parentGoal,
    this.boardId,
    this.listId,
  });
}

class _CalendarPageState extends State<CalendarPage> {
  bool _isLoading = true;
  List<_CalendarItem> _items = [];
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    pushPage();
    _loadData();
  }

  @override
  void dispose() {
    popPage();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final items = <_CalendarItem>[];
    var allGoals = <Goal>[];

    // Goals (active + long-term) with a due date
    try {
      final goalsService = GoalsService();
      final active = await goalsService.getActiveGoals();
      final longTerm = await goalsService.getLongTermGoals();
      allGoals = [...active, ...longTerm];
      for (final g in allGoals) {
        final dueDateStr = g.dueDate;
        if (dueDateStr == null || dueDateStr.isEmpty) continue;
        final parsed = DateTime.tryParse(dueDateStr);
        if (parsed == null) continue;
        items.add(
          _CalendarItem(
            id: g.id,
            title: g.text,
            dueDate: parsed,
            completed: g.completed == true,
            type: 'goal',
            goal: g,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading goals for calendar: $e');
    }

    // Goal-linked task board tasks (items table, section 'tasks')
    try {
      final res = await Supabase.instance.client
          .from('items')
          .select()
          .eq('user_id', userId)
          .eq('section', 'tasks')
          .not('due_date', 'is', null);
      for (final row in res) {
        final dueDateStr = row['due_date'] as String?;
        if (dueDateStr == null || dueDateStr.isEmpty) continue;
        final parsed = DateTime.tryParse(dueDateStr);
        if (parsed == null) continue;
        final parentGoal = await _resolveTaskGoal(
          row['parent_id']?.toString(),
          allGoals,
        );
        items.add(
          _CalendarItem(
            id: row['id'].toString(),
            title: row['text'] ?? '',
            dueDate: parsed,
            completed: row['completed'] == true,
            type: 'task',
            parentGoal: parentGoal,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading task-board tasks for calendar: $e');
    }

    // Quick Tasks + custom boards (task_boards JSON blobs)
    try {
      final res = await Supabase.instance.client
          .from('task_boards')
          .select()
          .eq('user_id', userId);
      for (final board in res) {
        final boardId = (board['board_id'] ?? board['id']).toString();
        final lists = board['lists'] as List? ?? [];
        for (final list in lists) {
          final listId = list['id'].toString();
          final tasks = list['tasks'] as List? ?? [];
          for (final t in tasks) {
            // Desktop (FreeformBoards.tsx) stores this JSON blob field as
            // camelCase 'dueDate'; fall back to legacy 'due_date'.
            final dueDateStr = (t['dueDate'] ?? t['due_date']) as String?;
            if (dueDateStr == null || dueDateStr.isEmpty) continue;
            final parsed = DateTime.tryParse(dueDateStr);
            if (parsed == null) continue;
            items.add(
              _CalendarItem(
                id: t['id'].toString(),
                title: t['content'] ?? '',
                dueDate: parsed,
                completed: t['completed'] == true,
                type: 'task',
                boardId: boardId,
                listId: listId,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading quick tasks for calendar: $e');
    }

    items.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    if (mounted) {
      setState(() {
        _items = items;
        _isLoading = false;
      });
    }
  }

  List<MapEntry<String, List<_CalendarItem>>> _groupedSections() {
    final now = DateTime.now();
    final todayKey = DateTime(now.year, now.month, now.day);

    final overdue = <_CalendarItem>[];
    final byDateKey = <DateTime, List<_CalendarItem>>{};

    final filteredItems = _selectedFilter == 'all'
        ? _items
        : _items.where((item) => item.type == _selectedFilter);

    for (final item in filteredItems) {
      final d = DateTime(
        item.dueDate.year,
        item.dueDate.month,
        item.dueDate.day,
      );
      if (d.isBefore(todayKey) && !item.completed) {
        overdue.add(item);
      } else if (!d.isBefore(todayKey)) {
        byDateKey.putIfAbsent(d, () => []).add(item);
      }
    }

    final sortedDates = byDateKey.keys.toList()..sort();
    final sections = <MapEntry<String, List<_CalendarItem>>>[];
    if (overdue.isNotEmpty) {
      sections.add(MapEntry('Overdue', overdue));
    }
    for (final d in sortedDates) {
      sections.add(MapEntry(_labelForDate(d, todayKey), byDateKey[d]!));
    }
    return sections;
  }

  String _labelForDate(DateTime d, DateTime todayKey) {
    final diff = d.difference(todayKey).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return DateFormat('EEE, MMM d').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final sections = _groupedSections();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leadingWidth: 44,
        titleSpacing: 0,
        centerTitle: false,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        title: FocusAwareAppBarTitle(
          focusOffset: 28,
          child: Row(
            children: [
              Text(
                'Calendar',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              _buildFilterTabs(),
              const SizedBox(width: 4),
            ],
          ),
        ),
        leading: const FocusAwareBackButton(),
        actions: const [FocusAppBarActions()],
      ),
      body: _isLoading
          ? Center(
              child: AbleriteLoadingIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: Theme.of(context).colorScheme.primary,
              child: sections.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.only(top: 120),
                      children: [_buildEmptyState()],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: sections.length,
                      itemBuilder: (context, index) {
                        final section = sections[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(section.key),
                            ...section.value.map(_buildItemRow),
                          ],
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildFilterTabs() {
    final colorScheme = Theme.of(context).colorScheme;
    const filters = [('all', 'All'), ('task', 'Tasks'), ('goal', 'Goals')];
    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(110),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: filters.map((filter) {
          final selected = _selectedFilter == filter.$1;
          return Semantics(
            button: true,
            selected: selected,
            label: 'Show ${filter.$2.toLowerCase()}',
            child: InkWell(
              onTap: () => setState(() => _selectedFilter = filter.$1),
              borderRadius: BorderRadius.circular(7),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 11),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  filter.$2,
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    final isOverdue = label == 'Overdue';
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 10),
      child: Row(
        children: [
          Icon(
            isOverdue
                ? Icons.warning_amber_rounded
                : Icons.calendar_today_outlined,
            size: 14,
            color: isOverdue
                ? Colors.redAccent
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
              color: isOverdue
                  ? Colors.redAccent
                  : Theme.of(context).colorScheme.onSurface.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }

  Future<Goal?> _resolveTaskGoal(
    String? parentId,
    List<Goal> loadedGoals,
  ) async {
    if (parentId == null || parentId.isEmpty) return null;
    final goalsById = {for (final goal in loadedGoals) goal.id: goal};
    final visited = <String>{};
    var currentId = parentId;

    while (currentId.isNotEmpty && visited.add(currentId)) {
      final loadedGoal = goalsById[currentId];
      if (loadedGoal != null) return loadedGoal;

      try {
        final parent = await Supabase.instance.client
            .from('items')
            .select()
            .eq('id', currentId)
            .maybeSingle();
        if (parent == null) return null;
        final section = parent['section']?.toString();
        if (section == 'activeGoals' || section == 'longTermGoals') {
          return Goal.fromJson(parent);
        }
        currentId = parent['parent_id']?.toString() ?? '';
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> _openItem(_CalendarItem item) async {
    final Widget destination;
    if (item.goal != null) {
      destination = GoalDetailPage(goal: item.goal!);
    } else if (item.parentGoal != null) {
      destination = TaskBoardPage(
        goal: item.parentGoal!,
        initialTaskId: item.id,
      );
    } else {
      destination = TodoPage(
        initialBoardId: item.boardId,
        initialListId: item.listId,
        initialTaskId: item.id,
      );
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
    if (mounted) _loadData();
  }

  Widget _buildItemRow(_CalendarItem item) {
    final isGoal = item.type == 'goal';
    final itemLabel = isGoal
        ? 'GOAL'
        : item.parentGoal != null
        ? 'GOAL TASK'
        : 'LIST TASK';
    final colorScheme = Theme.of(context).colorScheme;
    final color = isGoal
        ? colorScheme.primary
        : item.parentGoal != null
        ? colorScheme.tertiary
        : colorScheme.secondary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openItem(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).dividerColor.withAlpha(20),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: item.completed
                      ? TextDecoration.lineThrough
                      : null,
                  color: item.completed
                      ? Theme.of(context).colorScheme.onSurface.withAlpha(120)
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                itemLabel,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 64,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 16),
            Text(
              switch (_selectedFilter) {
                'task' => 'No tasks scheduled',
                'goal' => 'No goals scheduled',
                _ => 'Nothing scheduled',
              },
              style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            Text(
              switch (_selectedFilter) {
                'task' => 'Add due dates to your tasks to see them here.',
                'goal' => 'Add due dates to your goals to see them here.',
                _ => 'Add due dates to your tasks and goals to see them here.',
              },
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
