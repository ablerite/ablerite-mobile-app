import 'package:flutter/material.dart';
import 'widgets/ablerite_loading_indicator.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/focus_app_bar_actions.dart';
import '../models/goal.dart';
import '../services/goals_service.dart';
import '../services/navigation_service.dart';
import 'goal_detail_page.dart';
import 'widgets/auto_walkthrough.dart';
import 'widgets/smart_goal_fields.dart';
import 'widgets/spotlight_walkthrough.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  final GoalsService _goalsService = GoalsService();
  String selectedTab = 'active'; // 'active' or 'longterm'
  String selectedCategory = 'all';
  String selectedType =
      'all'; // 'all', 'need', 'desire', 'asset', or 'liability'

  List<Goal> activeGoals = [];
  List<Goal> longTermGoals = [];
  bool isLoading = true;

  final ScrollController _categoryScrollController = ScrollController();
  late List<GlobalKey> _categoryKeys;
  final GlobalKey _statusTabsKey = GlobalKey();
  final GlobalKey _categoryFilterKey = GlobalKey();
  final GlobalKey _typeFilterKey = GlobalKey();
  final GlobalKey _primaryGoalKey = GlobalKey();
  final GlobalKey _goalListKey = GlobalKey();
  final GlobalKey _addGoalKey = GlobalKey();

  final List<Map<String, dynamic>> categories = [
    {'id': 'all', 'label': 'All', 'icon': Icons.apps},
    {'id': 'health', 'label': 'Health', 'icon': Icons.favorite},
    {'id': 'wealth', 'label': 'Wealth', 'icon': Icons.attach_money},
    {'id': 'relationships', 'label': 'Relationships', 'icon': Icons.people},
    {'id': 'experiences', 'label': 'Experiences', 'icon': Icons.explore},
    {'id': 'objects', 'label': 'Objects', 'icon': Icons.inventory_2},
  ];

  @override
  void initState() {
    super.initState();
    pushPage();
    _categoryKeys = List.generate(categories.length, (index) => GlobalKey());
    _loadGoals();
  }

  @override
  void dispose() {
    popPage();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AutoWalkthrough.maybeShowOnce(
      context,
      id: 'goals-page',
      steps: _walkthroughSteps,
    );
  }

  void _showGoalsWalkthrough() {
    setState(() {
      selectedTab = 'active';
      selectedCategory = 'all';
      selectedType = 'all';
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SpotlightWalkthrough.show(context, steps: _walkthroughSteps);
    });
  }

  List<SpotlightStep> get _walkthroughSteps => [
    SpotlightStep(
      targetKey: _statusTabsKey,
      title: 'Goal Status',
      body:
          'Toggle between Active goals, Inactive (long-term) goals, and Completed goals.',
    ),
    SpotlightStep(
      targetKey: _categoryFilterKey,
      title: 'Life Areas',
      body:
          'Filter your goals by category area, such as Health, Wealth, Relationships, or Career.',
    ),
    SpotlightStep(
      targetKey: _typeFilterKey,
      title: 'Goal Types',
      body:
          'Classify goals as Needs, Desires, Assets, or Liabilities to keep financial and life targets organized.',
    ),
    SpotlightStep(
      targetKey: _primaryGoalKey,
      title: 'Primary Focus',
      body:
          'Your top active goal is pinned at the top as your main focus and stays highlighted across focus screens.',
    ),
    SpotlightStep(
      targetKey: _goalListKey,
      title: 'Priority Order',
      body:
          'Use the up and down arrows on goal cards to reorder your priority list.',
    ),
    SpotlightStep(
      targetKey: _addGoalKey,
      title: 'Add Goal',
      body:
          'Tap to create a new goal with target dates, SMART criteria, estimated costs, and personal motivation.',
    ),
  ];

  Future<void> _loadGoals() async {
    setState(() => isLoading = true);
    try {
      final active = await _goalsService.getActiveGoals();
      final longTerm = await _goalsService.getLongTermGoals();
      final archived = await _goalsService.getArchivedGoals();

      setState(() {
        // Include archived goals in both lists for filtering
        activeGoals = [
          ...active,
          ...archived.where((g) => g.section == 'activeGoals'),
        ];
        longTermGoals = [
          ...longTerm,
          ...archived.where((g) => g.section == 'longTermGoals'),
        ];
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading goals: $e');
      setState(() => isLoading = false);
    }
  }

  List<Goal> get filteredGoals {
    List<Goal> goals;

    if (selectedTab == 'active') {
      // Active: activeGoals where archived != true AND completed != true
      goals = activeGoals
          .where((g) => g.archived != true && g.completed != true)
          .toList();
    } else if (selectedTab == 'inactive') {
      // Inactive: longTermGoals where archived != true AND completed != true
      goals = longTermGoals
          .where((g) => g.archived != true && g.completed != true)
          .toList();
    } else {
      // Complete: ALL goals where archived == true OR completed == true
      goals = [
        ...activeGoals,
        ...longTermGoals,
      ].where((g) => g.archived == true || g.completed == true).toList();
    }

    // Apply category filter
    if (selectedCategory != 'all') {
      goals = goals.where((g) => g.category == selectedCategory).toList();
    }

    // Apply type filter
    if (selectedType != 'all') {
      goals = goals.where((g) => g.goalType == selectedType).toList();
    }

    return goals;
  }

  Future<void> _showAddEditGoalDialog({Goal? goal}) async {
    final isEditing = goal != null;
    final textController = TextEditingController(text: goal?.text ?? '');
    final whyController = TextEditingController(text: goal?.why ?? '');
    final specificController = TextEditingController(
      text: goal?.specific ?? '',
    );
    final measurableController = TextEditingController(
      text: goal?.measurable ?? '',
    );
    final achievableController = TextEditingController(
      text: goal?.achievable ?? '',
    );
    final relevantController = TextEditingController(
      text: goal?.relevant ?? '',
    );
    final costController = TextEditingController(
      text: goal?.costEstimate == null
          ? ''
          : _formatNumberWithThousands(goal!.costEstimate!),
    );
    String? startDate = goal?.startDate;
    String? dueDate = goal?.dueDate;
    String selectedGoalCategory = goal?.category ?? 'health';
    String selectedGoalType = goal?.goalType ?? 'desire';
    String selectedCostType = goal?.costType ?? 'one-time';
    String selectedGoalStatus = goal?.section == 'longTermGoals'
        ? 'inactive'
        : 'active';
    bool isPrimary = goal?.isPrimary ?? false;
    bool isSaving = false;
    int currentStep = 0;

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
                        isEditing ? 'Edit Goal' : 'Add New Goal',
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
                          // Goal Text
                          TextField(
                            controller: textController,
                            onChanged: (_) => setDialogState(() {}),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Goal',
                              labelStyle: TextStyle(
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
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),

                          // Why
                          TextField(
                            controller: whyController,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Why is this important?',
                              labelStyle: TextStyle(
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
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Status',
                            style: GoogleFonts.outfit(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(150),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTypeChip(
                                  'Active',
                                  'active',
                                  selectedGoalStatus,
                                  (value) => setDialogState(() {
                                    selectedGoalStatus = value;
                                  }),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTypeChip(
                                  'Inactive',
                                  'inactive',
                                  selectedGoalStatus,
                                  (value) => setDialogState(() {
                                    selectedGoalStatus = value;
                                    isPrimary = false;
                                  }),
                                ),
                              ),
                            ],
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
                              selectedGoalStatus == 'active'
                                  ? 'Feature this goal at the top of your active goals.'
                                  : 'Only active goals can be the primary focus.',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(140),
                              ),
                            ),
                            value: isPrimary,
                            onChanged: selectedGoalStatus == 'active'
                                ? (value) =>
                                      setDialogState(() => isPrimary = value)
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Dates',
                            style: GoogleFonts.outfit(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(150),
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
                          // Category Selector
                          Text(
                            'Category',
                            style: GoogleFonts.outfit(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(150),
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
                                      selectedGoalCategory == category['id'];
                                  return GestureDetector(
                                    onTap: () {
                                      setDialogState(() {
                                        selectedGoalCategory = category['id'];
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
                                                  .withAlpha(40)
                                            : Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest
                                                  .withAlpha(100),
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
                                        category['label'],
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

                          // Type Selector
                          Text(
                            'Type',
                            style: GoogleFonts.outfit(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(150),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTypeChip(
                                  'Need',
                                  'need',
                                  selectedGoalType,
                                  (value) => setDialogState(
                                    () => selectedGoalType = value,
                                  ),
                                  selectedColor: _goalTypeColor('need'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTypeChip(
                                  'Desire',
                                  'desire',
                                  selectedGoalType,
                                  (value) => setDialogState(
                                    () => selectedGoalType = value,
                                  ),
                                  selectedColor: _goalTypeColor('desire'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTypeChip(
                                  'Asset',
                                  'asset',
                                  selectedGoalType,
                                  (value) => setDialogState(
                                    () => selectedGoalType = value,
                                  ),
                                  selectedColor: _goalTypeColor('asset'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTypeChip(
                                  'Liability',
                                  'liability',
                                  selectedGoalType,
                                  (value) => setDialogState(
                                    () => selectedGoalType = value,
                                  ),
                                  selectedColor: _goalTypeColor('liability'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Text(
                            'Estimated Cost',
                            style: GoogleFonts.outfit(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(150),
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
                                    labelStyle: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withAlpha(120),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Theme.of(
                                          context,
                                        ).dividerColor.withAlpha(50),
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
                                      borderSide: BorderSide(
                                        color: Theme.of(
                                          context,
                                        ).dividerColor.withAlpha(50),
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
                  if (currentStep == 2 && isEditing)
                    TextButton(
                      onPressed: () async {
                        await _goalsService.deleteGoal(goal.id);
                        if (context.mounted) Navigator.pop(context);
                        _loadGoals();
                      },
                      child: Text(
                        'Delete',
                        style: GoogleFonts.outfit(color: Colors.red),
                      ),
                    ),
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
                            if (textController.text.isEmpty) return;
                            setDialogState(() => isSaving = true);

                            final newGoal = Goal(
                              id: goal?.id ?? '',
                              text: textController.text,
                              userId: goal?.userId ?? '',
                              section: selectedGoalStatus == 'active'
                                  ? 'activeGoals'
                                  : 'longTermGoals',
                              category: selectedGoalCategory,
                              parentId: goal?.parentId,
                              goalType: selectedGoalType,
                              startDate: startDate,
                              dueDate: dueDate,
                              why: whyController.text.isEmpty
                                  ? null
                                  : whyController.text,
                              completed: goal?.completed ?? false,
                              archived: goal?.archived ?? false,
                              orderIndex: goal?.orderIndex,
                              value: goal?.value,
                              isPrimary:
                                  selectedGoalStatus == 'active' && isPrimary,
                              costEstimate: costController.text.trim().isEmpty
                                  ? null
                                  : double.tryParse(
                                      costController.text.trim().replaceAll(
                                        ',',
                                        '',
                                      ),
                                    ),
                              costType: selectedCostType,
                              relatedIds: goal?.relatedIds,
                              relatedVisionBoardIds:
                                  goal?.relatedVisionBoardIds,
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

                            if (isEditing) {
                              final updates = {
                                'text': newGoal.text,
                                'section': newGoal.section,
                                'category': newGoal.category,
                                'due_date': newGoal.dueDate,
                                'start_date': newGoal.startDate,
                                'goal_type': newGoal.goalType,
                                'why': newGoal.why,
                                'is_primary': newGoal.isPrimary,
                                'cost_estimate': newGoal.costEstimate,
                                'cost_type': newGoal.costType,
                                'specific': newGoal.specific,
                                'measurable': newGoal.measurable,
                                'achievable': newGoal.achievable,
                                'relevant': newGoal.relevant,
                              };
                              final saved = await _goalsService
                                  .updateGoalFields(newGoal.id, updates);
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
                            } else {
                              final savedGoal = await _goalsService.addGoal(
                                newGoal,
                              );
                              if (savedGoal == null) {
                                if (!context.mounted) return;
                                setDialogState(() => isSaving = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Could not add goal'),
                                  ),
                                );
                                return;
                              }
                            }

                            if (!dialogContext.mounted) return;
                            final dialogRoute = ModalRoute.of(dialogContext);
                            if (dialogRoute?.isCurrent == true) {
                              Navigator.of(dialogContext).pop();
                            }
                            if (mounted) {
                              setState(() => selectedTab = selectedGoalStatus);
                            }
                            _loadGoals();
                          },
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            currentStep < 2
                                ? 'Next'
                                : isEditing
                                ? 'Save'
                                : 'Add',
                            style: GoogleFonts.outfit(
                              color: Theme.of(context).colorScheme.primary,
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

  Widget _buildTypeChip(
    String label,
    String value,
    String selected,
    Function(String) onSelect, {
    Color? selectedColor,
  }) {
    final isSelected = selected == value;
    final activeColor = selectedColor ?? Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withAlpha(40)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: isSelected
                ? activeColor
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        title: FocusAwareAppBarTitle(
          child: Text(
            'Goals',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
        ),
        leading: const FocusAwareBackButton(),
        actions: [
          const FocusAppBarActions(guide: FocusHelpGuide.actionCenter),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Goals walkthrough',
            onPressed: _showGoalsWalkthrough,
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Switcher
          Container(
            key: _statusTabsKey,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor.withAlpha(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(child: _buildTab('Active', 'active')),
                Expanded(child: _buildTab('Inactive', 'inactive')),
                Expanded(child: _buildTab('Complete', 'complete')),
              ],
            ),
          ),
          KeyedSubtree(
            key: _categoryFilterKey,
            child: _buildCategorySelector(),
          ),
          const SizedBox(height: 8),
          KeyedSubtree(key: _typeFilterKey, child: _buildTypeSelector()),
          const SizedBox(height: 8),

          // Content
          Expanded(
            child: isLoading
                ? Center(
                    child: AbleriteLoadingIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : selectedTab == 'active'
                ? _buildActiveView()
                : _buildInactiveView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: _addGoalKey,
        onPressed: () => _showAddEditGoalDialog(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          'Add Goal',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTab(String label, String value) {
    final isSelected = selectedTab == value;
    return GestureDetector(
      onTap: () => setState(() {
        selectedTab = value;
        selectedCategory = 'all';
        selectedType = 'all';
      }),
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

  Widget _buildTypeFilter(String label, String value) {
    final isSelected = selectedType == value;
    final selectedColor = value == 'all'
        ? Theme.of(context).colorScheme.primary
        : _goalTypeColor(value);
    return GestureDetector(
      onTap: () => setState(() => selectedType = value),
      child: Container(
        constraints: const BoxConstraints(minWidth: 72),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withAlpha(40)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? selectedColor
                : Theme.of(context).dividerColor.withAlpha(20),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? selectedColor
                : Theme.of(context).colorScheme.onSurface.withAlpha(150),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalCard(
    Goal goal, {
    bool isPrimary = false,
    bool canMoveUp = false,
    bool canMoveDown = false,
    VoidCallback? onMoveUp,
    VoidCallback? onMoveDown,
  }) {
    final categoryData = categories.firstWhere(
      (c) => c['id'] == goal.category,
      orElse: () => categories[0],
    );
    final isDone = goal.completed == true || goal.archived == true;
    final compact = MediaQuery.sizeOf(context).height < 760;
    final goalTypeColor = _goalTypeColor(goal.goalType);
    final metadata = [
      if (goal.startDate != null && goal.startDate!.isNotEmpty)
        _GoalMetadata(
          icon: Icons.event_available_outlined,
          text: 'Start ${_formatGoalDate(goal.startDate!)}',
        ),
      if (goal.dueDate != null && goal.dueDate!.isNotEmpty)
        _GoalMetadata(
          icon: Icons.event_outlined,
          text: 'Due ${_formatGoalDate(goal.dueDate!)}',
        ),
      if (goal.costEstimate != null)
        _GoalMetadata(
          icon: Icons.payments_outlined,
          text: _formatGoalCost(goal),
        ),
    ];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GoalDetailPage(goal: goal)),
        ).then((_) => _loadGoals()); // Reload goals when returning
      },
      child: Opacity(
        opacity: isDone ? 0.5 : 1.0,
        child: Container(
          margin: EdgeInsets.only(bottom: compact ? 8 : 12),
          padding: EdgeInsets.all(compact ? 12 : 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPrimary
                  ? Theme.of(context).colorScheme.primary.withAlpha(80)
                  : Theme.of(context).dividerColor.withAlpha(20),
              width: isPrimary ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha(50),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      categoryData['icon'],
                      color: Theme.of(context).colorScheme.primary,
                      size: compact ? 18 : 20,
                    ),
                  ),
                  SizedBox(width: compact ? 10 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: compact ? 15 : 17,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : null,
                            height: 1.3,
                          ),
                        ),
                        if (goal.category != null)
                          Text(
                            categoryData['label'],
                            style: GoogleFonts.outfit(
                              fontSize: compact ? 11 : 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(120),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (goal.goalType != null)
                    Container(
                      margin: EdgeInsets.only(right: compact ? 4 : 8),
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 7 : 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: goalTypeColor.withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: goalTypeColor.withAlpha(80)),
                      ),
                      child: Text(
                        goal.goalType!.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: compact ? 9 : 10,
                          fontWeight: FontWeight.bold,
                          color: goalTypeColor,
                        ),
                      ),
                    ),
                  if (canMoveUp || canMoveDown) ...[
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildOrderButton(
                          icon: Icons.keyboard_arrow_up,
                          enabled: canMoveUp,
                          onPressed: onMoveUp,
                        ),
                        _buildOrderButton(
                          icon: Icons.keyboard_arrow_down,
                          enabled: canMoveDown,
                          onPressed: onMoveDown,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              if (metadata.isNotEmpty) ...[
                SizedBox(height: compact ? 8 : 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: metadata
                      .map((item) => _buildGoalMetadataChip(item, compact))
                      .toList(),
                ),
              ],
              if (goal.why != null && goal.why!.isNotEmpty) ...[
                SizedBox(height: compact ? 8 : 12),
                Text(
                  goal.why!,
                  style: GoogleFonts.outfit(
                    fontSize: compact ? 12 : 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(160),
                    height: 1.35,
                  ),
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalMetadataChip(_GoalMetadata item, bool compact) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 8,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item.icon,
            size: compact ? 12 : 13,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            item.text,
            style: GoogleFonts.outfit(
              fontSize: compact ? 10 : 11,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(170),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _goalTypeColor(String? goalType) {
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

  String _formatGoalDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return '${parsed.day}/${parsed.month}/${parsed.year.toString().substring(2)}';
  }

  String _formatGoalCost(Goal goal) {
    final amount = goal.costEstimate;
    if (amount == null) return '';
    final rounded = _formatNumberWithThousands(amount);
    final suffix = switch (goal.costType) {
      'monthly' => '/mo',
      'annual' => '/yr',
      _ => '',
    };
    return '\$$rounded$suffix';
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

  Widget _buildOrderButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 30,
      height: 30,
      child: IconButton(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, size: 22),
        color: enabled
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withAlpha(60),
        onPressed: enabled ? onPressed : null,
      ),
    );
  }

  Future<void> _moveGoalWithinArea(
    Goal goal,
    int direction,
    List<Goal> areaGoals,
  ) async {
    final areaIndex = areaGoals.indexWhere((g) => g.id == goal.id);
    final targetAreaIndex = areaIndex + direction;
    if (areaIndex == -1 ||
        targetAreaIndex < 0 ||
        targetAreaIndex >= areaGoals.length) {
      return;
    }

    final sectionGoals =
        (goal.section == 'activeGoals' ? activeGoals : longTermGoals).toList();
    final areaIds = areaGoals.map((g) => g.id).toSet();
    final sectionSlots = <int>[];
    for (var i = 0; i < sectionGoals.length; i++) {
      if (areaIds.contains(sectionGoals[i].id)) {
        sectionSlots.add(i);
      }
    }

    final reorderedArea = areaGoals.toList();
    final movedGoal = reorderedArea.removeAt(areaIndex);
    reorderedArea.insert(targetAreaIndex, movedGoal);

    for (var i = 0; i < sectionSlots.length; i++) {
      sectionGoals[sectionSlots[i]] = reorderedArea[i];
    }

    final reorderedSection = [
      for (var i = 0; i < sectionGoals.length; i++)
        sectionGoals[i].copyWith(orderIndex: i),
    ];

    setState(() {
      if (goal.section == 'activeGoals') {
        activeGoals = reorderedSection;
      } else {
        longTermGoals = reorderedSection;
      }
    });

    final saved = await _goalsService.updateGoalOrder(reorderedSection);
    if (!saved && mounted) {
      await _loadGoals();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save goal order')),
      );
    }
  }

  Widget _buildActiveView() {
    if (activeGoals.isEmpty) {
      return _buildEmptyState();
    }

    // Get primary goal (not affected by filters)
    final primaryGoal = activeGoals.firstWhere(
      (g) => g.isPrimary,
      orElse: () => activeGoals.isEmpty
          ? Goal(id: '', text: '', userId: '', section: '')
          : activeGoals.first,
    );

    // Get secondary goals (filtered)
    final secondaryGoals = filteredGoals
        .where((g) => g.id != primaryGoal.id)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Primary Goal Section
        if (primaryGoal.id.isNotEmpty) ...[
          Row(
            children: [
              Icon(
                Icons.star,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'PRIMARY FOCUS',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          KeyedSubtree(
            key: _primaryGoalKey,
            child: _buildGoalCard(primaryGoal, isPrimary: true),
          ),
          const SizedBox(height: 24),
        ],

        // Secondary Goals Section
        if (secondaryGoals.isNotEmpty) ...[
          Text(
            'SECONDARY GOALS',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          KeyedSubtree(
            key: _goalListKey,
            child: Column(
              children: secondaryGoals
                  .asMap()
                  .entries
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildGoalCard(
                        entry.value,
                        canMoveUp: entry.key > 0,
                        canMoveDown: entry.key < secondaryGoals.length - 1,
                        onMoveUp: () => _moveGoalWithinArea(
                          entry.value,
                          -1,
                          secondaryGoals,
                        ),
                        onMoveDown: () =>
                            _moveGoalWithinArea(entry.value, 1, secondaryGoals),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          KeyedSubtree(
            key: _primaryGoalKey,
            child: Icon(
              selectedTab == 'active' ? Icons.adjust : Icons.flag,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(80),
            ),
          ),
          const SizedBox(height: 16),
          KeyedSubtree(
            key: _goalListKey,
            child: Column(
              children: [
                Text(
                  selectedTab == 'active'
                      ? 'No active goals yet'
                      : 'No long-term goals yet',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to add your first goal',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInactiveView() {
    return filteredGoals.isEmpty
        ? _buildEmptyState()
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredGoals.length,
            itemBuilder: (context, index) {
              return _buildGoalCard(
                filteredGoals[index],
                canMoveUp: index > 0,
                canMoveDown: index < filteredGoals.length - 1,
                onMoveUp: () => _moveGoalWithinArea(
                  filteredGoals[index],
                  -1,
                  filteredGoals,
                ),
                onMoveDown: () =>
                    _moveGoalWithinArea(filteredGoals[index], 1, filteredGoals),
              );
            },
          );
  }

  Widget _buildCategorySelector() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        controller: _categoryScrollController,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(
          left: 16,
          right: MediaQuery.of(context).size.width * 0.75,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category['id'];
          return Padding(
            key: _categoryKeys[index],
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category['icon'],
                    size: 16,
                    color: isSelected
                        ? Colors.white
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(150),
                  ),
                  const SizedBox(width: 6),
                  Text(category['label']),
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
              side: BorderSide(
                color: isSelected
                    ? Colors.transparent
                    : Theme.of(context).dividerColor.withAlpha(40),
              ),
              onSelected: (selected) {
                setState(() => selectedCategory = category['id']);
                Future.delayed(const Duration(milliseconds: 50), () {
                  final keyContext = _categoryKeys[index].currentContext;
                  if (keyContext != null && keyContext.mounted) {
                    final box = keyContext.findRenderObject() as RenderBox?;
                    if (box != null && _categoryScrollController.hasClients) {
                      // Get absolute screen X of the chip
                      final screenX = box.localToGlobal(Offset.zero).dx;

                      // Get absolute screen X of the ListView viewport itself
                      final listViewBox =
                          _categoryScrollController
                                  .position
                                  .context
                                  .storageContext
                                  .findRenderObject()
                              as RenderBox?;
                      final viewportScreenX =
                          listViewBox?.localToGlobal(Offset.zero).dx ?? 0.0;

                      // We want the chip to sit exactly 16 pixels inside the viewport bounds
                      final targetScreenX = viewportScreenX + 16.0;

                      final shift = screenX - targetScreenX;
                      final targetOffset =
                          _categoryScrollController.offset + shift;

                      final maxScroll =
                          _categoryScrollController.position.maxScrollExtent;
                      final minScroll =
                          _categoryScrollController.position.minScrollExtent;
                      final clampedOffset = targetOffset.clamp(
                        minScroll,
                        maxScroll,
                      );

                      _categoryScrollController.animateTo(
                        clampedOffset,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  }
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeSelector() {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        key: const PageStorageKey('goal-type-filter-without-all'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildTypeFilter('Needs', 'need'),
            const SizedBox(width: 8),
            _buildTypeFilter('Desires', 'desire'),
            const SizedBox(width: 8),
            _buildTypeFilter('Assets', 'asset'),
            const SizedBox(width: 8),
            _buildTypeFilter('Liabilities', 'liability'),
          ],
        ),
      ),
    );
  }
}

class _GoalMetadata {
  final IconData icon;
  final String text;

  const _GoalMetadata({required this.icon, required this.text});
}
