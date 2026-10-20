import 'package:flutter/material.dart';
import 'widgets/ablerite_loading_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/item.dart';
import '../services/navigation_service.dart';
import 'widgets/confirmation_dialog.dart';

class ExpectationsPage extends StatefulWidget {
  const ExpectationsPage({super.key});

  @override
  State<ExpectationsPage> createState() => _ExpectationsPageState();
}

class _ExpectationsPageState extends State<ExpectationsPage> {
  List<Item> _areas = [];
  List<Item> _expectations = [];
  bool _isLoading = true;
  String? _selectedAreaId;
  String _pageTitle = 'Expectations';

  final ScrollController _areaScrollController = ScrollController();
  final Map<int, GlobalKey> _areaKeys = {};

  @override
  void initState() {
    super.initState();
    pushPage();
    _fetchData();
  }

  @override
  void dispose() {
    popPage();
    _areaScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final responses = await Future.wait([
        Supabase.instance.client
            .from('items')
            .select('id, text, section, order_index')
            .eq('user_id', userId)
            .eq('section', 'expectationAreas')
            .order('order_index', ascending: true),
        Supabase.instance.client
            .from('items')
            .select()
            .eq('user_id', userId)
            .eq('section', 'expectations'),
      ]);

      if (mounted) {
        final areasList = (responses[0] as List)
            .map((e) => Item.fromJson(e))
            .toList();
        // Sort alphabetically if no order_index
        if (areasList.every((a) => a.orderIndex == null)) {
          areasList.sort((a, b) => a.text.compareTo(b.text));
        }

        // Initialize keys for area chips (index 0 = "All", then actual areas)
        _areaKeys[0] = GlobalKey(); // "All" chip
        for (int i = 0; i < areasList.length; i++) {
          _areaKeys[i + 1] = GlobalKey();
        }

        setState(() {
          _areas = areasList;
          _expectations = (responses[1] as List)
              .map((e) => Item.fromJson(e))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectArea(String? areaId, String title) {
    setState(() {
      _selectedAreaId = areaId;
      _pageTitle = title;
    });
  }

  List<Item> get _filteredExpectations {
    if (_selectedAreaId == null) {
      return _expectations;
    }
    return _expectations.where((e) => e.parentId == _selectedAreaId).toList();
  }

  Future<void> _addArea() async {
    final TextEditingController controller = TextEditingController();
    final shouldAdd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'New Area',
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Area Name',
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
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
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Add',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );

    if (shouldAdd == true && controller.text.isNotEmpty) {
      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId == null) return;

        // Let Supabase generate the ID
        final response = await Supabase.instance.client.from('items').insert({
          'text': controller.text,
          'section': 'expectationAreas',
          'user_id': userId,
        }).select();

        if (response.isNotEmpty) {
          await _fetchData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error adding area: $e')));
        }
      }
    }
  }

  Future<void> _editArea(Item area) async {
    final TextEditingController controller = TextEditingController(
      text: area.text,
    );
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Edit Area',
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Area Name',
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
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
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Save',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );

    if (shouldSave == true &&
        controller.text.isNotEmpty &&
        controller.text != area.text) {
      try {
        await Supabase.instance.client
            .from('items')
            .update({'text': controller.text})
            .eq('id', area.id);

        await _fetchData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error updating area: $e')));
        }
      }
    }
  }

  void _showSortAreasDialog() {
    if (_areas.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No areas to sort')));
      return;
    }

    final List<Item> localAreas = List.from(_areas);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text(
                'Sort Areas',
                style: GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  itemCount: localAreas.length,
                  onReorder: (oldIndex, newIndex) {
                    if (oldIndex < newIndex) newIndex -= 1;

                    setDialogState(() {
                      final area = localAreas.removeAt(oldIndex);
                      localAreas.insert(newIndex, area);
                    });
                  },
                  itemBuilder: (context, index) {
                    final area = localAreas[index];
                    return ListTile(
                      key: ValueKey(area.id),
                      title: Text(
                        area.text,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      trailing: Icon(
                        Icons.drag_handle,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(100),
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
                    setState(() => _isLoading = true);
                    try {
                      for (int i = 0; i < localAreas.length; i++) {
                        await Supabase.instance.client
                            .from('items')
                            .update({'order_index': i})
                            .eq('id', localAreas[i].id);
                      }
                      await _fetchData();
                    } catch (e) {
                      if (mounted) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error sorting areas: $e')),
                        );
                        setState(() => _isLoading = false);
                      }
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

  Future<void> _addExpectation() async {
    final TextEditingController textController = TextEditingController();
    final TextEditingController whyController = TextEditingController();

    String? selectedAreaId = _selectedAreaId;

    // If no area is selected, require user to pick one
    if (_areas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create an area first')),
      );
      return;
    }

    final shouldAdd = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text(
              'New Expectation',
              style: GoogleFonts.outfit(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedAreaId,
                    hint: Text(
                      'Select Area',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                    dropdownColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    items: _areas.map((area) {
                      return DropdownMenuItem(
                        value: area.id,
                        child: Text(
                          area.text,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setDialogState(() => selectedAreaId = value),
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
                  const SizedBox(height: 16),
                  TextField(
                    controller: textController,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Title',
                      hintStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(100),
                      ),
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
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: whyController,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Details',
                      hintStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(100),
                      ),
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
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Add',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (shouldAdd == true && textController.text.isNotEmpty) {
      if (selectedAreaId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select an Area')),
          );
        }
        return;
      }

      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId == null) return;

        // Let Supabase generate the ID - match desktop format
        await Supabase.instance.client.from('items').insert({
          'text': textController.text,
          'section': 'expectations',
          'user_id': userId,
          'parent_id': selectedAreaId,
          'why': whyController.text.isNotEmpty ? whyController.text : null,
        });

        await _fetchData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding expectation: $e')),
          );
        }
      }
    }
  }

  Future<void> _editExpectation(Item expectation) async {
    final TextEditingController textController = TextEditingController(
      text: expectation.text,
    );
    final TextEditingController whyController = TextEditingController(
      text: expectation.why ?? '',
    );

    String? selectedAreaId = expectation.parentId;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text(
              'Edit Expectation',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedAreaId,
                    hint: Text(
                      'Select Area',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                    dropdownColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    items: _areas.map((area) {
                      return DropdownMenuItem(
                        value: area.id,
                        child: Text(
                          area.text,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setDialogState(() => selectedAreaId = value),
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
                  const SizedBox(height: 16),
                  TextField(
                    controller: textController,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Title',
                      hintStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(100),
                      ),
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
                  const SizedBox(height: 12),
                  TextField(
                    controller: whyController,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Details',
                      hintStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(100),
                      ),
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
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Save',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (shouldSave == true && textController.text.isNotEmpty) {
      try {
        await Supabase.instance.client
            .from('items')
            .update({
              'text': textController.text,
              'why': whyController.text.isNotEmpty ? whyController.text : null,
              'parent_id': selectedAreaId,
            })
            .eq('id', expectation.id);

        await _fetchData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating expectation: $e')),
          );
        }
      }
    }
  }

  Future<void> _showExpectationOptions(Item expectation) async {
    final result = await showOptionsBottomSheet(
      context,
      title: expectation.text,
      subtitle: expectation.why,
      editLabel: 'Edit Expectation',
      deleteLabel: 'Delete Expectation',
    );

    if (result == 'edit') {
      _editExpectation(expectation);
    } else if (result == 'delete') {
      _deleteExpectation(expectation);
    }
  }

  Future<void> _toggleExpectationComplete(Item expectation) async {
    try {
      final isComplete = !(expectation.completed ?? false);
      await Supabase.instance.client
          .from('items')
          .update({'completed': isComplete})
          .eq('id', expectation.id);

      setState(() {
        final idx = _expectations.indexWhere((e) => e.id == expectation.id);
        if (idx != -1) {
          _expectations[idx] = _expectations[idx].copyWith(
            completed: isComplete,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error toggling completion: $e')),
        );
      }
    }
  }

  Future<void> _deleteExpectation(Item expectation) async {
    final confirm = await showDeleteBottomSheet(
      context,
      title: 'Delete Expectation?',
      subtitle: 'This will permanently delete "${expectation.text}".',
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client
            .from('items')
            .delete()
            .eq('id', expectation.id);
        await _fetchData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting expectation: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteArea(Item area) async {
    final confirm = await showDeleteBottomSheet(
      context,
      title: 'Delete Area?',
      subtitle:
          'This will delete the "${area.text}" area and all its expectations.',
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.from('items').delete().eq('id', area.id);
        await _fetchData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting area: $e')));
        }
      }
    }
  }

  Widget _buildAreaSelector() {
    // Create list of areas + "All" option
    final List<Map<String, dynamic>> items = [
      {'id': null, 'text': 'All'},
      ..._areas.map((a) => {'id': a.id, 'text': a.text, 'item': a}),
    ];

    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      child: ListView.builder(
        controller: _areaScrollController,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(
          left: 16,
          right: MediaQuery.of(context).size.width * 0.6,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = item['id'] == _selectedAreaId;
          return Padding(
            key: _areaKeys[index],
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onLongPress: item['id'] != null
                  ? () => _showAreaOptions(item['item'] as Item)
                  : null,
              child: FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item['id'] == null ? Icons.list : Icons.folder,
                      size: 16,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(150),
                    ),
                    const SizedBox(width: 6),
                    Text(item['text'] ?? 'All'),
                  ],
                ),
                labelStyle: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Colors.grey[400],
                ),
                selectedColor: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).colorScheme.surface,
                onSelected: (selected) {
                  _selectArea(item['id'], item['text'] ?? 'Expectations');
                  Future.delayed(const Duration(milliseconds: 50), () {
                    final keyContext = _areaKeys[index]?.currentContext;
                    if (keyContext != null && keyContext.mounted) {
                      final box = keyContext.findRenderObject() as RenderBox?;
                      if (box != null && _areaScrollController.hasClients) {
                        final screenX = box.localToGlobal(Offset.zero).dx;
                        final listViewBox =
                            _areaScrollController
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
                            _areaScrollController.offset + shift;
                        final maxScroll =
                            _areaScrollController.position.maxScrollExtent;
                        final minScroll =
                            _areaScrollController.position.minScrollExtent;
                        final clampedOffset = targetOffset.clamp(
                          minScroll,
                          maxScroll,
                        );
                        _areaScrollController.animateTo(
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

  Future<void> _showAreaOptions(Item area) async {
    final result = await showOptionsBottomSheet(
      context,
      title: area.text,
      editLabel: 'Edit Area',
      deleteLabel: 'Delete Area',
    );

    if (result == 'edit') {
      _editArea(area);
    } else if (result == 'delete') {
      _deleteArea(area);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          _pageTitle,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.sort,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            tooltip: 'Sort Areas',
            onPressed: _showSortAreasDialog,
          ),
          IconButton(
            icon: Icon(
              Icons.create_new_folder,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            tooltip: 'Add Area',
            onPressed: _addArea,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExpectation,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: AbleriteLoadingIndicator())
          : Column(
              children: [
                const SizedBox(height: 8),
                if (_areas.isNotEmpty) _buildAreaSelector(),
                const SizedBox(height: 16),
                Expanded(
                  child: _filteredExpectations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.psychology,
                                size: 64,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(30),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No Expectations in $_pageTitle',
                                style: GoogleFonts.outfit(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withAlpha(100),
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap the + button to add an expectation',
                                style: GoogleFonts.outfit(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withAlpha(120),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ReorderableListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredExpectations.length,
                          onReorder: (oldIndex, newIndex) async {
                            if (oldIndex < newIndex) newIndex -= 1;

                            setState(() {
                              final updatedFiltered = List<Item>.from(
                                _filteredExpectations,
                              );
                              final item = updatedFiltered.removeAt(oldIndex);
                              updatedFiltered.insert(newIndex, item);

                              if (_selectedAreaId != null) {
                                _expectations.removeWhere(
                                  (e) => e.parentId == _selectedAreaId,
                                );
                                _expectations.insertAll(0, updatedFiltered);
                              } else {
                                _expectations = updatedFiltered;
                              }
                            });

                            try {
                              final filteredList = _filteredExpectations;
                              for (int i = 0; i < filteredList.length; i++) {
                                await Supabase.instance.client
                                    .from('items')
                                    .update({'order_index': i})
                                    .eq('id', filteredList[i].id);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error sorting: $e')),
                                );
                              }
                            }
                          },
                          itemBuilder: (context, index) {
                            final exp = _filteredExpectations[index];
                            final area = _areas
                                .where((a) => a.id == exp.parentId)
                                .firstOrNull;

                            return Container(
                              key: ValueKey(exp.id),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withAlpha(100),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).dividerColor.withAlpha(50),
                                  width: 1,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _showExpectationOptions(exp),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        onTap: () =>
                                            _toggleExpectationComplete(exp),
                                        child: Container(
                                          margin: const EdgeInsets.only(
                                            right: 12,
                                            top: 2,
                                          ),
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: (exp.completed ?? false)
                                                  ? Theme.of(
                                                      context,
                                                    ).colorScheme.primary
                                                  : Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withAlpha(150),
                                              width: 2,
                                            ),
                                            color: (exp.completed ?? false)
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.primary
                                                : Colors.transparent,
                                          ),
                                          child: (exp.completed ?? false)
                                              ? const Icon(
                                                  Icons.check,
                                                  size: 16,
                                                  color: Colors.white,
                                                )
                                              : null,
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              exp.text,
                                              style: GoogleFonts.outfit(
                                                color: (exp.completed ?? false)
                                                    ? Theme.of(context)
                                                          .colorScheme
                                                          .onSurface
                                                          .withAlpha(150)
                                                    : Theme.of(
                                                        context,
                                                      ).colorScheme.onSurface,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                decoration:
                                                    (exp.completed ?? false)
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                            ),
                                            if (exp.why != null &&
                                                exp.why!.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                exp.why!,
                                                style: GoogleFonts.outfit(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withAlpha(150),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.normal,
                                                ),
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                            if (area != null) ...[
                                              const SizedBox(height: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                      .withAlpha(30),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  area.text,
                                                  style: GoogleFonts.outfit(
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
