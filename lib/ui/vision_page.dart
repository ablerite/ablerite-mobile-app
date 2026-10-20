import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'widgets/ablerite_loading_indicator.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/navigation_service.dart';
import '../services/device_layout_service.dart';
import 'package:image_picker/image_picker.dart';
import '../services/photo_compression_service.dart';
import '../models/vision_board.dart';
import '../models/goal.dart'; // Import Goal
import 'package:google_fonts/google_fonts.dart';
import 'widgets/confirmation_dialog.dart';

class _VisionImageCache {
  static const _maximumCachedFiles = 200;
  static final Map<String, ImageProvider<Object>> _memoryProviders = {};
  static final Map<String, Future<ImageProvider<Object>?>> _pendingLoads = {};
  static final Future<Directory> _cacheDirectory = _createCacheDirectory();

  static ImageProvider<Object>? peek(String itemId) => _memoryProviders[itemId];

  static Future<ImageProvider<Object>?> resolve(
    VisionItem item,
    Future<String?> Function(String? url) imageUrlLoader,
  ) {
    final memoryProvider = _memoryProviders[item.id];
    if (memoryProvider != null) return Future.value(memoryProvider);
    return _pendingLoads.putIfAbsent(
      item.id,
      () => _resolve(item, imageUrlLoader),
    );
  }

  static Future<ImageProvider<Object>?> _resolve(
    VisionItem item,
    Future<String?> Function(String? url) imageUrlLoader,
  ) async {
    final cacheFile = await _fileFor(item.id);
    try {
      if (await cacheFile.exists() && await cacheFile.length() > 0) {
        final provider = FileImage(cacheFile);
        _memoryProviders[item.id] = provider;
        return provider;
      }
    } catch (_) {
      // A broken cache entry is replaced from the remote source below.
    }

    final displayUrl = await imageUrlLoader(item.imageUrl);
    if (displayUrl == null || displayUrl.isEmpty) return null;

    try {
      final response = await http
          .get(Uri.parse(displayUrl))
          .timeout(const Duration(seconds: 20));
      final contentType = response.headers['content-type'] ?? '';
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          response.bodyBytes.isNotEmpty &&
          (contentType.isEmpty || contentType.startsWith('image/'))) {
        final temporaryFile = File('${cacheFile.path}.download');
        await temporaryFile.writeAsBytes(response.bodyBytes, flush: true);
        if (await cacheFile.exists()) await cacheFile.delete();
        await temporaryFile.rename(cacheFile.path);
        final provider = FileImage(cacheFile);
        _memoryProviders[item.id] = provider;
        unawaited(_pruneDiskCache());
        return provider;
      }
    } catch (e) {
      debugPrint('Vision image disk cache download failed: $e');
    }

    // The standard Flutter image cache still prevents repeat decoding during
    // this app session if the on-device file could not be written.
    final provider = NetworkImage(displayUrl);
    _memoryProviders[item.id] = provider;
    return provider;
  }

  static Future<void> remove(String itemId) async {
    final provider = _memoryProviders.remove(itemId);
    _pendingLoads.remove(itemId);
    if (provider != null) {
      PaintingBinding.instance.imageCache.evict(provider);
    }
    try {
      final file = await _fileFor(itemId);
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('Vision image cache cleanup failed: $e');
    }
  }

  static Future<Directory> _createCacheDirectory() async {
    // Temporary storage can be cleared between sessions, which made every
    // image download again. App support storage keeps private cached copies.
    final root = await getApplicationSupportDirectory();
    final directory = Directory('${root.path}/ablerite_vision_images');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  static Future<File> _fileFor(String itemId) async {
    final directory = await _cacheDirectory;
    final safeId = itemId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return File('${directory.path}/$safeId.image');
  }

  static Future<void> _pruneDiskCache() async {
    try {
      final directory = await _cacheDirectory;
      final files = await directory
          .list()
          .where((entry) => entry is File && entry.path.endsWith('.image'))
          .cast<File>()
          .toList();
      if (files.length <= _maximumCachedFiles) return;
      final datedFiles = <(File, DateTime)>[];
      for (final file in files) {
        datedFiles.add((file, (await file.stat()).modified));
      }
      datedFiles.sort((a, b) => a.$2.compareTo(b.$2));
      for (final entry in datedFiles.take(
        datedFiles.length - _maximumCachedFiles,
      )) {
        await entry.$1.delete();
      }
    } catch (e) {
      debugPrint('Vision image cache pruning failed: $e');
    }
  }
}

class _CachedVisionImage extends StatelessWidget {
  final VisionItem item;
  final Future<String?> Function(String? url) imageUrlLoader;
  final BoxFit fit;
  final Widget loading;
  final Widget error;

  const _CachedVisionImage({
    required this.item,
    required this.imageUrlLoader,
    required this.fit,
    required this.loading,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    final memoryProvider = _VisionImageCache.peek(item.id);
    if (memoryProvider != null) return _image(memoryProvider);

    return FutureBuilder<ImageProvider<Object>?>(
      future: _VisionImageCache.resolve(item, imageUrlLoader),
      builder: (context, snapshot) {
        final provider = snapshot.data;
        if (provider == null) {
          return snapshot.connectionState == ConnectionState.waiting
              ? loading
              : error;
        }
        return _image(provider);
      },
    );
  }

  Widget _image(ImageProvider<Object> provider) {
    return Image(
      key: ValueKey('vision-image-${item.id}'),
      image: provider,
      fit: fit,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return loading;
      },
      errorBuilder: (context, exception, stackTrace) => error,
    );
  }
}

class VisionPage extends StatefulWidget {
  final String? initialBoardId;

  const VisionPage({super.key, this.initialBoardId});

  @override
  State<VisionPage> createState() => _VisionPageState();
}

class _VisionPageState extends State<VisionPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<VisionItem> _allItems = [];
  List<VisionItem> _filteredItems = [];
  List<dynamic> _boards = [];
  List<Goal> _allGoals = []; // Store goals
  String? _selectedBoardId;
  String _pageTitle = 'Vision Board';
  final Map<String, String> _signedUrlCache = {};
  final PhotoCompressionService _photoCompressionService =
      PhotoCompressionService();
  Future<void>? _signedUrlPreload;
  String? _loadingMessage;
  bool _isGridView = true;
  final Set<String> _selectedItemIds = <String>{};
  final ScrollController _scrollController = ScrollController();
  final ScrollController _boardScrollController = ScrollController();
  List<GlobalKey> _boardKeys = [];

  @override
  void initState() {
    super.initState();
    pushPage();
    // Enforce Portrait for Main Vision Page
    DeviceLayoutService.applyPreferredOrientations();
    _fetchData();
  }

  @override
  void dispose() {
    popPage();
    _scrollController.dispose();
    _boardScrollController.dispose();
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
            .eq('section', 'vision_boards')
            .order('order_index', ascending: true),
        Supabase.instance.client
            .from('items')
            .select()
            .eq('user_id', userId)
            .eq('section', 'visionBoard')
            .order('created_at', ascending: false),
        Supabase.instance.client
            .from('items')
            .select()
            .eq('user_id', userId)
            .or('section.eq.activeGoals,section.eq.longTermGoals'),
      ]);
      final boardsRes = responses[0];
      final itemsRes = responses[1];
      final goalsRes = responses[2];
      final loadedItems = itemsRes
          .map<VisionItem>((json) => VisionItem.fromJson(json))
          .toList();
      _signedUrlPreload = _preloadSignedImageUrls(loadedItems);

      if (mounted) {
        setState(() {
          _boards = List.from(boardsRes);
          if (_boards.every((b) => b['order_index'] == null)) {
            _boards.sort(
              (a, b) => (a['text'] as String).compareTo(b['text'] as String),
            );
          }

          if (!_boards.any((b) => b['id'] == 'MAIN')) {
            _boards.insert(0, {
              'id': 'MAIN',
              'text': 'Main Board',
              'section': 'vision_boards',
            });
          }

          _boardKeys = List.generate(_boards.length, (index) => GlobalKey());

          _allItems = loadedItems;
          _allItems.sort(_compareVisionItemsByName);
          _allGoals = goalsRes
              .map<Goal>((json) => Goal.fromJson(json))
              .toList();

          if (_boards.isNotEmpty) {
            if (_selectedBoardId == null) {
              if (widget.initialBoardId != null &&
                  _boards.any((b) => b['id'] == widget.initialBoardId)) {
                final board = _boards.firstWhere(
                  (b) => b['id'] == widget.initialBoardId,
                );
                _selectBoard(widget.initialBoardId!, board['text']);
              } else {
                _selectBoard('MAIN', 'Main Board');
              }
            } else {
              // Ensure selected ID still exists, else fallback
              final exists = _boards.any((b) => b['id'] == _selectedBoardId);
              if (exists) {
                final board = _boards.firstWhere(
                  (b) => b['id'] == _selectedBoardId,
                );
                _selectBoard(_selectedBoardId!, board['text']);
              } else {
                _selectBoard('MAIN', 'Main Board');
              }
            }
          } else {
            _filteredItems = _allItems;
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

  int _compareVisionItemsByName(VisionItem a, VisionItem b) {
    final nameCompare = _visionSortName(a).compareTo(_visionSortName(b));
    if (nameCompare != 0) return nameCompare;
    return b.createdAt.compareTo(a.createdAt);
  }

  String _visionSortName(VisionItem item) {
    final text = item.text.trim();
    if (text.isEmpty || text == 'New Image') return 'untitled';
    return text.toLowerCase();
  }

  void _selectBoard(String boardId, String title) {
    setState(() {
      _selectedItemIds.clear();
      _selectedBoardId = boardId;
      _pageTitle = title;
      if (boardId == 'MAIN') {
        // Show items with no parent OR explicitly 'MAIN' parent
        _filteredItems = _allItems
            .where((e) => e.parentId == null || e.parentId == 'MAIN')
            .toList();
      } else {
        _filteredItems = _allItems.where((e) => e.parentId == boardId).toList();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0.0);
      }
    });
  }

  Future<void> _createNewBoardDialog() async {
    final textController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'New Vision Board',
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
                if (textController.text.isNotEmpty) {
                  final userId = Supabase.instance.client.auth.currentUser?.id;
                  if (userId != null) {
                    final nextOrderIndex =
                        _boards.where((board) => board['id'] != 'MAIN').length +
                        1;
                    await Supabase.instance.client.from('items').insert({
                      'user_id': userId,
                      'section': 'vision_boards',
                      'text': textController.text,
                      'order_index': nextOrderIndex,
                      'created_at': DateTime.now().toIso8601String(),
                    });
                    if (context.mounted) Navigator.pop(context);
                    await _fetchData();
                  }
                }
              },
              child: Text(
                'Create',
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

  // ... (existing methods: _getValidImageUrl, _pickAndUploadImage, _deleteItem, _confirmDelete, _editCaption, _showImageDialog, _startSlideshow, _showBoardSelector, _showAddOptions, _buildGridItem, _buildListItem) ...

  Future<String?> _getValidImageUrl(String? url) async {
    if (url == null || url.isEmpty) return null;
    if (_signedUrlCache.containsKey(url)) return _signedUrlCache[url];

    await _signedUrlPreload;
    if (_signedUrlCache.containsKey(url)) return _signedUrlCache[url];

    if (url.contains('supabase.co/storage/v1/object/public/user-images/')) {
      try {
        final uri = Uri.parse(url);
        final pathSegments = uri.pathSegments;
        final bucketIndex = pathSegments.indexOf('user-images');
        if (bucketIndex != -1 && bucketIndex + 1 < pathSegments.length) {
          final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
          final signedUrl = await Supabase.instance.client.storage
              .from('user-images')
              .createSignedUrl(filePath, 3600);
          _signedUrlCache[url] = signedUrl;
          return signedUrl;
        }
      } catch (e) {
        debugPrint('Signed vision image URL error: $e');
      }
    }
    return url;
  }

  String? _storagePathFromPublicUrl(String? url) {
    if (url == null ||
        !url.contains('supabase.co/storage/v1/object/public/user-images/')) {
      return null;
    }
    try {
      final pathSegments = Uri.parse(url).pathSegments;
      final bucketIndex = pathSegments.indexOf('user-images');
      if (bucketIndex == -1 || bucketIndex + 1 >= pathSegments.length) {
        return null;
      }
      return pathSegments.sublist(bucketIndex + 1).join('/');
    } catch (_) {
      return null;
    }
  }

  Future<void> _preloadSignedImageUrls(List<VisionItem> items) async {
    final urlsByPath = <String, String>{};
    for (final item in items) {
      final url = item.imageUrl;
      final path = _storagePathFromPublicUrl(url);
      if (url != null && path != null) urlsByPath[path] = url;
    }
    if (urlsByPath.isEmpty) return;

    try {
      final signedUrls = await Supabase.instance.client.storage
          .from('user-images')
          .createSignedUrls(urlsByPath.keys.toList(), 3600);
      for (final signed in signedUrls) {
        final originalUrl = urlsByPath[signed.path];
        if (originalUrl != null && signed.signedUrl.isNotEmpty) {
          _signedUrlCache[originalUrl] = signed.signedUrl;
        }
      }
    } catch (e) {
      debugPrint('Batch signed vision image URL error: $e');
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    XFile? pickedFile;

    // 1. Pick Image (Safely)
    try {
      pickedFile = await _photoCompressionService.pickImage(source);
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (pickedFile == null) return; // User cancelled

    // 2. Show Loading
    if (mounted) {
      setState(() => _isLoading = true);
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final file = File(pickedFile.path);
      final fileExt = pickedFile.path.split('.').last;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}.$fileExt';
      final filePath = '$userId/vision-board/$fileName';

      await Supabase.instance.client.storage
          .from('user-images')
          .upload(filePath, file);
      final publicUrl = Supabase.instance.client.storage
          .from('user-images')
          .getPublicUrl(filePath);

      await Supabase.instance.client.from('items').insert({
        'user_id': userId,
        'section': 'visionBoard',
        'text': 'New Image',
        'image_url': publicUrl,
        'parent_id': _selectedBoardId == 'MAIN' ? null : _selectedBoardId,
        'created_at': DateTime.now().toIso8601String(),
      });

      await _fetchData();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Image uploaded!')));
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAndUploadMultipleImages() async {
    List<XFile> pickedFiles;

    try {
      pickedFiles = await _photoCompressionService.pickMultipleImages();
    } catch (e) {
      debugPrint('Error picking images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (pickedFiles.isEmpty) return; // User cancelled

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadingMessage = 'Uploading... 0 of ${pickedFiles.length}';
      });
    }

    var successCount = 0;
    var failureCount = 0;

    for (final pickedFile in pickedFiles) {
      if (mounted) {
        setState(() {
          _loadingMessage =
              'Uploading... ${successCount + failureCount + 1} of ${pickedFiles.length}';
        });
      }
      try {
        final file = File(pickedFile.path);
        final fileExt = pickedFile.path.split('.').last;
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}.$fileExt';
        final filePath = '$userId/vision-board/$fileName';

        await Supabase.instance.client.storage
            .from('user-images')
            .upload(filePath, file);
        final publicUrl = Supabase.instance.client.storage
            .from('user-images')
            .getPublicUrl(filePath);

        await Supabase.instance.client.from('items').insert({
          'user_id': userId,
          'section': 'visionBoard',
          'text': 'New Image',
          'image_url': publicUrl,
          'parent_id': _selectedBoardId == 'MAIN' ? null : _selectedBoardId,
          'created_at': DateTime.now().toIso8601String(),
        });

        successCount++;
      } catch (e) {
        debugPrint('Upload error: $e');
        failureCount++;
      }
    }

    await _fetchData();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _loadingMessage = null;
      });
      final message = failureCount == 0
          ? '$successCount image${successCount == 1 ? '' : 's'} uploaded!'
          : '$successCount uploaded, $failureCount failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: failureCount == 0
              ? Theme.of(context).colorScheme.primary
              : Colors.red,
        ),
      );
    }
  }

  bool get _isSelectingItems => _selectedItemIds.isNotEmpty;

  void _toggleItemSelection(VisionItem item) {
    setState(() {
      if (!_selectedItemIds.add(item.id)) {
        _selectedItemIds.remove(item.id);
      }
    });
  }

  void _clearItemSelection() {
    if (_selectedItemIds.isEmpty) return;
    setState(_selectedItemIds.clear);
  }

  void _selectAllVisibleItems() {
    setState(() {
      _selectedItemIds
        ..clear()
        ..addAll(_filteredItems.map((item) => item.id));
    });
  }

  Future<void> _deleteItems(List<VisionItem> items) async {
    if (items.isEmpty) return;

    try {
      setState(() => _isLoading = true);

      final storagePaths = <String>[];
      for (final item in items) {
        final url = item.imageUrl;
        if (url != null && url.contains('user-images')) {
          try {
            final pathSegments = Uri.parse(url).pathSegments;
            final bucketIndex = pathSegments.indexOf('user-images');
            if (bucketIndex != -1) {
              storagePaths.add(pathSegments.sublist(bucketIndex + 1).join('/'));
            }
          } catch (e) {
            debugPrint('Could not parse image storage path: $e');
          }
        }
      }

      if (storagePaths.isNotEmpty) {
        try {
          await Supabase.instance.client.storage
              .from('user-images')
              .remove(storagePaths);
        } catch (e) {
          debugPrint('Storage delete error (ignoring): $e');
        }
      }

      final itemIds = items.map((item) => item.id).toList();
      await Supabase.instance.client
          .from('items')
          .delete()
          .inFilter('id', itemIds);

      await Future.wait(items.map((item) => _VisionImageCache.remove(item.id)));

      _selectedItemIds.clear();
      await _fetchData();

      if (mounted) {
        final count = items.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count image${count == 1 ? '' : 's'} deleted'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteSelectedItems() async {
    final items = _filteredItems
        .where((item) => _selectedItemIds.contains(item.id))
        .toList();
    if (items.isEmpty) return;

    final count = items.length;
    final confirm = await showDeleteBottomSheet(
      context,
      title: 'Delete $count image${count == 1 ? '' : 's'}?',
      subtitle:
          'The selected image${count == 1 ? '' : 's'} cannot be restored.',
    );

    if (confirm == true) {
      await _deleteItems(items);
    }
  }

  Future<void> _editCaption(VisionItem item) async {
    final controller = TextEditingController(text: item.text);
    final newText = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Edit Caption',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Enter caption...',
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(
              'Save',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );

    if (newText != null && newText != item.text) {
      setState(() => _isLoading = true);
      try {
        await Supabase.instance.client
            .from('items')
            .update({'text': newText})
            .eq('id', item.id);
        await _fetchData();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Caption updated')));
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
        debugPrint('Error updating caption: $e');
      }
    }
  }

  void _showImageDialog(VisionItem item) {
    // Use full-screen page (like slideshow) instead of dialog for proper landscape support
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => _SingleImagePage(
          item: item,
          onEditCaption: () {
            // Close the image page first, then edit
            Navigator.pop(context); // Close _SingleImagePage
            _editCaption(item);
          },
        ),
      ),
    );
  }

  void _startSlideshow() {
    if (_filteredItems.isEmpty) return;
    Navigator.of(context, rootNavigator: true)
        .push(
          MaterialPageRoute(
            builder: (context) => SlideshowPage(items: _filteredItems),
          ),
        )
        .then((_) {
          // Re-enforce portrait when returning from slideshow
          DeviceLayoutService.applyPreferredOrientations();
        });
  }

  Future<void> _confirmDeleteBoard(Map<String, dynamic> board) async {
    final shouldDelete = await showDeleteBottomSheet(
      context,
      title: 'Delete Vision Board?',
      subtitle:
          'Delete "${board['text']}" and all its images? This cannot be undone.',
    );
    if (shouldDelete == true) {
      _deleteBoard(board);
    }
  }

  Future<void> _editBoardDialog(Map<String, dynamic> board) async {
    final textController = TextEditingController(text: board['text'] ?? '');
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'Edit Vision Board',
            style: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: TextField(
            controller: textController,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Board Name',
              hintStyle: const TextStyle(color: Colors.grey),
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
                final newText = textController.text.trim();
                if (newText.isNotEmpty && newText != board['text']) {
                  try {
                    await Supabase.instance.client
                        .from('items')
                        .update({'text': newText})
                        .eq('id', board['id']);
                    if (context.mounted) Navigator.pop(context);
                    await _fetchData();
                  } catch (e) {
                    debugPrint('Error updating board: $e');
                  }
                } else {
                  Navigator.pop(context);
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
  }

  void _showBoardOptions(Map<String, dynamic> board) {
    showModalBottomSheet(
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
              'Board Options',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, color: Colors.blue),
              ),
              title: Text(
                'Edit Board',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Change board name',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _editBoardDialog(board);
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete, color: Colors.red),
              ),
              title: const Text(
                'Delete Board',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Remove board and all images',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteBoard(board);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteBoard(Map<String, dynamic> board) async {
    setState(() => _isLoading = true);
    try {
      // Delete images from storage
      final itemsToDelete = _allItems
          .where((i) => i.parentId == board['id'])
          .toList();
      for (var item in itemsToDelete) {
        final url = item.imageUrl;
        if (url != null && url.contains('user-images')) {
          try {
            final uri = Uri.parse(url);
            final pathSegments = uri.pathSegments;
            final bucketIndex = pathSegments.indexOf('user-images');
            if (bucketIndex != -1) {
              final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
              await Supabase.instance.client.storage.from('user-images').remove(
                [filePath],
              );
            }
          } catch (e) {
            debugPrint('Storage delete error (ignoring): $e');
          }
        }
      }

      // Delete DB rows
      await Supabase.instance.client
          .from('items')
          .delete()
          .eq('parent_id', board['id']);
      await Supabase.instance.client
          .from('items')
          .delete()
          .eq('id', board['id']);

      if (_selectedBoardId == board['id']) _selectedBoardId = null;

      await _fetchData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Board deleted')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSortBoardsDialog() {
    final List<dynamic> localBoards = List.from(_boards);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text(
                'Sort Vision Boards',
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
                  // ignore: deprecated_member_use
                  onReorder: (oldIndex, newIndex) {
                    if (oldIndex < newIndex) newIndex -= 1;

                    final movedBoard = localBoards[oldIndex];
                    if (movedBoard['id'] == 'MAIN' ||
                        (newIndex == 0 &&
                            localBoards.any((b) => b['id'] == 'MAIN'))) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Main Board must remain first.'),
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
                      key: ValueKey(board['id']),
                      title: Text(
                        board['text'] ?? 'Vision Board',
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
                    setState(() {
                      _boards = localBoards;
                    });
                    try {
                      for (int i = 0; i < _boards.length; i++) {
                        final bd = _boards[i];
                        if (bd['id'] == 'MAIN') continue;
                        await Supabase.instance.client
                            .from('items')
                            .update({'order_index': i})
                            .eq('id', bd['id']);
                      }
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

  Widget _buildBoardSelector() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 8, bottom: 8),
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
          final isSelected = board['id'] == _selectedBoardId;
          return Padding(
            key: _boardKeys[index],
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onLongPress: () {
                if (board['id'] != 'MAIN') {
                  _showBoardOptions(board);
                }
              },
              child: FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.dashboard,
                      size: 16,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(150),
                    ),
                    const SizedBox(width: 6),
                    Text(board['text'] ?? 'Vision Board'),
                  ],
                ),
                labelStyle: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface.withAlpha(150),
                ),
                selectedColor: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withAlpha(100),
                onSelected: (selected) {
                  _selectBoard(board['id'], board['text'] ?? 'Vision Board');
                  Future.delayed(const Duration(milliseconds: 50), () {
                    final keyContext = _boardKeys[index].currentContext;
                    if (keyContext != null && keyContext.mounted) {
                      final box = keyContext.findRenderObject() as RenderBox?;
                      if (box != null && _boardScrollController.hasClients) {
                        // Calculate absolute screen X coordinate of the chip
                        final screenX = box.localToGlobal(Offset.zero).dx;

                        // Get ListView viewport position for proper scroll calculation
                        final listViewBox =
                            _boardScrollController
                                    .position
                                    .context
                                    .storageContext
                                    .findRenderObject()
                                as RenderBox?;
                        final viewportScreenX =
                            listViewBox?.localToGlobal(Offset.zero).dx ?? 0.0;

                        // Target position: 16px from left edge of viewport
                        final targetScreenX = viewportScreenX + 16.0;
                        final shift = screenX - targetScreenX;
                        final targetOffset =
                            _boardScrollController.offset + shift;

                        // Ensure offset is within scroll bounds
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

  void _showAddOptions() {
    showModalBottomSheet(
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
              'Add to Vision Board',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.2),
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
              subtitle: Text(
                'Use your camera',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library, color: Colors.blue),
              ),
              title: Text(
                'Upload from Gallery',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Choose existing photo',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_library_outlined,
                  color: Colors.purple,
                ),
              ),
              title: Text(
                'Upload Multiple',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Choose several photos at once',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadMultipleImages();
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(VisionItem item) {
    final isSelected = _selectedItemIds.contains(item.id);
    return Semantics(
      selected: isSelected,
      label: isSelected ? '${item.text}, selected' : item.text,
      child: GestureDetector(
        onTap: () => _isSelectingItems
            ? _toggleItemSelection(item)
            : _showImageDialog(item),
        onLongPress: () => _toggleItemSelection(item),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).dividerColor,
                  width: isSelected ? 3 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _CachedVisionImage(
                      item: item,
                      imageUrlLoader: _getValidImageUrl,
                      fit: BoxFit.cover,
                      loading: const Center(
                        child: AbleriteLoadingIndicator(strokeWidth: 2),
                      ),
                      error: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  if (item.text.isNotEmpty && item.text != 'New Image')
                    Container(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withAlpha(200),
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      child: Text(
                        item.text,
                        style: GoogleFonts.outfit(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 20,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(VisionItem item) {
    final isSelected = _selectedItemIds.contains(item.id);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).dividerColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 60,
            height: 60,
            child: _CachedVisionImage(
              item: item,
              imageUrlLoader: _getValidImageUrl,
              fit: BoxFit.cover,
              loading: const AbleriteLoadingIndicator(),
              error: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        ),
        title: Text(
          item.text.isNotEmpty && item.text != 'New Image'
              ? item.text
              : 'Untitled',
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Tap to view',
          style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
        ),
        trailing: IconButton(
          icon: Icon(
            isSelected ? Icons.check_circle : Icons.more_vert,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
          ),
          onPressed: () => _isSelectingItems
              ? _toggleItemSelection(item)
              : _showImageDialog(item),
        ),
        onTap: () => _isSelectingItems
            ? _toggleItemSelection(item)
            : _showImageDialog(item),
        onLongPress: () => _toggleItemSelection(item),
      ),
    );
  }

  Widget _buildLinkedGoals() {
    if (_selectedBoardId == null || _selectedBoardId == 'MAIN') {
      return const SizedBox.shrink();
    }

    final linkedGoals = _allGoals
        .where(
          (g) => g.relatedVisionBoardIds?.contains(_selectedBoardId) ?? false,
        )
        .toList();
    if (linkedGoals.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'LINKED:',
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: linkedGoals
                    .map(
                      (g) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withAlpha(50),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.flag,
                              color: Theme.of(context).colorScheme.primary,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              g.text,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openBoardCanvas() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _VisionBoardCanvasPage(
          title: _pageTitle,
          boardId: _selectedBoardId ?? 'MAIN',
          items: List<VisionItem>.from(_filteredItems),
          imageUrlLoader: _getValidImageUrl,
        ),
      ),
    );
    if (mounted) {
      await _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSelectingItems,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSelectingItems) {
          _clearItemSelection();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: Text(
            _isSelectingItems
                ? '${_selectedItemIds.length} selected'
                : _pageTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              _isSelectingItems ? Icons.close : Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: _isSelectingItems
                ? _clearItemSelection
                : () => Navigator.pop(context),
          ),
          actions: _isSelectingItems
              ? [
                  IconButton(
                    icon: const Icon(Icons.select_all),
                    tooltip: 'Select all',
                    onPressed: _selectedItemIds.length == _filteredItems.length
                        ? null
                        : _selectAllVisibleItems,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete selected',
                    onPressed: _confirmDeleteSelectedItems,
                  ),
                ]
              : [
                  IconButton(
                    icon: const Icon(Icons.open_in_full),
                    tooltip: 'View Board',
                    onPressed: _filteredItems.isEmpty ? null : _openBoardCanvas,
                  ),
                  IconButton(
                    icon: const Icon(Icons.sort),
                    tooltip: 'Sort Boards',
                    onPressed: _showSortBoardsDialog,
                  ),
                  IconButton(
                    icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
                    tooltip: _isGridView ? 'Switch to List' : 'Switch to Grid',
                    onPressed: () => setState(() => _isGridView = !_isGridView),
                  ),
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    tooltip: 'Start Slideshow',
                    onPressed: _startSlideshow,
                  ),
                ],
        ),
        floatingActionButton: _isSelectingItems
            ? null
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FloatingActionButton(
                    heroTag: 'add_board',
                    onPressed: _createNewBoardDialog,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.dashboard_customize,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FloatingActionButton(
                    heroTag: 'add_photo',
                    onPressed: _showAddOptions,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Icon(
                      Icons.add_a_photo,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AbleriteLoadingIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    if (_loadingMessage != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _loadingMessage!,
                        style: GoogleFonts.outfit(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              )
            : _errorMessage != null
            ? Center(
                child: Text(
                  'Error: $_errorMessage',
                  style: const TextStyle(color: Colors.red),
                ),
              )
            : Column(
                children: [
                  _buildBoardSelector(),
                  _buildLinkedGoals(),
                  Expanded(
                    child: _filteredItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.visibility,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No Items in $_pageTitle',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap the + button to add an image',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _isGridView
                        ? LayoutBuilder(
                            builder: (context, constraints) {
                              final tileWidth = (constraints.maxWidth - 48) / 2;
                              final textScale = MediaQuery.textScalerOf(
                                context,
                              ).scale(1);
                              final captionHeight =
                                  34 + ((textScale - 1).clamp(0.0, 1.0) * 18);
                              return GridView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      mainAxisExtent: tileWidth + captionHeight,
                                    ),
                                itemCount: _filteredItems.length,
                                itemBuilder: (context, index) {
                                  final item = _filteredItems[index];
                                  return _buildGridItem(item);
                                },
                              );
                            },
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = _filteredItems[index];
                              return _buildListItem(item);
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

class SlideshowPage extends StatefulWidget {
  final List<VisionItem> items;
  const SlideshowPage({super.key, required this.items});

  @override
  State<SlideshowPage> createState() => _SlideshowPageState();
}

class _SlideshowPageState extends State<SlideshowPage> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;
  final Map<String, String> _signedUrlCache = {};

  @override
  void initState() {
    super.initState();
    // Full-screen vision experiences are landscape-only.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _pageController = PageController();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;

      // Use the current page from controller to stay in sync with user swipes
      final currentIndex = _pageController.page?.round() ?? _currentPage;
      final nextIndex = currentIndex + 1;
      if (nextIndex < widget.items.length) {
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    DeviceLayoutService.applyPreferredOrientations();
    super.dispose();
  }

  Future<String?> _getValidImageUrl(String? url) async {
    if (url == null || url.isEmpty) return null;
    if (_signedUrlCache.containsKey(url)) return _signedUrlCache[url];

    if (url.contains('supabase.co/storage/v1/object/public/user-images/')) {
      try {
        final uri = Uri.parse(url);
        final pathSegments = uri.pathSegments;
        final bucketIndex = pathSegments.indexOf('user-images');
        if (bucketIndex != -1 && bucketIndex + 1 < pathSegments.length) {
          final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
          final signedUrl = await Supabase.instance.client.storage
              .from('user-images')
              .createSignedUrl(filePath, 3600);
          _signedUrlCache[url] = signedUrl;
          return signedUrl;
        }
      } catch (_) {}
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification &&
                  notification.dragDetails != null) {
                _timer?.cancel();
              } else if (notification is ScrollEndNotification) {
                _startTimer();
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.items.length,
              onPageChanged: (index) {
                if (!mounted) return;
                setState(() => _currentPage = index);
                // Restart timer on page change so user swipe resets the cycle
                _startTimer();
              },
              itemBuilder: (context, index) {
                final item = widget.items[index];
                return InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: SizedBox.expand(
                    child: _CachedVisionImage(
                      item: item,
                      imageUrlLoader: _getValidImageUrl,
                      fit: BoxFit.contain,
                      loading: const Center(child: AbleriteLoadingIndicator()),
                      error: const Center(
                        child: Icon(Icons.broken_image, color: Colors.white54),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

// Full-screen single image viewer with landscape/portrait support
class _SingleImagePage extends StatefulWidget {
  final VisionItem item;
  final VoidCallback onEditCaption;
  const _SingleImagePage({required this.item, required this.onEditCaption});

  @override
  State<_SingleImagePage> createState() => _SingleImagePageState();
}

class _SingleImagePageState extends State<_SingleImagePage> {
  bool _showControls = false;
  final Map<String, String> _signedUrlCache = {};

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Use post-frame callback since we can't call setState during build
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

  Future<String?> _getValidImageUrl(String? url) async {
    if (url == null || url.isEmpty) return null;
    if (_signedUrlCache.containsKey(url)) return _signedUrlCache[url];

    if (url.contains('supabase.co/storage/v1/object/public/user-images/')) {
      try {
        final uri = Uri.parse(url);
        final pathSegments = uri.pathSegments;
        final bucketIndex = pathSegments.indexOf('user-images');
        if (bucketIndex != -1 && bucketIndex + 1 < pathSegments.length) {
          final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
          final signedUrl = await Supabase.instance.client.storage
              .from('user-images')
              .createSignedUrl(filePath, 3600);
          _signedUrlCache[url] = signedUrl;
          return signedUrl;
        }
      } catch (_) {}
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => setState(() => _showControls = !_showControls),
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: SizedBox.expand(
                child: _CachedVisionImage(
                  item: widget.item,
                  imageUrlLoader: _getValidImageUrl,
                  fit: BoxFit.contain,
                  loading: const Center(child: AbleriteLoadingIndicator()),
                  error: const Center(
                    child: Icon(Icons.broken_image, color: Colors.white54),
                  ),
                ),
              ),
            ),
          ),
          // Close button
          if (_showControls)
            Positioned(
              top: 40,
              right: 20,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          // Caption bar with edit button
          if (_showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.all(16.0),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.item.text.isNotEmpty &&
                                  widget.item.text != 'New Image'
                              ? widget.item.text
                              : 'No caption',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: widget.onEditCaption,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VisionBoardCanvasPage extends StatefulWidget {
  final String title;
  final String boardId;
  final List<VisionItem> items;
  final Future<String?> Function(String? url) imageUrlLoader;

  const _VisionBoardCanvasPage({
    required this.title,
    required this.boardId,
    required this.items,
    required this.imageUrlLoader,
  });

  @override
  State<_VisionBoardCanvasPage> createState() => _VisionBoardCanvasPageState();
}

class _VisionBoardCanvasPageState extends State<_VisionBoardCanvasPage> {
  static const double _defaultCardWidth = 154;
  static const double _minCardWidth = 96;
  static const double _maxCardWidth = 320;
  static const double _captionHeight = 34;
  final Map<String, Offset> _positions = {};
  final Map<String, double> _widths = {};
  final Map<String, int> _zOrder = {};
  final Map<String, Timer> _saveTimers = {};
  final Map<String, Offset> _scaleStartPositions = {};
  final Map<String, double> _scaleStartWidths = {};
  int _topZ = 0;
  String? _selectedItemId;
  bool _showControls = true;

  String get _layoutPrefsKey => 'vision_canvas_layout_${widget.boardId}';

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      final z = item.canvasZ ?? i;
      _zOrder[item.id] = z;
      if (z > _topZ) _topZ = z;
      if (item.canvasWidth != null) {
        _widths[item.id] = item.canvasWidth!
            .clamp(_minCardWidth, _maxCardWidth)
            .toDouble();
      }
      if (item.canvasX != null && item.canvasY != null) {
        _positions[item.id] = Offset(item.canvasX!, item.canvasY!);
      }
    }
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setPageViewSwipeEnabled(false);
      setBottomNavVisible(false);
    });
    _loadLocalLayout();
  }

  @override
  void dispose() {
    for (final entry in _saveTimers.entries) {
      entry.value.cancel();
      _saveLayout(entry.key);
    }
    DeviceLayoutService.applyPreferredOrientations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setPageViewSwipeEnabled(true);
      setBottomNavVisible(true);
    });
    super.dispose();
  }

  void _bringToFront(String id) {
    setState(() {
      _selectedItemId = id;
      _topZ += 1;
      _zOrder[id] = _topZ;
    });
    _scheduleSave(id);
  }

  double _cardHeight(double width) => width + _captionHeight;

  double _clampWidth(double width, Size canvasSize) {
    final maxByCanvas = (canvasSize.width - 8)
        .clamp(_minCardWidth, _maxCardWidth)
        .toDouble();
    return width.clamp(_minCardWidth, maxByCanvas).toDouble();
  }

  Offset _clampPosition(Offset position, Size canvasSize, double width) {
    final maxX = (canvasSize.width - width).clamp(0.0, double.infinity);
    final maxY = (canvasSize.height - _cardHeight(width)).clamp(
      0.0,
      double.infinity,
    );
    return Offset(position.dx.clamp(0.0, maxX), position.dy.clamp(0.0, maxY));
  }

  void _ensureCanvasState(Size canvasSize) {
    if (canvasSize.width <= 0 || canvasSize.height <= 0) return;
    // The canvas forces landscape orientation in initState(), but the OS
    // rotation completes asynchronously — the first build(s) here can still
    // report the old portrait size. Clamping saved positions to that
    // transient, too-narrow size would permanently shrink them (they get
    // written back to Supabase on close). Wait for real landscape bounds.
    if (canvasSize.width < canvasSize.height) return;

    final columns = (canvasSize.width / 186).floor().clamp(1, 6);
    for (var i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      final width = _clampWidth(
        _widths[item.id] ?? _defaultCardWidth,
        canvasSize,
      );
      _widths[item.id] = width;

      final existing = _positions[item.id];
      if (existing == null) {
        final position = Offset(
          18 + (i % columns) * 174.0,
          76 + (i ~/ columns) * 136.0,
        );
        _positions[item.id] = _clampPosition(position, canvasSize, width);
      } else {
        _positions[item.id] = _clampPosition(existing, canvasSize, width);
      }
    }
  }

  void _startTransform(String id) {
    _bringToFront(id);
    _scaleStartPositions[id] = _positions[id] ?? Offset.zero;
    _scaleStartWidths[id] = _widths[id] ?? _defaultCardWidth;
  }

  void _updateTransform(
    String id,
    ScaleUpdateDetails details,
    Size canvasSize,
  ) {
    final startPosition =
        _scaleStartPositions[id] ?? _positions[id] ?? Offset.zero;
    final startWidth =
        _scaleStartWidths[id] ?? _widths[id] ?? _defaultCardWidth;
    final nextWidth = _clampWidth(startWidth * details.scale, canvasSize);
    setState(() {
      _widths[id] = nextWidth;
      _positions[id] = _clampPosition(
        (_positions[id] ?? startPosition) + details.focalPointDelta,
        canvasSize,
        nextWidth,
      );
    });
    _saveLocalLayout();
  }

  void _resizeBy(String id, Offset delta, Size canvasSize) {
    final currentWidth = _widths[id] ?? _defaultCardWidth;
    final nextWidth = _clampWidth(
      currentWidth + delta.dx + delta.dy,
      canvasSize,
    );
    setState(() {
      _selectedItemId = id;
      _widths[id] = nextWidth;
      _positions[id] = _clampPosition(
        _positions[id] ?? Offset.zero,
        canvasSize,
        nextWidth,
      );
    });
    _saveLocalLayout();
  }

  void _finishTransform(String id) {
    _scaleStartPositions.remove(id);
    _scaleStartWidths.remove(id);
    _scheduleSave(id);
  }

  void _scheduleSave(String id) {
    _saveTimers[id]?.cancel();
    _saveTimers[id] = Timer(const Duration(milliseconds: 450), () {
      _saveLayout(id);
    });
  }

  Future<void> _loadLocalLayout() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_layoutPrefsKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      var changed = false;

      for (final item in widget.items) {
        final layout = decoded[item.id];
        if (layout is! Map) continue;
        final x = _readDouble(layout['x']);
        final y = _readDouble(layout['y']);
        final width = _readDouble(layout['width']);
        final z = _readInt(layout['z']);

        if (x != null && y != null) {
          _positions[item.id] = Offset(x, y);
          changed = true;
        }
        if (width != null) {
          _widths[item.id] = width
              .clamp(_minCardWidth, _maxCardWidth)
              .toDouble();
          changed = true;
        }
        if (z != null) {
          _zOrder[item.id] = z;
          if (z > _topZ) _topZ = z;
          changed = true;
        }
      }

      if (changed && mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading local vision canvas layout: $e');
    }
  }

  double? _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return null;
  }

  int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return null;
  }

  Future<void> _saveLocalLayout() async {
    final prefs = await SharedPreferences.getInstance();
    final layout = <String, dynamic>{};

    for (final item in widget.items) {
      final position = _positions[item.id];
      final width = _widths[item.id];
      if (position == null || width == null) continue;
      layout[item.id] = {
        'x': double.parse(position.dx.toStringAsFixed(2)),
        'y': double.parse(position.dy.toStringAsFixed(2)),
        'width': double.parse(width.toStringAsFixed(2)),
        'z': _zOrder[item.id] ?? 0,
      };
    }

    await prefs.setString(_layoutPrefsKey, jsonEncode(layout));
  }

  Future<void> _flushPendingSaves() async {
    final ids = <String>{..._positions.keys, ..._saveTimers.keys};
    for (final timer in _saveTimers.values) {
      timer.cancel();
    }
    _saveTimers.clear();
    await _saveLocalLayout();
    await Future.wait(ids.map(_saveLayout));
  }

  Future<void> _closeCanvas() async {
    await _flushPendingSaves();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _saveLayout(String id) async {
    final position = _positions[id];
    final width = _widths[id];
    if (position == null || width == null) return;

    final payload = jsonEncode({
      'vision_canvas': {
        'x': double.parse(position.dx.toStringAsFixed(2)),
        'y': double.parse(position.dy.toStringAsFixed(2)),
        'width': double.parse(width.toStringAsFixed(2)),
        'z': _zOrder[id] ?? 0,
      },
    });

    await _saveLocalLayout();

    try {
      await Supabase.instance.client
          .from('items')
          .update({'why': payload})
          .eq('id', id);
    } catch (e) {
      debugPrint('Error saving vision canvas layout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderedItems = List<VisionItem>.from(widget.items)
      ..sort((a, b) => (_zOrder[a.id] ?? 0).compareTo(_zOrder[b.id] ?? 0));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _closeCanvas();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final canvasSize = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              _ensureCanvasState(canvasSize);

              return Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _showControls = !_showControls),
                      child: CustomPaint(
                        painter: _BoardGridPainter(),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                  ...orderedItems.map(
                    (item) => _CanvasVisionImage(
                      item: item,
                      position: _positions[item.id] ?? Offset.zero,
                      width: _widths[item.id] ?? _defaultCardWidth,
                      isSelected: _selectedItemId == item.id,
                      imageUrlLoader: widget.imageUrlLoader,
                      onTap: () => _bringToFront(item.id),
                      onScaleStart: () => _startTransform(item.id),
                      onScaleUpdate: (details) =>
                          _updateTransform(item.id, details, canvasSize),
                      onScaleEnd: () => _finishTransform(item.id),
                      onResizeStart: () => _startTransform(item.id),
                      onResizeUpdate: (delta) =>
                          _resizeBy(item.id, delta, canvasSize),
                      onResizeEnd: () => _finishTransform(item.id),
                    ),
                  ),
                  if (_showControls)
                    Positioned(
                      left: 12,
                      top: 12,
                      right: 12,
                      child: Row(
                        children: [
                          IconButton.filledTonal(
                            onPressed: _closeCanvas,
                            icon: const Icon(Icons.close),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(28),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Drag to arrange',
                              style: GoogleFonts.outfit(
                                color: Colors.white.withAlpha(210),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CanvasVisionImage extends StatelessWidget {
  final VisionItem item;
  final Offset position;
  final double width;
  final bool isSelected;
  final Future<String?> Function(String? url) imageUrlLoader;
  final VoidCallback onTap;
  final VoidCallback onScaleStart;
  final ValueChanged<ScaleUpdateDetails> onScaleUpdate;
  final VoidCallback onScaleEnd;
  final VoidCallback onResizeStart;
  final ValueChanged<Offset> onResizeUpdate;
  final VoidCallback onResizeEnd;

  const _CanvasVisionImage({
    required this.item,
    required this.position,
    required this.width,
    required this.isSelected,
    required this.imageUrlLoader,
    required this.onTap,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onScaleEnd,
    required this.onResizeStart,
    required this.onResizeUpdate,
    required this.onResizeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            onScaleStart: (_) => onScaleStart(),
            onScaleUpdate: onScaleUpdate,
            onScaleEnd: (_) => onScaleEnd(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              width: width,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: ColoredBox(
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: _CachedVisionImage(
                          item: item,
                          imageUrlLoader: imageUrlLoader,
                          fit: BoxFit.cover,
                          loading: const ColoredBox(
                            color: Color(0xFFE5E7EB),
                            child: Center(
                              child: AbleriteLoadingIndicator(strokeWidth: 2),
                            ),
                          ),
                          error: const ColoredBox(
                            color: Color(0xFFE5E7EB),
                            child: Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
                        child: Text(
                          item.text.isNotEmpty && item.text != 'New Image'
                              ? item.text
                              : 'Vision',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: Colors.black87,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (isSelected)
            Positioned(
              right: -10,
              bottom: -10,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (_) => onResizeStart(),
                onPanUpdate: (details) => onResizeUpdate(details.delta),
                onPanEnd: (_) => onResizeEnd(),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.open_in_full,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BoardGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(12)
      ..strokeWidth = 1;
    const spacing = 36.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
