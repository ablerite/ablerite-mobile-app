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

class CosmicOrderingPage extends StatefulWidget {
  const CosmicOrderingPage({super.key});

  @override
  State<CosmicOrderingPage> createState() => _CosmicOrderingPageState();
}

class _CosmicOrderingPageState extends State<CosmicOrderingPage>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _client = Supabase.instance.client;
  final Map<String, String> _signedUrlCache = {};
  final DateFormat _dateFormat = DateFormat('d MMM yyyy');
  late final TabController _tabController;
  List<Item> _orders = [];
  bool _isLoading = true;
  bool _isSaving = false;

  List<Item> get _activeOrders =>
      _orders.where((order) => order.completed != true).toList();

  List<Item> get _fulfilledOrders =>
      _orders.where((order) => order.completed == true).toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    pushPage();
    _fetchOrders();
  }

  @override
  void dispose() {
    popPage();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
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
          .eq('section', 'cosmicOrders')
          .or('archived.is.null,archived.eq.false')
          .order('order_index', ascending: true)
          .order('created_at', ascending: true);

      if (!mounted) return;
      setState(() {
        _orders = (response as List<dynamic>)
            .map((json) => _cosmicOrderFromJson(json as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading cosmic orders: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load cosmic orders: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Item _cosmicOrderFromJson(Map<String, dynamic> json) {
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
        debugPrint('Signed cosmic order image URL error: $e');
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
        '${DateTime.now().millisecondsSinceEpoch}_${safeName.isEmpty ? 'order' : safeName}.$fileExt';
    final filePath = '$userId/cosmic-orders/$fileName';

    await _client.storage.from('user-images').upload(filePath, file);
    return _client.storage.from('user-images').getPublicUrl(filePath);
  }

  Future<void> _saveOrder({Item? order}) async {
    final result = await showModalBottomSheet<_OrderEditResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _OrderEditSheet(order: order),
    );

    if (result == null) return;

    final text = result.text.trim();
    if (text.isEmpty) return;

    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    if (!mounted) return;
    setState(() => _isSaving = true);
    try {
      String? imageUrl = order?.imageUrl;
      if (result.removeExistingImage) imageUrl = null;
      if (result.selectedImage != null) {
        imageUrl = await _uploadImage(result.selectedImage!);
      }

      final payload = {
        'user_id': userId,
        'section': 'cosmicOrders',
        'text': text,
        'image_url': imageUrl,
        'completed': order?.completed ?? false,
        'is_completed': order?.completed ?? false,
        'archived': false,
      };

      if (order == null) {
        await _client.from('items').insert({
          ...payload,
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        await _client.from('items').update(payload).eq('id', order.id);
      }

      await _fetchOrders();
    } catch (e) {
      debugPrint('Error saving cosmic order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _toggleFulfilled(Item order) async {
    final completed = order.completed != true;

    try {
      await _client
          .from('items')
          .update({
            'completed': completed,
            'is_completed': completed,
            'status': completed ? 'done' : 'todo',
          })
          .eq('id', order.id);
      await _fetchOrders();
    } catch (e) {
      debugPrint('Error toggling cosmic order: $e');
      await _fetchOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteOrder(Item order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete order?'),
        content: Text('Remove "${order.text}" from your cosmic orders?'),
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

    try {
      await _client.from('items').delete().eq('id', order.id);
      await _fetchOrders();
    } catch (e) {
      debugPrint('Error deleting cosmic order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not delete order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _placedLabel(Item order) {
    final createdAt = order.createdAt;
    if (createdAt == null || createdAt.isEmpty) return 'Placed recently';
    final parsed = DateTime.tryParse(createdAt);
    if (parsed == null) return 'Placed recently';
    return 'Placed ${_dateFormat.format(parsed.toLocal())}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Cosmic Ordering',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Cosmic Ordering guide',
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CosmicOrderingGuidePage(),
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
                    child: _HeroPanel(
                      activeCount: _activeOrders.length,
                      fulfilledCount: _fulfilledOrders.length,
                      isSaving: _isSaving,
                      onCreate: () => _saveOrder(),
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
                          Tab(text: 'Active (${_activeOrders.length})'),
                          Tab(text: 'Fulfilled (${_fulfilledOrders.length})'),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _OrdersList(
                          orders: _activeOrders,
                          fulfilled: false,
                          emptyIcon: Icons.auto_awesome,
                          emptyTitle: 'No active orders yet',
                          emptyMessage:
                              'Place an order for something real but hard to measure.',
                          placedLabelBuilder: _placedLabel,
                          imageUrlLoader: _displayUrlFor,
                          onFulfilled: _toggleFulfilled,
                          onEdit: (order) => _saveOrder(order: order),
                          onDelete: _deleteOrder,
                        ),
                        _OrdersList(
                          orders: _fulfilledOrders,
                          fulfilled: true,
                          emptyIcon: Icons.check_circle_outline,
                          emptyTitle: 'Nothing fulfilled yet',
                          emptyMessage:
                              'Fulfilled orders will appear here when they land.',
                          placedLabelBuilder: _placedLabel,
                          imageUrlLoader: _displayUrlFor,
                          onFulfilled: _toggleFulfilled,
                          onEdit: (order) => _saveOrder(order: order),
                          onDelete: _deleteOrder,
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

class _OrderEditResult {
  final String text;
  final XFile? selectedImage;
  final bool removeExistingImage;

  const _OrderEditResult({
    required this.text,
    required this.selectedImage,
    required this.removeExistingImage,
  });
}

/// Content of the add/edit cosmic order bottom sheet. Owns the
/// [TextEditingController] itself so Flutter disposes it exactly when this
/// widget's element is unmounted (after the sheet's exit transition
/// finishes), instead of the caller disposing it immediately when
/// `Navigator.pop` resolves — which happens well before the ~200ms exit
/// animation completes, while the still-visible `TextField` was still
/// attached to it.
class _OrderEditSheet extends StatefulWidget {
  final Item? order;

  const _OrderEditSheet({this.order});

  @override
  State<_OrderEditSheet> createState() => _OrderEditSheetState();
}

class _OrderEditSheetState extends State<_OrderEditSheet> {
  late final TextEditingController _textController;
  XFile? _selectedImage;
  bool _removeExistingImage = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.order?.text ?? '');
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
      _OrderEditResult(
        text: _textController.text,
        selectedImage: _selectedImage,
        removeExistingImage: _removeExistingImage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final hasExistingImage =
        order?.imageUrl != null && order!.imageUrl!.isNotEmpty;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              order == null ? 'New Cosmic Order' : 'Edit Cosmic Order',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _textController,
              autofocus: order == null,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Describe the order clearly...',
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
                          ? 'Replace image'
                          : 'Add image'
                    : 'Image selected',
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
              child: Text(order == null ? 'Place Order' : 'Save Order'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final List<Item> orders;
  final bool fulfilled;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;
  final String Function(Item order) placedLabelBuilder;
  final Future<String> Function(String url) imageUrlLoader;
  final void Function(Item order) onFulfilled;
  final void Function(Item order) onEdit;
  final void Function(Item order) onDelete;

  const _OrdersList({
    required this.orders,
    required this.fulfilled,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.placedLabelBuilder,
    required this.imageUrlLoader,
    required this.onFulfilled,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: orders.isEmpty
          ? Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SizedBox(
                  width: double.infinity,
                  child: _EmptyPanel(
                    icon: emptyIcon,
                    title: emptyTitle,
                    message: emptyMessage,
                  ),
                ),
              ),
            )
          : PageView.builder(
              physics: const BouncingScrollPhysics(),
              padEnds: false,
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == orders.length - 1 ? 0 : 10,
                  ),
                  child: _OrderCard(
                    order: order,
                    fulfilled: fulfilled,
                    placedLabel: placedLabelBuilder(order),
                    imageUrlLoader: imageUrlLoader,
                    onFulfilled: () => onFulfilled(order),
                    onEdit: () => onEdit(order),
                    onDelete: () => onDelete(order),
                  ),
                );
              },
            ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final int activeCount;
  final int fulfilledCount;
  final bool isSaving;
  final VoidCallback onCreate;

  const _HeroPanel({
    required this.activeCount,
    required this.fulfilledCount,
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
          image: AssetImage('assets/images/app_banners/cosmic_ordering.png'),
          fit: BoxFit.cover,
          opacity: 0.24,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Name it clearly. Keep it visible.',
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
                  '$activeCount active  •  $fulfilledCount fulfilled',
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
            label: const Text('New Order'),
          ),
        ],
      ),
    );
  }
}

class CosmicOrderingGuidePage extends StatelessWidget {
  const CosmicOrderingGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Cosmic Ordering Guide',
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
            _GuideHero(),
            SizedBox(height: 16),
            _GuideSection(
              icon: Icons.history_edu_outlined,
              title: 'Where it came from',
              body:
                  'Cosmic Ordering is a modern manifestation practice most closely associated with German author Bärbel Mohr. Mohr developed and popularised the idea through her writing on “ordering from the universe”, especially her book The Cosmic Ordering Service. In the UK, the idea later became widely known through television presenter Noel Edmonds, who publicly credited the practice as part of a major turning point in his life and career.\n\nThe basic idea is simple: you write down a clear desire as if placing an order, then release the grasping around it while staying alert to opportunities, choices, and aligned action. It sits close to practices such as intention setting, visualisation, affirmations, gratitude, and the law of attraction.',
            ),
            _GuideSection(
              icon: Icons.auto_awesome,
              title: 'What cosmic ordering is',
              body:
                  'A cosmic order is not a normal task, goal, or shopping list. It is for desires that matter emotionally but may not fit neatly into a spreadsheet: meeting the right person, finding the right home, receiving an unexpected opening, attracting a mentor, calling in confidence, or experiencing a new kind of peace.\n\nThe order should be clear enough that you would recognise it if it arrived, but open enough that life can deliver it in a form better than your first guess. The practice is less about controlling every detail and more about giving your mind, attention, and behaviour a clean direction.',
            ),
            _GuideSection(
              icon: Icons.edit_note_outlined,
              title: 'How to create an order',
              body:
                  'Start by naming what you want in plain language. Avoid vague phrases like “better life” or “more success”. Instead, describe the actual experience you want to receive: “I am ready to meet a kind, emotionally available partner”, “I receive the right opportunity to grow my work”, or “I find a home that feels calm, safe, and affordable.”\n\nKeep it positive and direct. Write what you are moving toward, not what you are escaping. Add an image if one helps your body recognise the feeling of receiving it. The image does not need to be literal; it only needs to make the desire feel more real and emotionally available.',
            ),
            _GuideSection(
              icon: Icons.visibility_outlined,
              title: 'How to visualize receiving it',
              body:
                  'After placing the order, spend a short moment imagining the desire already received. Picture the ordinary proof: the message arriving, the door opening, the conversation happening, the room you are standing in, the relief in your body, or the next step becoming obvious.\n\nDo not force the image for ages. A clear thirty seconds is better than ten strained minutes. The useful question is: “What would I naturally do today if I trusted this was moving toward me?” That question turns visualisation into behaviour.',
            ),
            _GuideSection(
              icon: Icons.directions_walk_outlined,
              title: 'Aligned action',
              body:
                  'Cosmic ordering is not passive waiting. Once the order is placed, act like someone available for the result. If the order is for a relationship, become easier to meet and more honest about what you want. If it is for an opportunity, tidy your portfolio, reply to messages, make the call, apply, ask, practise, or prepare.\n\nThe order gives your attention a direction. Your actions give the direction somewhere to land.',
            ),
            _GuideSection(
              icon: Icons.app_registration_outlined,
              title: 'How to use this app',
              body:
                  'Use the Active tab as your current order list. Tap New Order, write the desire clearly, and optionally attach an image that captures the feeling of receiving it. Keep active orders alive by reviewing them, refining wording when needed, and noticing whether your actions match the version of you who could receive them.\n\nUse the Fulfilled tab as evidence. When an order arrives, tap Fulfilled. This moves it out of Active and into Fulfilled so you can build a record of what landed. That record matters: it trains you to notice results instead of rushing past them.',
            ),
            _GuideSection(
              icon: Icons.check_circle_outline,
              title: 'Marking an order fulfilled',
              body:
                  'Mark an order fulfilled when the essence of it has arrived, even if the details are not exactly how you imagined. If you ordered “the right mentor” and a useful teacher, advisor, book, or conversation arrives, pause before dismissing it. Cosmic Ordering works best when you recognise the shape of the answer, not only the costume you expected it to wear.\n\nIf something was marked fulfilled too early, use Move Back to return it to Active. The list is allowed to breathe as your clarity improves.',
            ),
            _GuideSection(
              icon: Icons.tips_and_updates_outlined,
              title: 'A useful rhythm',
              body:
                  'Place the order once. Review it regularly. Visualize receiving it briefly. Take one aligned action. Let the method support momentum instead of replacing it.\n\nA good order feels clear, emotionally honest, and spacious. You should be able to read it and think: “Yes, that is what I am available to receive, and I know how I can move with it today.”',
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideHero extends StatelessWidget {
  const _GuideHero();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withAlpha(42)),
        image: const DecorationImage(
          image: AssetImage('assets/images/app_banners/cosmic_ordering.png'),
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
            'A practical guide to placing, living with, and completing cosmic orders.',
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

class _GuideSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _GuideSection({
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

class _OrderCard extends StatelessWidget {
  final Item order;
  final bool fulfilled;
  final String placedLabel;
  final Future<String> Function(String url) imageUrlLoader;
  final VoidCallback onFulfilled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _OrderCard({
    required this.order,
    required this.fulfilled,
    required this.placedLabel,
    required this.imageUrlLoader,
    required this.onFulfilled,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = order.imageUrl;
    final imageAspectRatio = isTabletLandscape(context) ? 16 / 5 : 16 / 9;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: fulfilled
            ? Colors.green.withAlpha(18)
            : colorScheme.surfaceContainerHighest.withAlpha(95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: fulfilled
              ? Colors.green.withAlpha(75)
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
                ? _ImagePlaceholder(fulfilled: fulfilled)
                : RepositionableNetworkImage(
                    key: ValueKey('cosmic-order-image-${order.id}'),
                    imageUrl: imageUrl,
                    imageUrlLoader: imageUrlLoader,
                    positionKey: 'cosmic-order.${order.id}',
                    frameAspectRatio: imageAspectRatio,
                    placeholderBuilder: () =>
                        _ImagePlaceholder(fulfilled: fulfilled),
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
                          color: fulfilled
                              ? Colors.green.withAlpha(25)
                              : colorScheme.primary.withAlpha(22),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          fulfilled ? 'FULFILLED' : 'ORDERED',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: fulfilled
                                ? Colors.green
                                : colorScheme.primary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        placedLabel,
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
                        order.text,
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
                          onPressed: onFulfilled,
                          icon: Icon(
                            fulfilled ? Icons.undo : Icons.check_circle_outline,
                          ),
                          label: Text(fulfilled ? 'Move Back' : 'Fulfilled'),
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

class _ImagePlaceholder extends StatelessWidget {
  final bool fulfilled;

  const _ImagePlaceholder({required this.fulfilled});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: fulfilled
          ? Colors.green.withAlpha(24)
          : colorScheme.primary.withAlpha(18),
      child: Icon(
        fulfilled ? Icons.check_circle_outline : Icons.auto_awesome,
        color: fulfilled ? Colors.green : colorScheme.primary,
        size: 42,
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline.withAlpha(40)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 38, color: colorScheme.primary.withAlpha(160)),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: colorScheme.onSurface.withAlpha(145),
            ),
          ),
        ],
      ),
    );
  }
}
