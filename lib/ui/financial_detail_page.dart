import 'package:flutter/material.dart';
import 'widgets/ablerite_loading_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/focus_app_bar_actions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/item.dart';
import '../services/currency_service.dart';
import 'package:uuid/uuid.dart';
import 'widgets/auto_walkthrough.dart';
import 'widgets/spotlight_walkthrough.dart';

class FinancialDetailPage extends StatefulWidget {
  final String title;
  final String section; // 'assets', 'liabilities', 'income', 'expenses'
  final Color color;

  const FinancialDetailPage({
    super.key,
    required this.title,
    required this.section,
    required this.color,
  });

  @override
  State<FinancialDetailPage> createState() => _FinancialDetailPageState();
}

enum SortOption {
  dateDesc,
  dateAsc,
  amountDesc,
  amountAsc,
  nameAsc,
  nameDesc,
  manual,
}

class _FinancialDetailPageState extends State<FinancialDetailPage> {
  final GlobalKey _summaryKey = GlobalKey();
  final GlobalKey _primarySectionKey = GlobalKey();
  final GlobalKey _secondarySectionKey = GlobalKey();
  final GlobalKey _tertiarySectionKey = GlobalKey();
  final GlobalKey _sortKey = GlobalKey();
  List<Item> items = [];
  List<Item> liabilities = [];
  List<Item> milestones = [];
  bool isLoading = true;
  bool _isPersistingOrder = false;
  String _currencySymbol = '\$';
  SortOption _currentSortOption = SortOption.manual;

  // For income view
  double _totalIncome = 0.0;

  // Realtime subscription for sync
  RealtimeChannel? _itemsSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _itemsSubscription?.unsubscribe();
    super.dispose();
  }

  void _showWalkthrough() {
    SpotlightWalkthrough.show(context, steps: _walkthroughSteps);
  }

  List<SpotlightStep> get _walkthroughSteps {
    return [
      SpotlightStep(
        targetKey: _summaryKey,
        title: '${widget.title} Overview',
        body: widget.section == 'assets'
            ? 'See total assets, liabilities, net worth, and progress toward your next goal at a glance.'
            : widget.section == 'income'
            ? 'See your total income, next milestone, amount remaining, and goal progress.'
            : 'Compare income and expenses, track budget use, and see how much remains.',
      ),
      if (widget.section == 'assets') ...[
        SpotlightStep(
          targetKey: _primarySectionKey,
          title: 'Net Worth Milestones',
          body:
              'Add and reorder targets that mark your progress toward a stronger net worth.',
        ),
        SpotlightStep(
          targetKey: _secondarySectionKey,
          title: 'Assets',
          body:
              'Add the things you own and their values. Tap an item to update it.',
        ),
        SpotlightStep(
          targetKey: _tertiarySectionKey,
          title: 'Liabilities',
          body:
              'Add debts and other liabilities so your net worth stays accurate.',
        ),
      ] else if (widget.section == 'income') ...[
        SpotlightStep(
          targetKey: _primarySectionKey,
          title: 'Income Sources',
          body:
              'Use the plus button to add each regular or additional source of income.',
        ),
        SpotlightStep(
          targetKey: _secondarySectionKey,
          title: 'Revenue Milestones',
          body:
              'Set income targets and hold to reorder them as your priorities change.',
        ),
      ] else if (widget.section == 'expenses')
        SpotlightStep(
          targetKey: _primarySectionKey,
          title: 'Expense Items',
          body:
              'Add and categorise your spending here to keep the monthly total current.',
        ),
      SpotlightStep(
        targetKey: _sortKey,
        title: 'Sort and Reorder',
        body:
            'Change how entries are ordered by date, amount, name, or your own manual order.',
      ),
    ];
  }

  void _maybeAutoStartWalkthrough() {
    if (isLoading) return;
    AutoWalkthrough.maybeShowOnce(
      context,
      id: 'financial-detail-${widget.section}',
      steps: _walkthroughSteps,
    );
  }

  void _setupRealtimeSubscription() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _itemsSubscription = Supabase.instance.client
        .channel('items-changes-${widget.section}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'items',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            if (!_isPersistingOrder) _loadData();
          },
        )
        .subscribe();
  }

  Future<void> _loadData() async {
    try {
      final currency = await CurrencyService.fetchFromSupabase();
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      setState(() => _currencySymbol = CurrencyService.getSymbol(currency));

      if (widget.section == 'assets') {
        // Load assets, liabilities, and net worth milestones.
        final assetsResponse = await Supabase.instance.client
            .from('items')
            .select()
            .eq('user_id', userId)
            .eq('section', 'assets')
            .order('order_index', ascending: true)
            .order('created_at', ascending: false);

        final liabilitiesResponse = await Supabase.instance.client
            .from('items')
            .select()
            .eq('user_id', userId)
            .eq('section', 'liabilities')
            .order('order_index', ascending: true)
            .order('created_at', ascending: false);

        final milestonesResponse = await Supabase.instance.client
            .from('items')
            .select()
            .eq('user_id', userId)
            .eq('section', 'net_worth_milestones')
            .order('order_index', ascending: true);

        setState(() {
          items = assetsResponse
              .map<Item>((json) => Item.fromJson(json))
              .toList();
          liabilities = liabilitiesResponse
              .map<Item>((json) => Item.fromJson(json))
              .toList();
          milestones = milestonesResponse
              .map<Item>((json) => Item.fromJson(json))
              .toList();
          isLoading = false;
        });
      } else if (widget.section == 'income') {
        // Load income sources and income milestones
        final incomeResponse = await Supabase.instance.client
            .from('items')
            .select()
            .eq('user_id', userId)
            .eq('section', 'income')
            .order('order_index', ascending: true)
            .order('created_at', ascending: false);

        final milestonesResponse = await Supabase.instance.client
            .from('items')
            .select()
            .eq('user_id', userId)
            .eq('section', 'income_milestones')
            .order('order_index', ascending: true);

        setState(() {
          items = incomeResponse
              .map<Item>((json) => Item.fromJson(json))
              .toList();
          milestones = milestonesResponse
              .map<Item>((json) => Item.fromJson(json))
              .toList();
          isLoading = false;
        });
      } else if (widget.section == 'expenses') {
        // Load expenses and also income for budget remaining calculation
        final expensesResponse = await Supabase.instance.client
            .from('items')
            .select()
            .eq('user_id', userId)
            .eq('section', 'expenses')
            .order('order_index', ascending: true)
            .order('created_at', ascending: false);

        final incomeResponse = await Supabase.instance.client
            .from('items')
            .select()
            .eq('user_id', userId)
            .eq('section', 'income');

        setState(() {
          items = expensesResponse
              .map<Item>((json) => Item.fromJson(json))
              .toList();
          _totalIncome = incomeResponse.fold(
            0.0,
            (sum, item) => sum + ((item['value'] as num?)?.toDouble() ?? 0.0),
          );
          isLoading = false;
        });
      } else if (widget.section == 'net_worth_milestones') {
        // Load net worth milestones directly
        final milestonesResponse = await Supabase.instance.client
            .from('items')
            .select()
            .eq('user_id', userId)
            .eq('section', 'net_worth_milestones')
            .order('order_index', ascending: true);

        setState(() {
          milestones = milestonesResponse
              .map<Item>((json) => Item.fromJson(json))
              .toList();
          isLoading = false;
        });
      } else if (widget.section == 'income_milestones') {
        // Load income milestones directly
        final milestonesResponse = await Supabase.instance.client
            .from('items')
            .select()
            .eq('user_id', userId)
            .eq('section', 'income_milestones')
            .order('order_index', ascending: true);

        setState(() {
          milestones = milestonesResponse
              .map<Item>((json) => Item.fromJson(json))
              .toList();
          isLoading = false;
        });
      } else {
        // Generic section
        final response = await Supabase.instance.client
            .from('items')
            .select()
            .eq('user_id', userId)
            .eq('section', widget.section)
            .order('order_index', ascending: true)
            .order('created_at', ascending: false);

        setState(() {
          items = response.map<Item>((json) => Item.fromJson(json)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading items: $e');
      setState(() => isLoading = false);
    }
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      symbol: _currencySymbol,
      decimalDigits: 0,
    );
    return formatter.format(value.round());
  }

  double get _totalAssets =>
      items.fold(0.0, (sum, item) => sum + (item.value?.toDouble() ?? 0.0));
  double get _totalLiabilities => liabilities.fold(
    0.0,
    (sum, item) => sum + (item.value?.toDouble() ?? 0.0),
  );
  double get _netWorth => _totalAssets - _totalLiabilities;
  double get _totalItemsValue =>
      items.fold(0.0, (sum, item) => sum + (item.value?.toDouble() ?? 0.0));
  double get _remainingBudget => _totalIncome - _totalItemsValue;

  Item? get _nextMilestone {
    final total = widget.section == 'assets' ? _netWorth : _totalItemsValue;
    for (final m in milestones) {
      if (m.completed != true && (m.value?.toDouble() ?? 0) > total) {
        return m;
      }
    }
    return null;
  }

  Item? get _netWorthTarget {
    final targets =
        milestones.where((m) => (m.value?.toDouble() ?? 0) > 0).toList()
          ..sort((a, b) => (b.value ?? 0).compareTo(a.value ?? 0));
    if (targets.isNotEmpty) return targets.first;
    return milestones.isNotEmpty ? milestones.last : null;
  }

  Future<void> _openNetWorthTargetEditor() async {
    final target = _netWorthTarget;
    if (target == null) {
      await _addItem('net_worth_milestones');
    } else {
      await _editItem(target, 'net_worth_milestones');
    }
  }

  Future<void> _addItem(String section) async {
    final nameController = TextEditingController();
    final valueController = TextEditingController();
    DateTime? selectedDate;
    String selectedCategory = '';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            _getAddTitle(section),
            style: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    labelText: section.contains('milestone')
                        ? 'Milestone Name'
                        : 'Name',
                    labelStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(50),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: widget.color),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: valueController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount ($_currencySymbol)',
                    labelStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(50),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: widget.color),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (section.contains('milestone')) ...[
                  const SizedBox(height: 16),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme:
                                      Theme.of(
                                            context,
                                          ).colorScheme.brightness ==
                                          Brightness.dark
                                      ? ColorScheme.dark(
                                          primary: widget.color,
                                          onPrimary: Theme.of(
                                            context,
                                          ).colorScheme.onPrimary,
                                          surface: Theme.of(
                                            context,
                                          ).colorScheme.surface,
                                          onSurface: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        )
                                      : ColorScheme.light(
                                          primary: widget.color,
                                          onPrimary: Colors.white,
                                          surface: Colors.white,
                                          onSurface: Colors.black,
                                        ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (date != null) {
                            setDialogState(() => selectedDate = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).dividerColor.withAlpha(50),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedDate != null
                                    ? DateFormat(
                                        'MMM d, yyyy',
                                      ).format(selectedDate!)
                                    : 'Target Date (Optional)',
                                style: TextStyle(
                                  color: selectedDate != null
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurface.withAlpha(120),
                                ),
                              ),
                              Icon(
                                Icons.calendar_today,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(120),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: -8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'SMART Goal',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (section == 'expenses') ...[
                  const SizedBox(height: 16),
                  Text(
                    'Category',
                    style: GoogleFonts.outfit(color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        [
                          'housing',
                          'food',
                          'transport',
                          'utilities',
                          'entertainment',
                          'other',
                        ].map((cat) {
                          final isSelected = selectedCategory == cat;
                          return GestureDetector(
                            onTap: () =>
                                setDialogState(() => selectedCategory = cat),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _getCategoryColor(
                                        cat,
                                      ).withValues(alpha: 0.2)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? _getCategoryColor(cat)
                                      : Theme.of(
                                          context,
                                        ).dividerColor.withAlpha(50),
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                cat.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? _getCategoryColor(cat)
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    valueController.text.isEmpty) {
                  return;
                }

                final userId = Supabase.instance.client.auth.currentUser?.id;
                if (userId == null) return;

                try {
                  final data = {
                    'id': const Uuid().v4(),
                    'user_id': userId,
                    'section': section,
                    'text': nameController.text,
                    'value': int.parse(valueController.text),
                    'created_at': DateTime.now().toIso8601String(),
                  };
                  final nextOrderIndex = _nextOrderIndexForSection(section);
                  if (nextOrderIndex != null) {
                    data['order_index'] = nextOrderIndex;
                  }

                  if (selectedCategory.isNotEmpty) {
                    data['category'] = selectedCategory;
                  }
                  if (selectedDate != null) {
                    data['target_date'] = selectedDate!.toIso8601String();
                  }

                  await Supabase.instance.client.from('items').insert(data);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _loadData();
                } catch (e) {
                  debugPrint('Error adding item: $e');
                }
              },
              child: Text(
                'Add',
                style: GoogleFonts.outfit(color: widget.color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getAddTitle(String section) {
    switch (section) {
      case 'assets':
        return 'Add Asset';
      case 'liabilities':
        return 'Add Liability';
      case 'income':
        return 'Add Income Source';
      case 'expenses':
        return 'Add Expense';
      case 'net_worth_milestones':
        return 'Add Net Worth Milestone';
      case 'income_milestones':
        return 'Add Income Milestone';
      default:
        return 'Add Item';
    }
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'housing':
        return Colors.red[400]!;
      case 'food':
        return Colors.amber[400]!;
      case 'transport':
        return Colors.orange[400]!;
      case 'utilities':
        return Colors.blue[400]!;
      case 'entertainment':
        return Colors.purple[400]!;
      default:
        return Colors.grey[400]!;
    }
  }

  int? _nextOrderIndexForSection(String section) {
    final sectionItems = section == 'liabilities'
        ? liabilities
        : section.contains('milestone')
        ? milestones
        : items;
    final indexedItems = sectionItems.where((item) => item.orderIndex != null);
    if (indexedItems.isEmpty) return null;
    return indexedItems
            .map((item) => item.orderIndex!)
            .reduce((a, b) => a > b ? a : b) +
        1;
  }

  Future<void> _editItem(Item item, String section) async {
    final nameController = TextEditingController(text: item.text);
    final valueController = TextEditingController(
      text: item.value?.toString() ?? '',
    );
    DateTime? selectedDate = item.targetDate != null
        ? DateTime.parse(item.targetDate!)
        : null;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'Edit ${item.text}',
            style: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor.withAlpha(50),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: widget.color),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valueController,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount ($_currencySymbol)',
                  labelStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor.withAlpha(50),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: widget.color),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (section.contains('milestone')) ...[
                const SizedBox(height: 16),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme:
                                    Theme.of(context).colorScheme.brightness ==
                                        Brightness.dark
                                    ? ColorScheme.dark(
                                        primary: widget.color,
                                        onPrimary: Theme.of(
                                          context,
                                        ).colorScheme.onPrimary,
                                        surface: Theme.of(
                                          context,
                                        ).colorScheme.surface,
                                        onSurface: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      )
                                    : ColorScheme.light(
                                        primary: widget.color,
                                        onPrimary: Colors.white,
                                        surface: Colors.white,
                                        onSurface: Colors.black,
                                      ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          setDialogState(() => selectedDate = date);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).dividerColor.withAlpha(50),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedDate != null
                                  ? DateFormat(
                                      'MMM d, yyyy',
                                    ).format(selectedDate!)
                                  : 'Target Date (Optional)',
                              style: TextStyle(
                                color: selectedDate != null
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withAlpha(120),
                              ),
                            ),
                            Icon(
                              Icons.calendar_today,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(120),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'SMART Goal',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await Supabase.instance.client
                      .from('items')
                      .delete()
                      .eq('id', item.id);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _loadData();
                } catch (e) {
                  debugPrint('Error deleting item: $e');
                }
              },
              child: Text(
                'Delete',
                style: GoogleFonts.outfit(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    valueController.text.isEmpty) {
                  return;
                }

                try {
                  final Map<String, dynamic> updateData = {
                    'text': nameController.text,
                    'value': int.parse(valueController.text),
                  };
                  if (section.contains('milestone')) {
                    updateData['target_date'] =
                        selectedDate?.toIso8601String() ??
                        ''; // Or null if your DB accepts nulls differently; empty string might fail for date columns. Let's use an explicit null if appropriate.
                    // Actually, Supabase takes null for optional dates. We need a way to clear it. For now let's set it.
                    if (selectedDate != null) {
                      updateData['target_date'] = selectedDate!
                          .toIso8601String();
                    } else {
                      updateData['target_date'] =
                          null; // Assuming Supabase Dart parses null properly
                    }
                  }
                  await Supabase.instance.client
                      .from('items')
                      .update(updateData)
                      .eq('id', item.id);

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _loadData();
                } catch (e) {
                  debugPrint('Error updating item: $e');
                }
              },
              child: Text(
                'Save',
                style: GoogleFonts.outfit(color: widget.color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleMilestoneComplete(Item item) async {
    try {
      await Supabase.instance.client
          .from('items')
          .update({'is_completed': !(item.completed ?? false)})
          .eq('id', item.id);
      _loadData();
    } catch (e) {
      debugPrint('Error toggling milestone: $e');
    }
  }

  Future<void> _reorderMilestones(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;

    setState(() {
      final item = milestones.removeAt(oldIndex);
      milestones.insert(newIndex, item);
    });

    // Update order_index for all milestones
    _isPersistingOrder = true;
    try {
      for (int i = 0; i < milestones.length; i++) {
        await Supabase.instance.client
            .from('items')
            .update({'order_index': i})
            .eq('id', milestones[i].id);
      }
    } catch (e) {
      debugPrint('Error reordering milestones: $e');
      _loadData(); // Reload on error
    } finally {
      _isPersistingOrder = false;
    }
  }

  Future<void> _onReorder(
    List<Item> currentList,
    int oldIndex,
    int newIndex,
    String section,
  ) async {
    if (oldIndex == newIndex) return;

    // Optimistically update UI
    setState(() {
      final item = currentList.removeAt(oldIndex);
      currentList.insert(newIndex, item);
      _currentSortOption = SortOption.manual;

      // Update the main lists based on the section
      if (section == 'assets' ||
          section == 'income' ||
          section.contains('milestone')) {
        // assets, income, etc are in `items`
        // But wait, `items` contains everything if section is 'assets'? No.
        // `_loadData` sets `items` to `assetsResponse`.
        // So if we are reordering 'assets', we are modifying `items`.
        // If we are reordering 'liabilities', we are modifying `liabilities`.
      }

      // We need to sync the reordered list back to the source list (`items` or `liabilities`)
      // However, `currentList` is a COPY from `_getSortedItems`.
      // We need to apply this new order to the source list.
      // Since we are in manual mode now, `_getSortedItems` will sort by `orderIndex`.
      // So we just need to update `orderIndex` on the items in the source list.
      // But `Item` is immutable.

      // Let's create a map of id -> newIndex
      final orderMap = <String, int>{};
      for (int i = 0; i < currentList.length; i++) {
        orderMap[currentList[i].id] = i;
      }

      // Helper to update a list
      List<Item> updateList(List<Item> list) {
        return list.map((item) {
          if (orderMap.containsKey(item.id)) {
            return item.copyWith(orderIndex: orderMap[item.id]);
          }
          return item;
        }).toList(); // Sort logic will handle the rest?
        // No, `_getSortedItems` sorts by `orderIndex`.
        // So if we update `orderIndex`, the list will be sorted correctly.
      }

      if (section == 'liabilities') {
        liabilities = updateList(liabilities);
      } else {
        items = updateList(items);
      }
    });

    // Persist to Supabase
    _isPersistingOrder = true;
    try {
      // We need the items in their new order to assign indices
      // `currentList` has the new order.
      for (int i = 0; i < currentList.length; i++) {
        await Supabase.instance.client
            .from('items')
            .update({'order_index': i})
            .eq('id', currentList[i].id);
      }
    } catch (e) {
      debugPrint('Error reordering items: $e');
      _loadData(); // Revert on error
    } finally {
      _isPersistingOrder = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final greenColor = isDark ? Colors.greenAccent : Colors.green[700]!;
    final redColor = isDark ? Colors.redAccent : Colors.red[700]!;
    if (!isLoading) _maybeAutoStartWalkthrough();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leadingWidth: 44,
        titleSpacing: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: FocusAwareAppBarTitle(
          focusOffset: 28,
          child: Text(
            widget.title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        leading: const FocusAwareBackButton(),
        actions: [
          const FocusAppBarActions(guide: FocusHelpGuide.finance),
          IconButton(
            constraints: const BoxConstraints.tightFor(width: 36, height: 40),
            padding: const EdgeInsets.all(6),
            iconSize: 20,
            icon: const Icon(Icons.help_outline),
            tooltip: '${widget.title} walkthrough',
            onPressed: _showWalkthrough,
          ),
          SizedBox(
            width: 36,
            height: 40,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildSortButton(),
                IgnorePointer(
                  child: ColoredBox(key: _sortKey, color: Colors.transparent),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: isLoading
          ? Center(
              child: AbleriteLoadingIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Multi-metric Summary Header
                    KeyedSubtree(
                      key: _summaryKey,
                      child: _buildSummaryHeader(),
                    ),
                    const SizedBox(height: 16),

                    // Content based on section
                    if (widget.section == 'assets') ...[
                      KeyedSubtree(
                        key: _primarySectionKey,
                        child: _buildMilestonesSection(
                          'Net Worth Milestones',
                          'net_worth_milestones',
                        ),
                      ),
                      const SizedBox(height: 16),
                      KeyedSubtree(
                        key: _secondarySectionKey,
                        child: _buildItemsSection(
                          'Assets',
                          items,
                          greenColor,
                          'assets',
                        ),
                      ),
                      const SizedBox(height: 16),
                      KeyedSubtree(
                        key: _tertiarySectionKey,
                        child: _buildItemsSection(
                          'Liabilities',
                          liabilities,
                          redColor,
                          'liabilities',
                        ),
                      ),
                    ] else if (widget.section == 'income') ...[
                      KeyedSubtree(
                        key: _primarySectionKey,
                        child: _buildItemsSection(
                          'Income Sources',
                          items,
                          greenColor,
                          'income',
                        ),
                      ),
                      const SizedBox(height: 16),
                      KeyedSubtree(
                        key: _secondarySectionKey,
                        child: _buildMilestonesSection(
                          'Revenue Milestones',
                          'income_milestones',
                        ),
                      ),
                    ] else if (widget.section == 'expenses') ...[
                      KeyedSubtree(
                        key: _primarySectionKey,
                        child: _buildItemsSection(
                          'Expense Items',
                          items,
                          redColor,
                          'expenses',
                          showCategory: true,
                        ),
                      ),
                    ] else ...[
                      _buildItemsSection(
                        widget.title,
                        items,
                        widget.color,
                        widget.section,
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final greenColor = isDark ? Colors.greenAccent : Colors.green[700]!;
    final redColor = isDark ? Colors.redAccent : Colors.red[700]!;

    if (widget.section == 'assets') {
      // Net Worth: 4 metrics
      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withAlpha(100),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withAlpha(50),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Assets',
                    _totalAssets,
                    greenColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    'Total Liabilities',
                    _totalLiabilities,
                    redColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Net Worth',
                    _netWorth,
                    _netWorth >= 0 ? greenColor : redColor,
                    highlight: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _buildMilestoneProgress()),
              ],
            ),
          ],
        ),
      );
    } else if (widget.section == 'income') {
      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withAlpha(100),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withAlpha(50),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Income',
                    _totalItemsValue,
                    greenColor,
                    highlight: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _buildNextMilestoneCard()),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildGapCard()),
                const SizedBox(width: 8),
                Expanded(child: _buildMilestoneProgress()),
              ],
            ),
          ],
        ),
      );
    } else if (widget.section == 'expenses') {
      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withAlpha(100),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withAlpha(50),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Income',
                    _totalIncome,
                    greenColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    'Total Expenses',
                    _totalItemsValue,
                    redColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildBudgetUsedCard()),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    'Remaining',
                    _remainingBudget,
                    _remainingBudget >= 0 ? greenColor : redColor,
                    highlight: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Default single metric
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total',
            style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[400]),
          ),
          Text(
            _formatCurrency(_totalItemsValue),
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    double value,
    Color valueColor, {
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: highlight
            ? valueColor.withValues(alpha: 0.1)
            : Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
        border: highlight
            ? Border.all(color: valueColor.withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 9,
              color: highlight ? valueColor : Colors.grey[500],
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _formatCurrency(value),
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextMilestoneCard() {
    final next = _nextMilestone;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'NEXT MILESTONE',
            style: GoogleFonts.outfit(
              fontSize: 9,
              color: Colors.grey[500],
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            next != null
                ? _formatCurrency(next.value?.toDouble() ?? 0)
                : 'Not set',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: next != null
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.grey,
            ),
          ),
          if (next?.targetDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'by ${DateFormat('MMM yyyy').format(DateTime.parse(next!.targetDate!))}',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: Colors.grey[400],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGapCard() {
    final next = _nextMilestone;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? Colors.white70 : Colors.black87;
    final target = next?.value?.toDouble() ?? _totalItemsValue;
    final gap = (target - _totalItemsValue)
        .clamp(0, double.infinity)
        .toDouble();

    return _buildMetricCard('To Milestone', gap, defaultColor);
  }

  Widget _buildBudgetUsedCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amberColor = isDark ? Colors.amber : Colors.orange[800]!;
    final greenColor = isDark ? Colors.greenAccent : Colors.green[700]!;
    final redColor = isDark ? Colors.redAccent : Colors.red[700]!;

    final ratio = _totalIncome > 0
        ? (_totalItemsValue / _totalIncome * 100)
        : 0.0;
    final color = ratio > 100
        ? redColor
        : (ratio > 80 ? amberColor : greenColor);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'BUDGET USED',
            style: GoogleFonts.outfit(
              fontSize: 9,
              color: Colors.grey[500],
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${ratio.round()}%',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneProgress() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final purpleColor = isDark ? Colors.purple[300]! : Colors.purple[700]!;

    final next = _nextMilestone;
    final netWorthTarget = _netWorthTarget;
    final current = widget.section == 'assets' ? _netWorth : _totalItemsValue;
    final canEditTarget = widget.section == 'assets';
    final target = canEditTarget
        ? netWorthTarget?.value?.toDouble()
        : next?.value?.toDouble() ?? current;
    final progress = target != null && target > 0
        ? (current / target * 100).clamp(0, 100)
        : 0;
    final targetDate = canEditTarget ? netWorthTarget?.targetDate : null;
    final parsedTargetDate = targetDate == null
        ? null
        : DateTime.tryParse(targetDate);
    final targetDueLabel = parsedTargetDate == null
        ? null
        : 'by ${DateFormat('MMM yyyy').format(parsedTargetDate)}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: purpleColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: purpleColor.withValues(alpha: 0.3)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  'GOAL PROGRESS',
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    color: purpleColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${progress.round()}%',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: purpleColor,
                  ),
                ),
                if (targetDueLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    targetDueLabel,
                    style: GoogleFonts.outfit(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: purpleColor.withValues(alpha: 0.75),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (canEditTarget)
            Positioned(
              top: -8,
              right: -4,
              child: IconButton(
                onPressed: _openNetWorthTargetEditor,
                icon: Icon(Icons.edit_outlined, size: 15, color: purpleColor),
                tooltip: 'Edit net worth target',
                constraints: const BoxConstraints.tightFor(
                  width: 28,
                  height: 28,
                ),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                splashRadius: 16,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMilestonesSection(String title, String section) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final purpleColor = isDark ? Colors.purple[300]! : Colors.purple[700]!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withAlpha(100),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: purpleColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.flag, size: 16, color: purpleColor),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    'Hold to reorder',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _addItem(section),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: purpleColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.add, size: 16, color: purpleColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (milestones.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'No milestones set.',
                  style: GoogleFonts.outfit(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: milestones.length,
              onReorderItem: _reorderMilestones,
              proxyDecorator: (child, index, animation) {
                return Material(
                  color: Colors.transparent,
                  elevation: 4,
                  child: child,
                );
              },
              itemBuilder: (context, index) {
                final item = milestones[index];
                return ReorderableDelayedDragStartListener(
                  key: ValueKey(item.id),
                  index: index,
                  child: _buildMilestoneItem(item, section),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMilestoneItem(Item item, String section) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = item.completed ?? false;
    final greenColor = isDark ? Colors.green : Colors.green[700]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isCompleted
            ? greenColor.withValues(alpha: 0.1)
            : Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCompleted
              ? greenColor.withValues(alpha: 0.3)
              : Theme.of(context).dividerColor.withAlpha(50),
          style: isCompleted ? BorderStyle.solid : BorderStyle.none,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _toggleMilestoneComplete(item),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? greenColor : Colors.transparent,
                border: Border.all(
                  color: isCompleted ? greenColor : Colors.grey,
                ),
              ),
              child: isCompleted
                  ? Icon(
                      Icons.check,
                      size: 14,
                      color: isDark ? Colors.white : Colors.black,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.text,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: isCompleted
                              ? greenColor
                              : Theme.of(context).colorScheme.onSurface,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.targetDate != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: greenColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'SMART',
                          style: GoogleFonts.outfit(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: greenColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    if (item.value != null)
                      Text(
                        _formatCurrency(item.value!.toDouble()),
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    if (item.targetDate != null) ...[
                      Text(
                        ' • ',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        DateFormat(
                          'MMM d, yyyy',
                        ).format(DateTime.parse(item.targetDate!)),
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _editItem(item, section),
            child: Icon(Icons.edit, size: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(
    String title,
    List<Item> sectionItems,
    Color color,
    String section, {
    bool showCategory = false,
  }) {
    final total = sectionItems.fold(
      0.0,
      (sum, item) => sum + (item.value?.toDouble() ?? 0.0),
    );
    final displayedItems = _getSortedItems(sectionItems);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withAlpha(100),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    section == 'assets'
                        ? Icons.trending_up
                        : section == 'liabilities'
                        ? Icons.trending_down
                        : section == 'income'
                        ? Icons.attach_money
                        : Icons.shopping_bag,
                    size: 16,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    _formatCurrency(total),
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _addItem(section),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.add, size: 16, color: color),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (sectionItems.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'No items yet.',
                  style: GoogleFonts.outfit(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else if (_currentSortOption == SortOption.manual)
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: displayedItems.length,
              proxyDecorator: (child, index, animation) {
                return Material(
                  color: Colors.transparent,
                  elevation: 4,
                  child: child,
                );
              },
              onReorderItem: (oldIndex, newIndex) {
                _onReorder(displayedItems, oldIndex, newIndex, section);
              },
              itemBuilder: (context, index) {
                final item = displayedItems[index];
                return Container(
                  key: ValueKey(item.id),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: _buildFinancialItem(
                    item,
                    color,
                    section,
                    showCategory: showCategory,
                    dragIndex: index,
                  ),
                );
              },
            )
          else
            ...displayedItems.map(
              (item) => _buildFinancialItem(
                item,
                color,
                section,
                showCategory: showCategory,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFinancialItem(
    Item item,
    Color color,
    String section, {
    bool showCategory = false,
    int? dragIndex,
  }) {
    return GestureDetector(
      onTap: () => _editItem(item, section),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withAlpha(50),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).dividerColor.withAlpha(30),
          ),
        ),
        child: Row(
          children: [
            if (dragIndex != null)
              ReorderableDragStartListener(
                index: dragIndex,
                child: const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.drag_handle, color: Colors.grey),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.text,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (showCategory && item.category != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(
                          item.category,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.category!.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: _getCategoryColor(item.category),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              _formatCurrency(item.value?.toDouble() ?? 0),
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Item> _getSortedItems(List<Item> inputItems) {
    final sorted = List<Item>.from(inputItems);
    switch (_currentSortOption) {
      case SortOption.dateDesc:
        sorted.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
        break;
      case SortOption.dateAsc:
        sorted.sort((a, b) => (a.createdAt ?? '').compareTo(b.createdAt ?? ''));
        break;
      case SortOption.amountDesc:
        sorted.sort((a, b) => (b.value ?? 0).compareTo(a.value ?? 0));
        break;
      case SortOption.amountAsc:
        sorted.sort((a, b) => (a.value ?? 0).compareTo(b.value ?? 0));
        break;
      case SortOption.nameAsc:
        sorted.sort((a, b) => (a.text).compareTo(b.text));
        break;
      case SortOption.nameDesc:
        sorted.sort((a, b) => (b.text).compareTo(a.text));
        break;
      case SortOption.manual:
        sorted.sort((a, b) {
          final indexA = a.orderIndex ?? 999999;
          final indexB = b.orderIndex ?? 999999;
          if (indexA != indexB) return indexA.compareTo(indexB);
          // Fallback to createdAt if orderIndex is same (e.g. null)
          return (b.createdAt ?? '').compareTo(a.createdAt ?? '');
        });
        break;
    }
    return sorted;
  }

  Widget _buildSortButton() {
    return PopupMenuButton<SortOption>(
      icon: Icon(
        Icons.sort,
        color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
        size: 24,
      ),
      color: Theme.of(context).colorScheme.surface,
      onSelected: (SortOption result) {
        setState(() {
          _currentSortOption = result;
        });
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOption>>[
        _buildPopupMenuItem(SortOption.dateDesc, 'Date (Newest)'),
        _buildPopupMenuItem(SortOption.dateAsc, 'Date (Oldest)'),
        _buildPopupMenuItem(SortOption.amountDesc, 'Amount (High to Low)'),
        _buildPopupMenuItem(SortOption.amountAsc, 'Amount (Low to High)'),
        _buildPopupMenuItem(SortOption.nameAsc, 'Name (A-Z)'),
        _buildPopupMenuItem(SortOption.nameDesc, 'Name (Z-A)'),
        _buildPopupMenuItem(SortOption.manual, 'Manual (Drag & Drop)'),
      ],
    );
  }

  PopupMenuItem<SortOption> _buildPopupMenuItem(SortOption value, String text) {
    return PopupMenuItem<SortOption>(
      value: value,
      child: Row(
        children: [
          if (_currentSortOption == value)
            Icon(Icons.check, size: 16, color: widget.color)
          else
            const SizedBox(width: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
