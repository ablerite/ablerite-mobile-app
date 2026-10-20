import 'dart:io';
import 'package:flutter/material.dart';
import 'widgets/ablerite_loading_indicator.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/focus_app_bar_actions.dart';
import '../services/navigation_service.dart';
import '../services/device_layout_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/item.dart';
import 'widgets/confirmation_dialog.dart';

class NotebooksPage extends StatefulWidget {
  const NotebooksPage({super.key});

  @override
  State<NotebooksPage> createState() => _NotebooksPageState();
}

class _NotebooksPageState extends State<NotebooksPage> {
  List<Item> _notebooks = [];
  List<Item> _allNotes = [];
  List<Item> _filteredNotes = [];
  bool _isLoading = true;
  bool _isGridView = false;
  String _selectedNotebookId = 'ALL';
  final ScrollController _notebookScrollController = ScrollController();
  List<GlobalKey> _notebookKeys = [];

  @override
  void initState() {
    super.initState();
    pushPage();
    _fetchData();
  }

  @override
  void dispose() {
    popPage();
    _notebookScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Fetch notebooks
      final notebooksRes = await Supabase.instance.client
          .from('items')
          .select('id, text, section, order_index')
          .eq('user_id', userId)
          .eq('section', 'notebooks')
          .order('order_index', ascending: true);

      // Fetch all notes
      final notesRes = await Supabase.instance.client
          .from('items')
          .select()
          .eq('user_id', userId)
          .eq('section', 'notes')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _notebooks = (notebooksRes as List)
              .map((e) => Item.fromJson(e))
              .toList();
          _allNotes = (notesRes as List).map((e) => Item.fromJson(e)).toList();
          // Clear cached futures so images reload with fresh signed URLs
          _imageUrlFutures.clear();

          // Sort notebooks alphabetically if no order_index
          if (_notebooks.every((n) => n.orderIndex == null)) {
            _notebooks.sort((a, b) => a.text.compareTo(b.text));
          }

          _allNotes.sort((a, b) {
            if (a.orderIndex != null && b.orderIndex != null) {
              return a.orderIndex!.compareTo(b.orderIndex!);
            }
            if (a.orderIndex != null) return -1;
            if (b.orderIndex != null) return 1;
            return (b.createdAt ?? '').compareTo(
              a.createdAt ?? '',
            ); // Fallback for new notes
          });

          _updateFilteredNotes();
          _notebookKeys = List.generate(
            _notebooks.length + 1,
            (_) => GlobalKey(),
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateFilteredNotes() {
    if (_selectedNotebookId == 'ALL') {
      _filteredNotes = List.from(_allNotes);
    } else {
      _filteredNotes = _allNotes
          .where((n) => n.parentId == _selectedNotebookId)
          .toList();
    }
  }

  void _selectNotebook(String notebookId, String title) {
    setState(() {
      _selectedNotebookId = notebookId;

      _updateFilteredNotes();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_notebookScrollController.hasClients) {
        _notebookScrollController.jumpTo(0.0);
      }
    });
  }

  Future<void> _addNotebook() async {
    final TextEditingController controller = TextEditingController();
    final shouldAdd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'New Notebook',
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Notebook Name',
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
              'Create',
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

        // Let Supabase generate the ID - match desktop format
        await Supabase.instance.client.from('items').insert({
          'text': controller.text,
          'section': 'notebooks',
          'user_id': userId,
        });

        await _fetchData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error adding notebook: $e')));
        }
      }
    }
  }

  Widget _buildNoteCard(Item note, {bool isGridCard = false}) {
    final hasImage = note.imageUrl != null && note.imageUrl!.isNotEmpty;

    return Container(
      margin: EdgeInsets.only(bottom: isGridCard ? 0 : 12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withAlpha(100),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withAlpha(50),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteDetailPage(
                note: note,
                defaultNotebookId: _selectedNotebookId == 'ALL'
                    ? null
                    : _selectedNotebookId,
                notebooks: _notebooks,
                onSave: _fetchData,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: FutureBuilder<String?>(
                  future: _imageUrlFutures.putIfAbsent(
                    note.id,
                    () => _getImageUrl(note),
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        height: isGridCard ? 100 : 120,
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: AbleriteLoadingIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    if (snapshot.hasData && snapshot.data != null) {
                      return Image.network(
                        snapshot.data!,
                        height: isGridCard ? 100 : 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        cacheWidth: 600,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            height: isGridCard ? 100 : 120,
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            child: const Center(
                              child: AbleriteLoadingIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: isGridCard ? 100 : 120,
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.image_not_supported,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(50),
                            ),
                          );
                        },
                      );
                    }
                    return Container(
                      height: isGridCard ? 100 : 120,
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.image,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(50),
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          note.text,
                          style: GoogleFonts.outfit(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: isGridCard ? 14 : 16,
                          ),
                          maxLines: isGridCard ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.more_horiz,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(150),
                          size: 20,
                        ),
                        onPressed: () => _showNoteOptions(note),
                      ),
                    ],
                  ),
                  if (note.why != null && note.why!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      note.why!.replaceAll('\n', ' '),
                      style: GoogleFonts.outfit(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(150),
                        fontSize: isGridCard ? 12 : 14,
                      ),
                      maxLines: isGridCard ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (note.createdAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(note.createdAt!),
                      style: GoogleFonts.outfit(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(100),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotebookChips() {
    // Build chip list: ALL NOTES first, then each notebook
    final allItems = [
      {'id': 'ALL', 'text': 'All Notes'},
      ..._notebooks.map((n) => {'id': n.id, 'text': n.text}),
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        controller: _notebookScrollController,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(
          left: 16,
          right: MediaQuery.of(context).size.width * 0.75,
        ),
        itemCount: allItems.length,
        itemBuilder: (context, index) {
          final item = allItems[index];
          final isSelected = item['id'] == _selectedNotebookId;
          return Padding(
            key: _notebookKeys[index],
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onLongPress: item['id'] != 'ALL'
                  ? () => _showNotebookOptions(
                      _notebooks.firstWhere((n) => n.id == item['id']),
                    )
                  : null,
              child: FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item['id'] == 'ALL' ? Icons.apps : Icons.folder,
                      size: 16,
                      color: isSelected
                          ? Theme.of(context).colorScheme.surface
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(150),
                    ),
                    const SizedBox(width: 6),
                    Text(item['text'] ?? 'Untitled'),
                  ],
                ),
                labelStyle: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Theme.of(context).colorScheme.surface
                      : Theme.of(context).colorScheme.onSurface.withAlpha(150),
                ),
                selectedColor: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withAlpha(100),
                onSelected: (selected) {
                  _selectNotebook(item['id']!, item['text'] ?? 'Notebook');
                  Future.delayed(const Duration(milliseconds: 50), () {
                    final keyContext = _notebookKeys[index].currentContext;
                    if (keyContext != null && keyContext.mounted) {
                      final box = keyContext.findRenderObject() as RenderBox?;
                      if (box != null && _notebookScrollController.hasClients) {
                        final screenX = box.localToGlobal(Offset.zero).dx;
                        final listViewBox =
                            _notebookScrollController
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
                            _notebookScrollController.offset + shift;
                        final maxScroll =
                            _notebookScrollController.position.maxScrollExtent;
                        final minScroll =
                            _notebookScrollController.position.minScrollExtent;
                        final clampedOffset = targetOffset.clamp(
                          minScroll,
                          maxScroll,
                        );
                        _notebookScrollController.animateTo(
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

  Future<void> _showNotebookOptions(Item notebook) async {
    final result = await showDeleteBottomSheet(
      context,
      title: 'Delete Notebook?',
      subtitle:
          'This will permanently delete the "${notebook.text}" notebook and all its notes.',
    );

    if (result == true) {
      try {
        await Supabase.instance.client
            .from('items')
            .delete()
            .eq('id', notebook.id);
        await _fetchData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting notebook: $e')),
          );
        }
      }
    }
  }

  void _showSortNotebooksDialog() {
    final List<Item> localNotebooks = List.from(_notebooks);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text(
                'Sort Notebooks',
                style: GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  itemCount: localNotebooks.length,
                  onReorderItem: (oldIndex, newIndex) {
                    setDialogState(() {
                      final item = localNotebooks.removeAt(oldIndex);
                      localNotebooks.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final notebook = localNotebooks[index];
                    return ListTile(
                      key: ValueKey(notebook.id),
                      leading: Icon(
                        Icons.folder,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        notebook.text,
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
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                  ),
                  onPressed: () async {
                    // Save new order to database
                    for (int i = 0; i < localNotebooks.length; i++) {
                      await Supabase.instance.client
                          .from('items')
                          .update({'order_index': i})
                          .eq('id', localNotebooks[i].id);
                    }
                    if (mounted) {
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      _fetchData();
                    }
                  },
                  child: Text(
                    'Save',
                    style: GoogleFonts.outfit(
                      color: Theme.of(context).colorScheme.surface,
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

  final Map<String, String> _signedUrlCache = {};
  final Map<String, Future<String?>> _imageUrlFutures = {};

  Future<String?> _getImageUrl(Item note) async {
    if (note.imageUrl == null || note.imageUrl!.isEmpty) return null;
    if (_signedUrlCache.containsKey(note.imageUrl)) {
      return _signedUrlCache[note.imageUrl];
    }
    try {
      if (note.imageUrl!.contains(
        'supabase.co/storage/v1/object/public/user-images/',
      )) {
        final uri = Uri.parse(note.imageUrl!);
        final pathSegments = uri.pathSegments;
        final bucketIndex = pathSegments.indexOf('user-images');
        if (bucketIndex != -1 && bucketIndex + 1 < pathSegments.length) {
          final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
          final signedUrl = await Supabase.instance.client.storage
              .from('user-images')
              .createSignedUrl(filePath, 3600);
          _signedUrlCache[note.imageUrl!] = signedUrl;
          return signedUrl;
        }
      }
      _signedUrlCache[note.imageUrl!] = note.imageUrl!;
      return note.imageUrl;
    } catch (e) {
      return note.imageUrl;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('d MMM yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _showNoteOptions(Item note) async {
    final result = await showOptionsBottomSheet(
      context,
      title: note.text,
      editLabel: 'Edit Note',
      deleteLabel: 'Delete Note',
      moveLabel: 'Move to Notebook',
    );
    if (result == 'edit') {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NoteDetailPage(
            note: note,
            defaultNotebookId: _selectedNotebookId == 'ALL'
                ? null
                : _selectedNotebookId,
            notebooks: _notebooks,
            onSave: _fetchData,
          ),
        ),
      );
    } else if (result == 'delete') {
      await _deleteNote(note);
    } else if (result == 'move') {
      await _moveNoteDialog(note);
    }
  }

  Future<void> _moveNoteDialog(Item note) async {
    final availableNotebooks = [
      {'id': null, 'text': 'Uncategorized'},
      ..._notebooks.map((n) => {'id': n.id, 'text': n.text}),
    ];
    String? selectedNotebookId = note.parentId;

    final shouldMove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text(
                'Move Note',
                style: GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              content: DropdownButtonFormField<String?>(
                initialValue: selectedNotebookId,
                dropdownColor: Theme.of(context).colorScheme.surface,
                items: availableNotebooks
                    .map(
                      (b) => DropdownMenuItem(
                        value: b['id'],
                        child: Text(
                          b['text'] as String,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) =>
                    setDialogState(() => selectedNotebookId = val),
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

    if (shouldMove == true && selectedNotebookId != note.parentId) {
      try {
        await Supabase.instance.client
            .from('items')
            .update({'parent_id': selectedNotebookId})
            .eq('id', note.id);

        await _fetchData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error moving note: $e')));
        }
      }
    }
  }

  Future<void> _deleteNote(Item note) async {
    final confirm = await showDeleteBottomSheet(
      context,
      title: 'Delete Note?',
      subtitle: 'This will permanently delete this note.',
    );
    if (confirm == true) {
      try {
        await Supabase.instance.client.from('items').delete().eq('id', note.id);
        await _fetchData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting note: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: FocusAwareAppBarTitle(
          child: Text(
            'Notebooks',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: const FocusAwareBackButton(),
        actions: [
          const FocusAppBarActions(guide: FocusHelpGuide.exploration),
          IconButton(
            icon: Icon(
              _isGridView ? Icons.list : Icons.grid_view,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            tooltip: _isGridView ? 'List View' : 'Grid View',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: Icon(
              Icons.sort,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            tooltip: 'Sort Notebooks',
            onPressed: _showSortNotebooksDialog,
          ),
          IconButton(
            icon: Icon(
              Icons.book,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            tooltip: 'New Notebook',
            onPressed: _addNotebook,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteDetailPage(
                note: null,
                defaultNotebookId: _selectedNotebookId == 'ALL'
                    ? null
                    : _selectedNotebookId,
                notebooks: _notebooks,
                onSave: _fetchData,
              ),
            ),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.surface,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: AbleriteLoadingIndicator())
          : Column(
              children: [
                const SizedBox(height: 16),
                // Notebook chips (horizontal scrollable)
                if (_notebooks.isNotEmpty) _buildNotebookChips(),
                const SizedBox(height: 16),
                // Notes list
                Expanded(
                  child: _filteredNotes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.note,
                                size: 64,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(30),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _selectedNotebookId == 'ALL'
                                    ? 'No notes yet'
                                    : 'No notes in this notebook',
                                style: GoogleFonts.outfit(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withAlpha(100),
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap the + button to create a note',
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
                      : _isGridView
                      ? LayoutBuilder(
                          builder: (context, constraints) {
                            final textScale = MediaQuery.textScalerOf(
                              context,
                            ).scale(1);
                            final cardHeight =
                                252 + ((textScale - 1).clamp(0.0, 1.0) * 42);
                            return GridView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    mainAxisExtent: cardHeight,
                                  ),
                              itemCount: _filteredNotes.length,
                              itemBuilder: (context, index) => _buildNoteCard(
                                _filteredNotes[index],
                                isGridCard: true,
                              ),
                            );
                          },
                        )
                      : ReorderableListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredNotes.length,
                          onReorderItem: (oldIndex, newIndex) async {
                            setState(() {
                              final item = _filteredNotes.removeAt(oldIndex);
                              _filteredNotes.insert(newIndex, item);

                              // Update _allNotes order
                              _allNotes.remove(item);
                              if (newIndex == _filteredNotes.length - 1) {
                                _allNotes.add(item);
                              } else {
                                final nextItem = _filteredNotes[newIndex + 1];
                                final insertionIndex = _allNotes.indexOf(
                                  nextItem,
                                );
                                if (insertionIndex != -1) {
                                  _allNotes.insert(insertionIndex, item);
                                } else {
                                  _allNotes.add(item);
                                }
                              }
                            });

                            try {
                              for (int i = 0; i < _filteredNotes.length; i++) {
                                await Supabase.instance.client
                                    .from('items')
                                    .update({'order_index': i})
                                    .eq('id', _filteredNotes[i].id);
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
                            final note = _filteredNotes[index];
                            return Container(
                              key: ValueKey(note.id),
                              child: _buildNoteCard(note),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class NotesListPage extends StatefulWidget {
  final String? notebookId;
  final String notebookName;

  const NotesListPage({
    super.key,
    required this.notebookId,
    required this.notebookName,
  });

  @override
  State<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
  List<Item> _notes = [];
  bool _isLoading = true;
  final Map<String, String> _signedUrlCache = {};

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      var query = Supabase.instance.client
          .from('items')
          .select()
          .eq('user_id', userId)
          .eq('section', 'notes');

      if (widget.notebookId != null) {
        query = query.eq('parent_id', widget.notebookId!);
      }

      final response = await query.order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _notes = (response as List).map((e) => Item.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading notes: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String?> _getImageUrl(Item note) async {
    if (note.imageUrl == null || note.imageUrl!.isEmpty) return null;

    // Return cached URL if available
    if (_signedUrlCache.containsKey(note.imageUrl)) {
      return _signedUrlCache[note.imageUrl];
    }

    try {
      // Check if it's a Supabase Storage URL
      if (note.imageUrl!.contains(
        'supabase.co/storage/v1/object/public/user-images/',
      )) {
        try {
          final uri = Uri.parse(note.imageUrl!);
          final pathSegments = uri.pathSegments;
          final bucketIndex = pathSegments.indexOf('user-images');
          if (bucketIndex != -1 && bucketIndex + 1 < pathSegments.length) {
            final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
            final signedUrl = await Supabase.instance.client.storage
                .from('user-images')
                .createSignedUrl(filePath, 3600);
            _signedUrlCache[note.imageUrl!] = signedUrl;
            return signedUrl;
          }
        } catch (e) {
          // Fall back to original URL
        }
      }

      // Return original URL for other cases
      _signedUrlCache[note.imageUrl!] = note.imageUrl!;
      return note.imageUrl;
    } catch (e) {
      return note.imageUrl;
    }
  }

  Future<void> _addNote() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteDetailPage(
          note: null,
          defaultNotebookId: widget.notebookId,
          notebooks: const [],
          onSave: _fetchNotes,
        ),
      ),
    );
  }

  Future<void> _showNoteOptions(Item note) async {
    final result = await showOptionsBottomSheet(
      context,
      title: note.text,
      editLabel: 'Edit Note',
      deleteLabel: 'Delete Note',
    );

    if (result == 'edit') {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NoteDetailPage(
            note: note,
            defaultNotebookId: widget.notebookId,
            notebooks: const [],
            onSave: _fetchNotes,
          ),
        ),
      );
    } else if (result == 'delete') {
      await _deleteNote(note);
    }
  }

  Future<void> _deleteNote(Item note) async {
    final confirm = await showDeleteBottomSheet(
      context,
      title: 'Delete Note?',
      subtitle: 'This will permanently delete this note.',
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.from('items').delete().eq('id', note.id);
        await _fetchNotes();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting note: $e')));
        }
      }
    }
  }

  void _showSortNotesDialog() {
    final List<Item> localNotes = List.from(_notes);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text(
                'Sort Notes',
                style: GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  itemCount: localNotes.length,
                  onReorderItem: (oldIndex, newIndex) {
                    setDialogState(() {
                      final item = localNotes.removeAt(oldIndex);
                      localNotes.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final note = localNotes[index];
                    return ListTile(
                      key: ValueKey(note.id),
                      leading: Icon(
                        Icons.note,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        note.text,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                  ),
                  onPressed: () async {
                    // Save new order to database
                    for (int i = 0; i < localNotes.length; i++) {
                      await Supabase.instance.client
                          .from('items')
                          .update({'order_index': i})
                          .eq('id', localNotes[i].id);
                    }
                    if (mounted) {
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      _fetchNotes();
                    }
                  },
                  child: Text(
                    'Save',
                    style: GoogleFonts.outfit(
                      color: Theme.of(context).colorScheme.surface,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.notebookName,
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
            tooltip: 'Sort Notes',
            onPressed: _showSortNotesDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.surface,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: AbleriteLoadingIndicator())
          : _notes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(30),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notes in ${widget.notebookName}',
                    style: GoogleFonts.outfit(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(100),
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to create a note',
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
              padding: const EdgeInsets.all(16),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                final hasImage =
                    note.imageUrl != null && note.imageUrl!.isNotEmpty;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest.withAlpha(100),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withAlpha(50),
                      width: 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NoteDetailPage(
                            note: note,
                            defaultNotebookId: widget.notebookId,
                            notebooks: const [],
                            onSave: _fetchNotes,
                          ),
                        ),
                      );
                    },
                    onLongPress: () => _showNoteOptions(note),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image thumbnail if exists
                        if (hasImage)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: FutureBuilder<String?>(
                              future: _getImageUrl(note),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data != null) {
                                  return Image.network(
                                    snapshot.data!,
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 120,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest,
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface.withAlpha(50),
                                        ),
                                      );
                                    },
                                  );
                                }
                                return Container(
                                  height: 120,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.image,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withAlpha(50),
                                  ),
                                );
                              },
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                note.text,
                                style: GoogleFonts.outfit(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (note.why != null && note.why!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  note.why!.replaceAll('\n', ' '),
                                  style: GoogleFonts.outfit(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withAlpha(150),
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (note.createdAt != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _formatDate(note.createdAt!),
                                  style: GoogleFonts.outfit(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withAlpha(120),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy • h:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}

class NoteDetailPage extends StatefulWidget {
  final Item? note;
  final String? defaultNotebookId;
  final List<Item> notebooks;
  final VoidCallback onSave;

  const NoteDetailPage({
    super.key,
    this.note,
    this.defaultNotebookId,
    this.notebooks = const [],
    required this.onSave,
  });

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isEditing = false;
  String? _existingImageUrl;
  String? _signedImageUrl;
  bool _isLoadingImage = true;
  late String? _selectedNotebookId;
  late List<Item> _availableNotebooks;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.text ?? '');
    _contentController = TextEditingController(text: widget.note?.why ?? '');
    _existingImageUrl = widget.note?.imageUrl;
    _selectedNotebookId = widget.note?.parentId ?? widget.defaultNotebookId;
    _availableNotebooks = List<Item>.from(widget.notebooks);
    _loadNotebookChoices();

    if (widget.note == null) {
      _isEditing = true;
      _isLoadingImage = false;
    } else {
      _loadSignedUrl();
    }
  }

  Future<void> _loadNotebookChoices() async {
    if (_availableNotebooks.isNotEmpty) return;
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final response = await Supabase.instance.client
          .from('items')
          .select()
          .eq('user_id', userId)
          .eq('section', 'notebooks')
          .order('order_index', ascending: true)
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _availableNotebooks = (response as List)
            .map((json) => Item.fromJson(json))
            .toList();
      });
    } catch (_) {
      // The editor still works without folder choices.
    }
  }

  Future<void> _loadSignedUrl() async {
    if (_existingImageUrl == null || _existingImageUrl!.isEmpty) {
      setState(() => _isLoadingImage = false);
      return;
    }

    try {
      // Check if it's a Supabase Storage URL
      if (_existingImageUrl!.contains(
        'supabase.co/storage/v1/object/public/user-images/',
      )) {
        final uri = Uri.parse(_existingImageUrl!);
        final pathSegments = uri.pathSegments;
        final bucketIndex = pathSegments.indexOf('user-images');
        if (bucketIndex != -1 && bucketIndex + 1 < pathSegments.length) {
          final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
          final signedUrl = await Supabase.instance.client.storage
              .from('user-images')
              .createSignedUrl(filePath, 3600);
          if (mounted) {
            setState(() {
              _signedImageUrl = signedUrl;
              _isLoadingImage = false;
            });
          }
          return;
        }
      }
      // Use original URL
      if (mounted) {
        setState(() {
          _signedImageUrl = _existingImageUrl;
          _isLoadingImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _signedImageUrl = _existingImageUrl;
          _isLoadingImage = false;
        });
      }
    }
  }

  void _openFullScreenImage() {
    if (_signedImageUrl == null || _signedImageUrl!.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImagePage(imageUrl: _signedImageUrl!),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open link')));
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    // Show bottom sheet to choose camera or gallery
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Image',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: Text(
                'Take Photo',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            Divider(color: Theme.of(context).dividerColor, height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.photo_library,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: Text(
                'Choose from Gallery',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile == null) return;

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Upload to Supabase Storage
      final file = File(pickedFile.path);
      final fileExt = pickedFile.path.split('.').last;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}.$fileExt';
      final filePath = '$userId/notebooks/$fileName';

      await Supabase.instance.client.storage
          .from('user-images')
          .upload(filePath, file);
      final publicUrl = Supabase.instance.client.storage
          .from('user-images')
          .getPublicUrl(filePath);

      setState(() {
        _existingImageUrl = publicUrl;
        _isLoadingImage = true;
      });

      // Load the signed URL properly
      await _loadSignedUrl();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Image added')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Widget _buildNotebookSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    final notebookIds = _availableNotebooks.map((n) => n.id).toSet();
    final currentValue = notebookIds.contains(_selectedNotebookId)
        ? _selectedNotebookId
        : null;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 14),
      child: DropdownButtonFormField<String?>(
        key: ValueKey('notebook-$currentValue-${_availableNotebooks.length}'),
        initialValue: currentValue,
        dropdownColor: colorScheme.surface,
        decoration: InputDecoration(
          labelText: 'Notebook',
          prefixIcon: const Icon(Icons.folder_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.outline.withAlpha(90)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.primary),
          ),
        ),
        items: [
          DropdownMenuItem<String?>(
            value: null,
            child: Text(
              'Uncategorized',
              style: GoogleFonts.outfit(color: colorScheme.onSurface),
            ),
          ),
          ..._availableNotebooks.map(
            (notebook) => DropdownMenuItem<String?>(
              value: notebook.id,
              child: Text(
                notebook.text,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(color: colorScheme.onSurface),
              ),
            ),
          ),
        ],
        onChanged: (value) => setState(() => _selectedNotebookId = value),
      ),
    );
  }

  Future<void> _saveNote() async {
    final title = _titleController.text;
    final content = _contentController.text;

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title cannot be empty')));
      return;
    }

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final notebookIds = _availableNotebooks.map((n) => n.id).toSet();
      final notebookIdToSave = notebookIds.contains(_selectedNotebookId)
          ? _selectedNotebookId
          : null;

      if (widget.note == null) {
        // Create new note - let Supabase generate ID
        await Supabase.instance.client.from('items').insert({
          'text': title,
          'section': 'notes',
          'user_id': userId,
          'parent_id': notebookIdToSave,
          'why': content,
          'image_url': _existingImageUrl,
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        // Update existing note
        await Supabase.instance.client
            .from('items')
            .update({
              'text': title,
              'why': content,
              'image_url': _existingImageUrl,
              'parent_id': notebookIdToSave,
            })
            .eq('id', widget.note!.id);
      }

      widget.onSave();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving note: $e')));
      }
    }
  }

  Future<void> _deleteNote() async {
    if (widget.note == null) return;

    final confirm = await showDeleteBottomSheet(
      context,
      title: 'Delete Note?',
      subtitle: 'This will permanently delete this note.',
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client
            .from('items')
            .delete()
            .eq('id', widget.note!.id);
        widget.onSave();
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting note: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _existingImageUrl != null && _existingImageUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: Icon(
                Icons.image,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              tooltip: 'Add Image',
              onPressed: _pickImage,
            ),
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: Icon(
                Icons.check,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: _saveNote,
            ),
          if (!_isEditing && widget.note != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _deleteNote,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show image if exists (in view mode or edit mode)
            if (hasImage)
              GestureDetector(
                onTap: _openFullScreenImage,
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    _isLoadingImage
                        ? Container(
                            height: 200,
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            child: const Center(
                              child: AbleriteLoadingIndicator(),
                            ),
                          )
                        : _signedImageUrl != null
                        ? Image.network(
                            _signedImageUrl!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                child: Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withAlpha(50),
                                    size: 48,
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            height: 200,
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                                size: 48,
                              ),
                            ),
                          ),
                    // Add an expand icon to show it's clickable
                    if (!_isLoadingImage && _signedImageUrl != null)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(120),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.fullscreen,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (_isEditing)
                    TextField(
                      controller: _titleController,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Title',
                        hintStyle: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(100),
                        ),
                        border: InputBorder.none,
                      ),
                    )
                  else
                    Text(
                      widget.note?.text ?? '',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  if (_isEditing) _buildNotebookSelector(),
                  Divider(color: Theme.of(context).dividerColor),
                  if (_isEditing)
                    TextField(
                      controller: _contentController,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                      ),
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Start typing...',
                        hintStyle: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(100),
                        ),
                        border: InputBorder.none,
                      ),
                    )
                  else
                    widget.note?.why != null && widget.note!.why!.isNotEmpty
                        ? MarkdownBody(
                            data: widget.note!.why!,
                            styleSheet: MarkdownStyleSheet(
                              p: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 16,
                              ),
                              h1: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                              h2: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                              h3: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTapLink: (text, href, title) {
                              if (href != null) {
                                _openUrl(href);
                              }
                            },
                          )
                        : const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FullScreenImagePage extends StatefulWidget {
  final String imageUrl;

  const FullScreenImagePage({super.key, required this.imageUrl});

  @override
  State<FullScreenImagePage> createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<FullScreenImagePage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setPageViewSwipeEnabled(false);
      setBottomNavVisible(false);
    });
  }

  @override
  void dispose() {
    DeviceLayoutService.applyPreferredOrientations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setPageViewSwipeEnabled(true);
      setBottomNavVisible(true);
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Image.network(
            widget.imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(
                  Icons.image_not_supported,
                  color: Colors.grey,
                  size: 64,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
