import 'dart:io';

import 'package:flutter/material.dart';
import 'widgets/ablerite_loading_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/item.dart';
import '../services/navigation_service.dart';
import 'widgets/repositionable_network_image.dart';
import 'widgets/tablet_layout.dart';

class FocusVisionPage extends StatefulWidget {
  const FocusVisionPage({super.key});

  @override
  State<FocusVisionPage> createState() => _FocusVisionPageState();
}

class _FocusVisionPageState extends State<FocusVisionPage>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _client = Supabase.instance.client;
  final DateFormat _dateFormat = DateFormat('d MMM yyyy');
  final Map<String, String> _signedUrlCache = {};
  late final TabController _tabController;
  List<Item> _items = [];
  bool _isLoading = true;
  bool _isSaving = false;

  List<Item> get _active =>
      _items.where((item) => item.completed != true).toList();

  List<Item> get _completed =>
      _items.where((item) => item.completed == true).toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    pushPage();
    _fetchItems();
  }

  @override
  void dispose() {
    popPage();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchItems() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await _client
          .from('items')
          .select('*')
          .eq('user_id', userId)
          .eq('section', 'visionFocus')
          .or('archived.is.null,archived.eq.false')
          .order('order_index', ascending: true)
          .order('created_at', ascending: true);

      if (!mounted) return;
      setState(() {
        _items = (response as List<dynamic>)
            .map((json) => _focusFromJson(json as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading focus visions: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load focus visions: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Item _focusFromJson(Map<String, dynamic> json) {
    final completedValue = json['completed'] ?? json['is_completed'];
    final completed = completedValue is bool
        ? completedValue
        : completedValue?.toString().toLowerCase() == 'true';

    return Item.fromJson(
      json,
    ).copyWith(completed: completed || json['status'] == 'done');
  }

  Future<String> _displayUrlFor(String url) async {
    if (_signedUrlCache.containsKey(url)) return _signedUrlCache[url]!;
    if (url.contains('supabase.co/storage/v1/object/public/user-images/')) {
      try {
        final uri = Uri.parse(url);
        final bucketIndex = uri.pathSegments.indexOf('user-images');
        if (bucketIndex != -1) {
          final filePath = uri.pathSegments.sublist(bucketIndex + 1).join('/');
          final signedUrl = await _client.storage
              .from('user-images')
              .createSignedUrl(filePath, 3600);
          _signedUrlCache[url] = signedUrl;
          return signedUrl;
        }
      } catch (e) {
        debugPrint('Signed focus vision image URL error: $e');
      }
    }
    _signedUrlCache[url] = url;
    return url;
  }

  Future<String?> _uploadImage(XFile image) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final file = File(image.path);
    final fileExt = image.path.split('.').last;
    final safeName = image.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${safeName.isEmpty ? 'focus' : safeName}.$fileExt';
    final filePath = '$userId/vision-focus/$fileName';

    await _client.storage.from('user-images').upload(filePath, file);
    return _client.storage.from('user-images').getPublicUrl(filePath);
  }

  Future<void> _saveFocus({Item? focus}) async {
    final result = await showModalBottomSheet<_FocusEditResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _FocusEditSheet(focus: focus),
    );

    if (result == null) return;

    final text = result.text.trim();
    if (text.isEmpty) return;

    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    if (!mounted) return;
    setState(() => _isSaving = true);
    try {
      String? imageUrl = focus?.imageUrl;
      if (result.removeExistingImage) imageUrl = null;
      if (result.selectedImage != null) {
        imageUrl = await _uploadImage(result.selectedImage!);
      }

      final payload = {
        'user_id': userId,
        'section': 'visionFocus',
        'text': text,
        'image_url': imageUrl,
        'completed': focus?.completed ?? false,
        'is_completed': focus?.completed ?? false,
        'archived': false,
      };

      if (focus == null) {
        await _client.from('items').insert({
          ...payload,
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        await _client.from('items').update(payload).eq('id', focus.id);
      }

      await _fetchItems();
    } catch (e) {
      debugPrint('Error saving focus vision: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save focus vision: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _toggleComplete(Item focus) async {
    final completed = focus.completed != true;
    try {
      await _client
          .from('items')
          .update({
            'completed': completed,
            'is_completed': completed,
            'status': completed ? 'done' : 'todo',
          })
          .eq('id', focus.id);
      await _fetchItems();
    } catch (e) {
      debugPrint('Error toggling focus vision: $e');
      await _fetchItems();
    }
  }

  Future<void> _deleteFocus(Item focus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete focus vision?'),
        content: Text('Remove "${focus.text}" from Focus Vision?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _client.from('items').delete().eq('id', focus.id);
    await _fetchItems();
  }

  String _createdLabel(Item focus) {
    final createdAt = focus.createdAt;
    if (createdAt == null || createdAt.isEmpty) return 'Created recently';
    final parsed = DateTime.tryParse(createdAt);
    if (parsed == null) return 'Created recently';
    return 'Created ${_dateFormat.format(parsed.toLocal())}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Focus Vision',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Mental movies guide',
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FocusVisionGuidePage(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: AbleriteLoadingIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                    child: _FocusHeroPanel(
                      activeCount: _active.length,
                      completedCount: _completed.length,
                      isSaving: _isSaving,
                      onCreate: () => _saveFocus(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withAlpha(
                          90,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colorScheme.outline.withAlpha(35),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          color: colorScheme.primary.withAlpha(38),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        labelColor: colorScheme.onSurface,
                        unselectedLabelColor: colorScheme.onSurface.withAlpha(
                          145,
                        ),
                        tabs: [
                          Tab(text: 'Active (${_active.length})'),
                          Tab(text: 'Completed (${_completed.length})'),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _FocusList(
                          items: _active,
                          completed: false,
                          emptyTitle: 'No focus visions yet',
                          emptyMessage:
                              'Create a primer image and focus line to begin.',
                          createdLabelBuilder: _createdLabel,
                          imageUrlLoader: _displayUrlFor,
                          onComplete: _toggleComplete,
                          onEdit: (focus) => _saveFocus(focus: focus),
                          onDelete: _deleteFocus,
                        ),
                        _FocusList(
                          items: _completed,
                          completed: true,
                          emptyTitle: 'Nothing completed yet',
                          emptyMessage:
                              'Completed focus visions will appear here.',
                          createdLabelBuilder: _createdLabel,
                          imageUrlLoader: _displayUrlFor,
                          onComplete: _toggleComplete,
                          onEdit: (focus) => _saveFocus(focus: focus),
                          onDelete: _deleteFocus,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _FocusEditResult {
  final String text;
  final XFile? selectedImage;
  final bool removeExistingImage;

  const _FocusEditResult({
    required this.text,
    required this.selectedImage,
    required this.removeExistingImage,
  });
}

/// Content of the add/edit focus vision bottom sheet. Owns the
/// [TextEditingController] itself so Flutter disposes it exactly when this
/// widget's element is unmounted (after the sheet's exit transition
/// finishes), instead of the caller disposing it immediately when
/// `Navigator.pop` resolves — which happens well before the ~200ms exit
/// animation completes, while the still-visible `TextField` was still
/// attached to it.
class _FocusEditSheet extends StatefulWidget {
  final Item? focus;

  const _FocusEditSheet({this.focus});

  @override
  State<_FocusEditSheet> createState() => _FocusEditSheetState();
}

class _FocusEditSheetState extends State<_FocusEditSheet> {
  late final TextEditingController _textController;
  XFile? _selectedImage;
  bool _removeExistingImage = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.focus?.text ?? '');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 86,
    );
    if (picked == null) return;
    if (!mounted) return;
    setState(() {
      _selectedImage = picked;
      _removeExistingImage = false;
    });
  }

  void _save() {
    Navigator.pop(
      context,
      _FocusEditResult(
        text: _textController.text,
        selectedImage: _selectedImage,
        removeExistingImage: _removeExistingImage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final focus = widget.focus;
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final hasExistingImage =
        focus?.imageUrl != null && focus!.imageUrl!.isNotEmpty;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              focus == null ? 'New Focus Vision' : 'Edit Focus Vision',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _textController,
              autofocus: focus == null,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'What mental movie does this primer image start?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image_outlined),
              label: Text(
                _selectedImage == null
                    ? hasExistingImage && !_removeExistingImage
                          ? 'Replace primer image'
                          : 'Add primer image'
                    : 'Primer image selected',
              ),
            ),
            if (hasExistingImage && _selectedImage == null)
              TextButton.icon(
                onPressed: () => setState(
                  () => _removeExistingImage = !_removeExistingImage,
                ),
                icon: Icon(
                  _removeExistingImage ? Icons.undo : Icons.hide_image_outlined,
                ),
                label: Text(
                  _removeExistingImage
                      ? 'Keep existing image'
                      : 'Remove existing image',
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _save,
              child: Text(
                focus == null ? 'Create Focus Vision' : 'Save Vision',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusHeroPanel extends StatelessWidget {
  final int activeCount;
  final int completedCount;
  final bool isSaving;
  final VoidCallback onCreate;

  const _FocusHeroPanel({
    required this.activeCount,
    required this.completedCount,
    required this.isSaving,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withAlpha(42)),
        image: const DecorationImage(
          image: AssetImage('assets/images/app_banners/focus_vision.png'),
          fit: BoxFit.cover,
          opacity: 0.24,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.center_focus_strong, color: colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prime the mental movie.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '$activeCount active  •  $completedCount complete',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface.withAlpha(165),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: isSaving ? null : onCreate,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              visualDensity: VisualDensity.compact,
            ),
            icon: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: AbleriteLoadingIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add, size: 18),
            label: const Text('New Focus'),
          ),
        ],
      ),
    );
  }
}

class _FocusList extends StatelessWidget {
  final List<Item> items;
  final bool completed;
  final String emptyTitle;
  final String emptyMessage;
  final String Function(Item item) createdLabelBuilder;
  final Future<String> Function(String url) imageUrlLoader;
  final void Function(Item item) onComplete;
  final void Function(Item item) onEdit;
  final void Function(Item item) onDelete;

  const _FocusList({
    required this.items,
    required this.completed,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.createdLabelBuilder,
    required this.imageUrlLoader,
    required this.onComplete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: items.isEmpty
          ? Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SizedBox(
                  width: double.infinity,
                  child: _FocusEmptyPanel(
                    title: emptyTitle,
                    message: emptyMessage,
                  ),
                ),
              ),
            )
          : PageView.builder(
              physics: const BouncingScrollPhysics(),
              padEnds: false,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == items.length - 1 ? 0 : 10,
                  ),
                  child: _FocusCard(
                    item: item,
                    completed: completed,
                    createdLabel: createdLabelBuilder(item),
                    imageUrlLoader: imageUrlLoader,
                    onComplete: () => onComplete(item),
                    onEdit: () => onEdit(item),
                    onDelete: () => onDelete(item),
                  ),
                );
              },
            ),
    );
  }
}

class FocusVisionGuidePage extends StatelessWidget {
  const FocusVisionGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Mental Movies Guide',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: const [
            _FocusGuideHero(),
            SizedBox(height: 16),
            _FocusGuideSection(
              icon: Icons.psychology_alt,
              title: 'What mental movies are',
              body:
                  'Mental movies are short internal scenes you rehearse deliberately. The idea is rooted in Maxwell Maltz and Psycho-Cybernetics: your self-image and imagination shape how your nervous system prepares you to act. A mental movie is not daydreaming for hours. It is a brief, emotionally clear scene that lets your mind and body recognise the next version of reality.',
            ),
            _FocusGuideSection(
              icon: Icons.image_outlined,
              title: 'The primer image',
              body:
                  'The primer image is the doorway into the movie. Choose one image that instantly starts the scene, feeling, identity, and outcome you want to rehearse. Return to that image at the start of a meditation session. Look at it, breathe, then let the movie begin internally.',
            ),
            _FocusGuideSection(
              icon: Icons.center_focus_strong,
              title: 'Use it for near-field manifestation',
              body:
                  'Focus Vision works best for desires that are close enough to your current circumstances that your mind can believe, rehearse, and act toward them now. If the outcome is too distant or vague, you may get bored and give up. Use Focus Vision for immediate shifts, near-future wins, conversations, habits, confidence, opportunities, and states you can grow into soon.',
            ),
            _FocusGuideSection(
              icon: Icons.dashboard_customize_outlined,
              title: 'Use it with Vision Boards',
              body:
                  'Your Vision Boards hold the wider future: the life, places, relationships, work, health, and identity you desire. Focus Vision is the short mental movie that helps you manifest a specific piece of that wider board. The vision board is the map. The primer image is the beacon you return to before action.',
            ),
            _FocusGuideSection(
              icon: Icons.self_improvement,
              title: 'A simple practice',
              body:
                  'Open a Focus Vision. Look at the primer image for 20 to 30 seconds. Read the focus line. Close your eyes and play a short scene as if it is already happening. Feel the body state. End by asking: what is the one aligned action I can take today?',
            ),
            _FocusGuideSection(
              icon: Icons.check_circle_outline,
              title: 'When to complete it',
              body:
                  'Mark a Focus Vision complete when the scene has landed in reality or when it has done its job by changing your behaviour, confidence, or readiness. Completed focus visions become evidence that mental rehearsal can lead to visible movement.',
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  final Item item;
  final bool completed;
  final String createdLabel;
  final Future<String> Function(String url) imageUrlLoader;
  final VoidCallback onComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FocusCard({
    required this.item,
    required this.completed,
    required this.createdLabel,
    required this.imageUrlLoader,
    required this.onComplete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = item.imageUrl;
    final imageAspectRatio = isTabletLandscape(context) ? 16 / 5 : 16 / 9;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: completed
            ? Colors.amber.withAlpha(18)
            : colorScheme.surfaceContainerHighest.withAlpha(95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: completed
              ? Colors.amber.withAlpha(75)
              : colorScheme.outline.withAlpha(45),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: imageAspectRatio,
            child: imageUrl == null || imageUrl.isEmpty
                ? _FocusImagePlaceholder(completed: completed)
                : RepositionableNetworkImage(
                    key: ValueKey('focus-image-${item.id}'),
                    imageUrl: imageUrl,
                    imageUrlLoader: imageUrlLoader,
                    positionKey: 'focus-vision.${item.id}',
                    frameAspectRatio: imageAspectRatio,
                    placeholderBuilder: () =>
                        _FocusImagePlaceholder(completed: completed),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: completed
                              ? Colors.amber.withAlpha(25)
                              : colorScheme.primary.withAlpha(22),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          completed ? 'COMPLETE' : 'FOCUS VISION',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: completed
                                ? Colors.amber
                                : colorScheme.primary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        createdLabel,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: colorScheme.onSurface.withAlpha(130),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        item.text,
                        maxLines: 9,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          height: 1.28,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onComplete,
                          icon: Icon(
                            completed ? Icons.undo : Icons.check_circle_outline,
                          ),
                          label: Text(completed ? 'Move Back' : 'Complete'),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusImagePlaceholder extends StatelessWidget {
  final bool completed;

  const _FocusImagePlaceholder({required this.completed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: completed
          ? Colors.amber.withAlpha(24)
          : colorScheme.primary.withAlpha(18),
      child: Icon(
        completed ? Icons.check_circle_outline : Icons.center_focus_strong,
        color: completed ? Colors.amber : colorScheme.primary,
        size: 42,
      ),
    );
  }
}

class _FocusEmptyPanel extends StatelessWidget {
  final String title;
  final String message;

  const _FocusEmptyPanel({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(60),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline.withAlpha(35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.center_focus_strong,
            color: colorScheme.primary.withAlpha(150),
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: colorScheme.onSurface.withAlpha(145),
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusGuideHero extends StatelessWidget {
  const _FocusGuideHero();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withAlpha(42)),
        image: const DecorationImage(
          image: AssetImage('assets/images/app_banners/focus_vision.png'),
          fit: BoxFit.cover,
          opacity: 0.18,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.menu_book_outlined, color: colorScheme.primary, size: 30),
          const SizedBox(height: 14),
          Text(
            'A practical guide to primer images, mental movies, and near-future manifestation.',
            style: GoogleFonts.outfit(
              fontSize: 24,
              height: 1.08,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusGuideSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _FocusGuideSection({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline.withAlpha(35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colorScheme.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: GoogleFonts.outfit(
              fontSize: 14,
              height: 1.45,
              color: colorScheme.onSurface.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }
}
