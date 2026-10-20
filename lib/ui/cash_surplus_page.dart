import 'package:flutter/material.dart';
import 'widgets/ablerite_loading_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/focus_app_bar_actions.dart';
import 'package:intl/intl.dart';
import 'widgets/confirmation_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/financial_service.dart';
import '../services/currency_service.dart';
import '../models/cash_item.dart';
import 'widgets/auto_walkthrough.dart';
import 'widgets/spotlight_walkthrough.dart';

class CashSurplusPage extends StatefulWidget {
  const CashSurplusPage({super.key});

  @override
  State<CashSurplusPage> createState() => _CashSurplusPageState();
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

class _CashSurplusPageState extends State<CashSurplusPage> {
  final GlobalKey _summaryKey = GlobalKey();
  final GlobalKey _plannedKey = GlobalKey();
  final GlobalKey _activeKey = GlobalKey();
  final GlobalKey _addKey = GlobalKey();
  final GlobalKey _sortKey = GlobalKey();
  final FinancialService _financialService = FinancialService();
  final SupabaseClient _client = Supabase.instance.client;

  bool _isLoading = true;
  double _totalSurplus = 0.0;
  double _monthlyIncome = 0.0;
  double _monthlyExpenses = 0.0;
  List<CashItem> _items = [];
  String _currencySymbol = '\$';
  SortOption _currentSortOption = SortOption.dateDesc;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final currency = await CurrencyService.fetchFromSupabase();
      final metrics = await _financialService.getFinancialMetrics();
      final itemsData = await _financialService.getCashPlannerItems();

      setState(() {
        _currencySymbol = CurrencyService.getSymbol(currency);
        _monthlyIncome = metrics['income'] ?? 0.0;
        _monthlyExpenses = metrics['budget'] ?? 0.0;
        _totalSurplus = _monthlyIncome - _monthlyExpenses;
        _items = itemsData.map((json) => CashItem.fromJson(json)).toList();
        _isLoading = false;
      });
      _maybeAutoStartWalkthrough();
    } catch (e) {
      debugPrint('Error fetching cash surplus data: $e');
      setState(() => _isLoading = false);
      _maybeAutoStartWalkthrough();
    }
  }

  double get _activeSpend => _items
      .where((i) => i.isCompleted)
      .fold(0.0, (sum, item) => sum + item.value);

  double get _plannedAmount => _items
      .where((i) => !i.isCompleted)
      .fold(0.0, (sum, item) => sum + item.value);

  double get _remainingCash => _totalSurplus - _activeSpend;

  List<CashItem> get _plannedItems =>
      _sortedItems.where((i) => !i.isCompleted).toList();
  List<CashItem> get _activeItems =>
      _sortedItems.where((i) => i.isCompleted).toList();

  void _showWalkthrough() {
    SpotlightWalkthrough.show(context, steps: _walkthroughSteps);
  }

  List<SpotlightStep> get _walkthroughSteps {
    return [
      SpotlightStep(
        targetKey: _summaryKey,
        title: 'Surplus Overview',
        body:
            'See your available surplus, active spending, planned allocations, and remaining cash.',
      ),
      SpotlightStep(
        targetKey: _plannedKey,
        title: 'Planned',
        body:
            'Future allocations live here until you are ready to mark them as active spending.',
      ),
      SpotlightStep(
        targetKey: _activeKey,
        title: 'Active Spend',
        body:
            'Track allocations that are currently in use and how they reduce your remaining cash.',
      ),
      SpotlightStep(
        targetKey: _addKey,
        title: 'Add an Allocation',
        body: 'Create a new planned or active use for your cash surplus.',
      ),
      SpotlightStep(
        targetKey: _sortKey,
        title: 'Sort and Reorder',
        body: 'Order allocations by date, amount, name, or manually.',
      ),
    ];
  }

  void _maybeAutoStartWalkthrough() {
    if (_isLoading) return;
    AutoWalkthrough.maybeShowOnce(
      context,
      id: 'cash-surplus',
      steps: _walkthroughSteps,
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: _currencySymbol,
      decimalDigits: 0,
    );
    return formatter.format(amount.round());
  }

  Future<void> _toggleItemStatus(CashItem item) async {
    try {
      await _client
          .from('items')
          .update({'is_completed': !item.isCompleted})
          .eq('id', item.id);
      await _fetchData();
    } catch (e) {
      debugPrint('Error toggling item status: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating item: $e')));
    }
  }

  Future<void> _deleteItem(CashItem item) async {
    final confirmed = await showDeleteBottomSheet(
      context,
      title: 'Delete Item?',
      subtitle: 'Are you sure you want to delete "${item.label}"?',
    );

    if (confirmed == true) {
      try {
        await _client.from('items').delete().eq('id', item.id);
        await _fetchData();
      } catch (e) {
        debugPrint('Error deleting item: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting item: $e')));
      }
    }
  }

  Future<void> _showAddEditDialog({CashItem? item}) async {
    final isEditing = item != null;
    final textController = TextEditingController(text: item?.label ?? '');
    final valueController = TextEditingController(
      text: item != null ? item.value.toString() : '',
    );
    String selectedCategory = item?.category ?? 'spend';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            isEditing ? 'Edit Plan' : 'Add Plan',
            style: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: textController,
                  style: GoogleFonts.outfit(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: GoogleFonts.outfit(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[700]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.greenAccent),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: valueController,
                  style: GoogleFonts.outfit(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount (\$)',
                    labelStyle: GoogleFonts.outfit(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[700]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.greenAccent),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Category',
                  style: GoogleFonts.outfit(color: Colors.grey[400]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setDialogState(
                          () => selectedCategory = 'investment',
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedCategory == 'investment'
                                ? Colors.greenAccent.withValues(alpha: 0.2)
                                : Colors.transparent,
                            border: Border.all(
                              color: selectedCategory == 'investment'
                                  ? Colors.greenAccent
                                  : Colors.grey[700]!,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.trending_up,
                                color: selectedCategory == 'investment'
                                    ? Colors.greenAccent
                                    : Colors.grey,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Investment',
                                style: GoogleFonts.outfit(
                                  color: selectedCategory == 'investment'
                                      ? Colors.greenAccent
                                      : Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setDialogState(() => selectedCategory = 'spend'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedCategory == 'spend'
                                ? Colors.amber.withValues(alpha: 0.2)
                                : Colors.transparent,
                            border: Border.all(
                              color: selectedCategory == 'spend'
                                  ? Colors.amber
                                  : Colors.grey[700]!,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.shopping_bag,
                                color: selectedCategory == 'spend'
                                    ? Colors.amber
                                    : Colors.grey,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Spend',
                                style: GoogleFonts.outfit(
                                  color: selectedCategory == 'spend'
                                      ? Colors.amber
                                      : Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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
              onPressed: () async {
                final text = textController.text.trim();
                final value = int.tryParse(valueController.text) ?? 0;

                if (text.isEmpty || value <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter a description and valid amount',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(context);

                try {
                  if (isEditing) {
                    await _client
                        .from('items')
                        .update({
                          'text': text,
                          'value': value,
                          'category': selectedCategory,
                        })
                        .eq('id', item.id);
                  } else {
                    final userId = _client.auth.currentUser?.id;
                    if (userId == null) return;

                    await _client.from('items').insert({
                      'user_id': userId,
                      'section': 'cashPlanner',
                      'text': text,
                      'value': value,
                      'category': selectedCategory,
                      'is_completed': false,
                    });
                  }
                  await _fetchData();
                } catch (e) {
                  debugPrint('Error saving item: $e');
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving item: $e')),
                  );
                }
              },
              child: Text(
                isEditing ? 'Save' : 'Add',
                style: GoogleFonts.outfit(color: Colors.greenAccent),
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
        leadingWidth: 44,
        titleSpacing: 0,
        leading: const FocusAwareBackButton(),
        title: FocusAwareAppBarTitle(
          focusOffset: 28,
          child: Text(
            'Cash Surplus',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          const FocusAppBarActions(guide: FocusHelpGuide.finance),
          IconButton(
            constraints: const BoxConstraints.tightFor(width: 36, height: 40),
            padding: const EdgeInsets.all(6),
            iconSize: 20,
            icon: const Icon(Icons.help_outline),
            tooltip: 'Cash Surplus walkthrough',
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
      body: _isLoading
          ? const Center(child: AbleriteLoadingIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Summary Header - 4 metrics grid
                  KeyedSubtree(key: _summaryKey, child: _buildSummaryHeader()),
                  const SizedBox(height: 16),

                  // Two-column layout for Planned vs Active
                  KeyedSubtree(key: _plannedKey, child: _buildPlannedSection()),
                  const SizedBox(height: 16),
                  KeyedSubtree(key: _activeKey, child: _buildActiveSection()),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final greenColor = isDark ? Colors.greenAccent : Colors.green[700]!;
    final redColor = isDark ? Colors.redAccent : Colors.red[700]!;
    final amberColor = isDark ? Colors.amber : Colors.orange[800]!;
    final defaultColor = isDark ? Colors.white70 : Colors.black87;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withAlpha(100),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withAlpha(50)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Surplus',
                  _totalSurplus,
                  _totalSurplus >= 0 ? greenColor : redColor,
                  highlight: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  'Active Spend',
                  _activeSpend,
                  amberColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Planned',
                  _plannedAmount,
                  defaultColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  'Remaining',
                  _remainingCash,
                  _remainingCash >= 0 ? greenColor : redColor,
                  highlight: true,
                ),
              ),
            ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highlightColor = isDark ? Colors.greenAccent : Colors.green[700]!;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: highlight
            ? highlightColor.withValues(alpha: 0.1)
            : Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
        border: highlight
            ? Border.all(color: highlightColor.withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 9,
              color: highlight ? highlightColor : Colors.grey[500],
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

  Widget _buildPlannedSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amberColor = isDark ? Colors.amber : Colors.orange[800]!;
    return _buildAllocationSection(
      title: 'Planned Allocations',
      items: _plannedItems,
      total: _plannedAmount,
      color: amberColor,
      icon: Icons.account_balance_wallet_outlined,
      isActive: false,
      emptyText: 'No planned allocations.',
      showAdd: true,
    );
  }

  Widget _buildActiveSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final greenColor = isDark ? Colors.greenAccent : Colors.green[700]!;

    return _buildAllocationSection(
      title: 'Active Spend',
      items: _activeItems,
      total: _activeSpend,
      color: greenColor,
      icon: Icons.check_circle_outline,
      isActive: true,
      emptyText: 'No active spend yet.',
    );
  }

  Widget _buildAllocationSection({
    required String title,
    required List<CashItem> items,
    required double total,
    required Color color,
    required IconData icon,
    required bool isActive,
    required String emptyText,
    bool showAdd = false,
  }) {
    return Container(
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
                  Icon(icon, size: 16, color: color),
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
                  if (showAdd) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      key: _addKey,
                      onTap: () => _showAddEditDialog(),
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
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  emptyText,
                  style: GoogleFonts.outfit(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else if (_currentSortOption == SortOption.manual)
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              proxyDecorator: (child, index, animation) => Material(
                color: Colors.transparent,
                elevation: 4,
                child: child,
              ),
              onReorderItem: (oldIndex, newIndex) =>
                  _onReorder(items, oldIndex, newIndex),
              children: items
                  .asMap()
                  .entries
                  .map(
                    (entry) => Container(
                      key: ValueKey(entry.value.id),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: _buildItemCard(
                        entry.value,
                        isActive: isActive,
                        index: entry.key,
                        showDragHandle: true,
                      ),
                    ),
                  )
                  .toList(),
            )
          else
            ...items.map((item) => _buildItemCard(item, isActive: isActive)),
        ],
      ),
    );
  }

  Widget _buildItemCard(
    CashItem item, {
    required bool isActive,
    int? index,
    bool showDragHandle = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isInvestment = (item.category ?? 'spend') == 'investment';
    final greenColor = isDark ? Colors.greenAccent : Colors.green[700]!;
    final amberColor = isDark ? Colors.amber : Colors.orange[800]!;

    final cardContent = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive
            ? greenColor.withValues(alpha: 0.1)
            : Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? greenColor.withValues(alpha: 0.3)
              : Theme.of(context).dividerColor.withAlpha(50),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (showDragHandle && index != null) ...[
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle, color: Colors.grey),
                ),
                const SizedBox(width: 12),
              ],
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isInvestment
                      ? greenColor.withValues(alpha: 0.1)
                      : amberColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isInvestment ? Icons.trending_up : Icons.shopping_bag,
                  size: 16,
                  color: isInvestment ? greenColor : amberColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                _formatCurrency(item.value.toDouble()),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: isActive
                      ? greenColor
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isActive
                      ? Colors.greenAccent.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isActive
                      ? 'ACTIVE'
                      : (item.category ?? 'spend').toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: isActive
                        ? greenColor.withValues(alpha: 0.8)
                        : Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _toggleItemStatus(item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isActive ? 'Revert' : 'Mark Active',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: Colors.grey[300],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showAddEditDialog(item: item),
                      child: Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _deleteItem(item),
                      child: Icon(
                        Icons.delete,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (showDragHandle) {
      // If showing drag handle, the padding/margin is handled by the parent container in the list
      return cardContent;
    } else {
      // If normal list, we add margin here. But wait, in the list map we added Container with margin.
      // So cardContent should just be the card.
      // In `_buildPlannedSection` (else branch), we map to `_buildItemCard`.
      // We should ensure margin is consistent.

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: cardContent,
      );
    }
  }

  List<CashItem> get _sortedItems {
    final sorted = List<CashItem>.from(_items);
    switch (_currentSortOption) {
      case SortOption.dateDesc:
        sorted.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
        break;
      case SortOption.dateAsc:
        sorted.sort((a, b) => (a.createdAt ?? '').compareTo(b.createdAt ?? ''));
        break;
      case SortOption.amountDesc:
        sorted.sort((a, b) => b.value.compareTo(a.value));
        break;
      case SortOption.amountAsc:
        sorted.sort((a, b) => a.value.compareTo(b.value));
        break;
      case SortOption.nameAsc:
        sorted.sort((a, b) => a.label.compareTo(b.label));
        break;
      case SortOption.nameDesc:
        sorted.sort((a, b) => b.label.compareTo(a.label));
        break;
      case SortOption.manual:
        sorted.sort((a, b) {
          final indexA = a.orderIndex ?? 999999;
          final indexB = b.orderIndex ?? 999999;
          if (indexA != indexB) return indexA.compareTo(indexB);
          return (b.createdAt ?? '').compareTo(a.createdAt ?? '');
        });
        break;
    }
    return sorted;
  }

  Future<void> _onReorder(
    List<CashItem> currentList,
    int oldIndex,
    int newIndex,
  ) async {
    if (oldIndex == newIndex) return;

    setState(() {
      final item = currentList.removeAt(oldIndex);
      currentList.insert(newIndex, item);
      _currentSortOption = SortOption.manual;

      // Update orderIndex for all items in the list
      // Note: We need to be careful not to overwrite orderIndex of items NOT in this list (e.g. planned vs active)
      // But since they are separate lists visually, we can just assign indexes based on their current position in THIS list?
      // Actually, planned and active items are subsections of the main list.
      // If we reorder "Planned" items, we should update their order relative to each other.
      // A simple strategy:
      // 1. Get all items.
      // 2. Update the items that were reordered in the local `_items` list.
      // 3. Persist.

      // Let's find the items in `_items` and update their orderIndex.
      // Simpler approach: Just update the `orderIndex` of the items in `currentList`
      // to be 0, 1, 2... but we need to persist this to Supabase.

      // Map id -> new index
      final orderMap = <String, int>{};
      for (int i = 0; i < currentList.length; i++) {
        orderMap[currentList[i].id] = i;
      }

      // Update _items locally
      _items = _items.map((item) {
        if (orderMap.containsKey(item.id)) {
          return item.copyWith(orderIndex: orderMap[item.id]);
        }
        return item;
      }).toList();
    });

    // Optimistic update done, now persist
    // specific items that changed? Or just all in the list?
    // Let's persist all items in the reordered section to ensure consistency
    try {
      for (int i = 0; i < currentList.length; i++) {
        final item = currentList[i];
        await _client
            .from('items')
            .update({'order_index': i})
            .eq('id', item.id);
      }
    } catch (e) {
      debugPrint('Error updating order: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving order: $e')));
    }
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
            Icon(
              Icons.check,
              size: 16,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.greenAccent
                  : Colors.green[700],
            )
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
