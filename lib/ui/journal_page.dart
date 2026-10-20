import 'dart:ui';
import 'package:flutter/material.dart';
import 'widgets/ablerite_loading_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/focus_app_bar_actions.dart';
import '../models/journal.dart';
import '../services/navigation_service.dart';
import 'widgets/confirmation_dialog.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<JournalEntry> _allEntries = [];
  List<JournalEntry> _filteredEntries = [];
  List<dynamic> _folders = [];
  String? _selectedFolderId;
  String _pageTitle = 'Journals';

  final ScrollController _folderScrollController = ScrollController();
  final Map<int, GlobalKey> _folderKeys = {};

  @override
  void initState() {
    super.initState();
    pushPage();
    _fetchData();
  }

  @override
  void dispose() {
    popPage();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // 1. Fetch Folders - only journalFolders section (not notebooks)
      final foldersRes = await Supabase.instance.client
          .from('items')
          .select('id, text, section, order_index')
          .eq('user_id', userId)
          .eq('section', 'journalFolders')
          .order('order_index', ascending: true);

      // 2. Fetch All Journal Entries
      final entriesRes = await Supabase.instance.client
          .from('items')
          .select()
          .eq('user_id', userId)
          .eq('section', 'journal')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _folders = foldersRes as List;
          if (_folders.every((f) => f['order_index'] == null)) {
            _folders.sort(
              (a, b) => (a['text'] as String? ?? '').compareTo(
                b['text'] as String? ?? '',
              ),
            );
          }

          // Prepend virtual folders
          _folders.insert(0, {'id': 'MAIN', 'text': 'Main'});
          _folders.insert(0, {'id': 'ALL', 'text': 'All Entries'});

          _allEntries = (entriesRes as List)
              .map((e) => JournalEntry.fromJson(e))
              .toList();

          if (_folders.isNotEmpty) {
            // Default to All
            _selectFolder('ALL', 'All Entries');
            // Init keys
            for (int i = 0; i < _folders.length; i++) {
              _folderKeys[i] = GlobalKey();
            }
          } else {
            _filteredEntries = _allEntries;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _selectFolder(String folderId, String title) {
    setState(() {
      _selectedFolderId = folderId;
      _pageTitle = title;
      if (folderId == 'ALL') {
        _filteredEntries = _allEntries;
      } else if (folderId == 'MAIN') {
        _filteredEntries = _allEntries
            .where((e) => e.parentId == null)
            .toList();
      } else {
        _filteredEntries = _allEntries
            .where((e) => e.parentId == folderId)
            .toList();
      }
    });
  }

  Future<void> _updateEntry(String id, String newContent) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Update 'why' column as per discovery
      await Supabase.instance.client
          .from('items')
          .update({'why': newContent})
          .eq('id', id)
          .eq('user_id', userId);

      // Refresh data to reflect changes
      await _fetchData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry updated successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error updating entry: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createEntry(String content, String? parentId) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final now = DateTime.now();
      final title = DateFormat('EEEE, MMMM d, yyyy').format(now);

      await Supabase.instance.client.from('items').insert({
        'user_id': userId,
        'section': 'journal',
        'text': title, // The Date Title
        'why': content, // The actual content
        'parent_id': parentId,
        'created_at': now.toIso8601String(),
      });

      await _fetchData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry created successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error creating entry: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteEntry(JournalEntry entry) async {
    final confirm = await showDeleteBottomSheet(
      context,
      title: 'Delete Entry?',
      subtitle: 'Delete "${entry.title}"? This cannot be undone.',
    );

    if (confirm != true) return;

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client
          .from('items')
          .delete()
          .eq('id', entry.id)
          .eq('user_id', userId);

      await _fetchData();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Entry deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _moveEntry(JournalEntry entry) async {
    // Get folders excluding ALL and MAIN virtual folders, and excluding current folder
    final folders = _folders
        .where((f) => f['id'] != 'ALL' && f['id'] != 'MAIN')
        .map((f) => {'id': f['id'], 'text': f['text']})
        .toList();

    if (folders.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No folders available')));
      return;
    }

    String? selectedFolderId = entry.parentId;

    final result = await showDialog<String?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text(
              'Move Entry',
              style: GoogleFonts.outfit(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedFolderId,
                  hint: Text(
                    'Select Folder',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  items: [
                    DropdownMenuItem<String>(
                      value: '',
                      child: Text(
                        'No Folder (Main)',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    ...folders.map(
                      (f) => DropdownMenuItem<String>(
                        value: f['id'] as String,
                        child: Text(
                          f['text'] as String,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => selectedFolderId = value),
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[700]!),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.greenAccent),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, selectedFolderId),
                child: Text(
                  'Move',
                  style: TextStyle(color: Colors.greenAccent),
                ),
              ),
            ],
          );
        },
      ),
    );

    // result is null if cancelled, '' for Main, or folder id string
    if (result != null) {
      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId == null) return;

        await Supabase.instance.client
            .from('items')
            .update({'parent_id': result == '' ? null : result})
            .eq('id', entry.id)
            .eq('user_id', userId);

        await _fetchData();

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Entry moved')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to move: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteFolder(Map<String, dynamic> folder) async {
    final confirm = await showDeleteBottomSheet(
      context,
      title: 'Delete Journal?',
      subtitle: 'Delete "${folder["text"]}"? Entries will be moved to Main.',
    );

    if (confirm != true) return;

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Move all entries in this folder to Main (parent_id = null)
      await Supabase.instance.client
          .from('items')
          .update({'parent_id': null})
          .eq('parent_id', folder['id'])
          .eq('user_id', userId);

      // Then delete the folder itself
      await Supabase.instance.client
          .from('items')
          .delete()
          .eq('id', folder['id'])
          .eq('user_id', userId);

      await _fetchData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Journal deleted - entries moved to Main'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEntryDetails(JournalEntry entry) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(90),
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            _buildEntryDetailsDialog(context, entry),
          ],
        );
      },
    );
  }

  Widget _buildEntryDetailsDialog(BuildContext context, JournalEntry entry) {
    return StatefulBuilder(
      builder: (context, setStateDialog) {
        return Dialog(
          alignment: Alignment.topCenter,
          backgroundColor: Theme.of(context).colorScheme.surface,
          insetPadding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 100,
            bottom: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).dividerColor.withAlpha(20),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          entry.title,
                          style: GoogleFonts.outfit(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.drive_file_move,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(180),
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Move to folder',
                            onPressed: () {
                              Navigator.pop(context);
                              _moveEntry(entry);
                            },
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Delete entry',
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteEntry(entry);
                            },
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(180),
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              Navigator.pop(context);
                              _showEditDialog(entry);
                            },
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.grey,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    entry.content,
                    style: GoogleFonts.outfit(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(180),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditDialog(JournalEntry entry) {
    final controller = TextEditingController(text: entry.content);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        alignment: Alignment.topCenter,
        insetPadding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 100,
          bottom: 24,
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Edit Entry',
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          maxLines: null, // Allow multiline
          decoration: InputDecoration(
            hintText: 'Write your thoughts...',
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
            ),
            border: const OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor.withAlpha(50),
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
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              Navigator.pop(context);
              _updateEntry(entry.id, controller.text);
            },
            child: Text(
              'Save',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateEntryDialog() {
    final TextEditingController contentController = TextEditingController();
    String? selectedNotebookId;

    // Prepare dropdown items: "No Journal" + actual folders (excluding virtual ALL/MAIN)
    final dropdownItems = <Map<String, dynamic>>[];
    dropdownItems.add({'id': null, 'text': 'All Entries (No Journal)'});
    dropdownItems.addAll(
      _folders
          .where((f) => f['id'] != 'ALL' && f['id'] != 'MAIN')
          .map((e) => {'id': e['id'], 'text': e['text']})
          .toList(),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              alignment: Alignment.topCenter,
              backgroundColor: Theme.of(context).colorScheme.surface,
              insetPadding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 100,
                bottom: 24,
              ),
              child: Container(
                width: double.maxFinite,
                height: 500, // Fixed height or constrained
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.arrow_back,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'New Entry',
                              style: GoogleFonts.outfit(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          DateFormat(
                            'EEEE, MMMM d, yyyy',
                          ).format(DateTime.now()),
                          style: GoogleFonts.outfit(
                            color: Colors.greenAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withAlpha(100),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).dividerColor.withAlpha(50),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: selectedNotebookId,
                          dropdownColor: Theme.of(context).colorScheme.surface,
                          isExpanded: true,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(150),
                          ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          items: dropdownItems.map((item) {
                            return DropdownMenuItem<String?>(
                              value: item['id'] as String?,
                              child: Text(
                                item['text'] as String,
                                style: GoogleFonts.outfit(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setStateDialog(() => selectedNotebookId = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Text Area
                    Expanded(
                      child: TextField(
                        controller: contentController,
                        style: GoogleFonts.outfit(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                        ),
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          hintText: "What's on your mind today?",
                          hintStyle: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(100),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.outfit(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () {
                            if (contentController.text.trim().isEmpty) return;
                            Navigator.pop(context);
                            _createEntry(
                              contentController.text,
                              selectedNotebookId,
                            );
                          },
                          child: Text(
                            'Save Entry',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _createFolder(String name) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client.from('items').insert({
        'user_id': userId,
        'section': 'journalFolders',
        'text': name,
        'created_at': DateTime.now().toIso8601String(),
      });

      await _fetchData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Journal created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCreateFolderDialog() {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'New Journal',
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: nameController,
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'Journal Name',
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
            ),
            border: const OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor.withAlpha(50),
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
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                _createFolder(nameController.text.trim());
              }
            },
            child: Text(
              'Create',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSortFoldersDialog() {
    final List<dynamic> localFolders = List.from(
      _folders.where((f) => f['id'] != 'ALL' && f['id'] != 'MAIN'),
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text(
                'Sort Journals',
                style: GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  itemCount: localFolders.length,
                  onReorder: (oldIndex, newIndex) {
                    if (oldIndex < newIndex) newIndex -= 1;

                    setDialogState(() {
                      final f = localFolders.removeAt(oldIndex);
                      localFolders.insert(newIndex, f);
                    });
                  },
                  itemBuilder: (context, index) {
                    final folder = localFolders[index];
                    return ListTile(
                      key: ValueKey(folder['id']),
                      title: Text(
                        folder['text'] ?? 'Journal',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      trailing: Icon(
                        Icons.drag_handle,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(120),
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

                    // Reconstruct the _folders list to keep ALL and MAIN at the top
                    final List<dynamic> newFolders = [];
                    final allFolder = _folders.firstWhere(
                      (f) => f['id'] == 'ALL',
                      orElse: () => null,
                    );
                    final mainFolder = _folders.firstWhere(
                      (f) => f['id'] == 'MAIN',
                      orElse: () => null,
                    );

                    if (allFolder != null) newFolders.add(allFolder);
                    if (mainFolder != null) newFolders.add(mainFolder);
                    newFolders.addAll(localFolders);

                    setState(() {
                      _folders = newFolders;
                    });

                    try {
                      for (int i = 0; i < localFolders.length; i++) {
                        final fd = localFolders[i];
                        await Supabase.instance.client
                            .from('items')
                            .update({'order_index': i})
                            .eq('id', fd['id']);
                      }
                    } catch (e) {
                      debugPrint('Error saving folder order: $e');
                    }
                  },
                  child: Text(
                    'Save',
                    style: GoogleFonts.outfit(color: Colors.greenAccent),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFolderSelector() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        controller: _folderScrollController,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(
          left: 16,
          right: MediaQuery.of(context).size.width * 0.75,
        ),
        itemCount: _folders.length,
        itemBuilder: (context, index) {
          final folder = _folders[index];
          final isSelected = folder['id'] == _selectedFolderId;

          return Padding(
            key: _folderKeys[index],
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onLongPress: folder['id'] != 'ALL' && folder['id'] != 'MAIN'
                  ? () => _deleteFolder(folder)
                  : null,
              child: FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      folder['id'] == 'ALL' ? Icons.list : Icons.folder,
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(150),
                    ),
                    const SizedBox(width: 6),
                    Text(folder['text'] ?? 'Untitled'),
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
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withAlpha(100),
                onSelected: (selected) {
                  _selectFolder(folder['id'], folder['text'] ?? 'Journal');

                  Future.delayed(const Duration(milliseconds: 50), () {
                    final keyContext = _folderKeys[index]?.currentContext;
                    if (keyContext != null && keyContext.mounted) {
                      final box = keyContext.findRenderObject() as RenderBox?;
                      if (box != null && _folderScrollController.hasClients) {
                        final screenX = box.localToGlobal(Offset.zero).dx;

                        final listViewBox =
                            _folderScrollController
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
                            _folderScrollController.offset + shift;

                        final maxScroll =
                            _folderScrollController.position.maxScrollExtent;
                        final minScroll =
                            _folderScrollController.position.minScrollExtent;
                        final clampedOffset = targetOffset.clamp(
                          minScroll,
                          maxScroll,
                        );

                        _folderScrollController.animateTo(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: FocusAwareAppBarTitle(
          child: Text(
            _pageTitle,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: const FocusAwareBackButton(),
        actions: [
          const FocusAppBarActions(guide: FocusHelpGuide.exploration),
          IconButton(
            icon: Icon(
              Icons.sort,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            tooltip: 'Sort Journals',
            onPressed: _showSortFoldersDialog,
          ),
          IconButton(
            icon: Icon(
              Icons.create_new_folder,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () => _showCreateFolderDialog(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateEntryDialog();
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Folder Selector Chips
          if (_folders.isNotEmpty) _buildFolderSelector(),
          const SizedBox(height: 16),

          Expanded(
            child: _isLoading
                ? const Center(child: AbleriteLoadingIndicator())
                : _errorMessage != null
                ? Center(
                    child: Text(
                      'Error: $_errorMessage',
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : _filteredEntries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.book,
                          size: 64,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(100),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Entries in $_pageTitle',
                          style: GoogleFonts.outfit(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(150),
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the + button to add an entry',
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
                : ListView.builder(
                    itemCount: _filteredEntries.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final entry = _filteredEntries[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showEntryDetails(entry),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.title,
                                  style: GoogleFonts.outfit(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  entry.content.isNotEmpty
                                      ? entry.content
                                      : "No content",
                                  style: GoogleFonts.outfit(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withAlpha(150),
                                    fontSize: 14,
                                  ),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
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
