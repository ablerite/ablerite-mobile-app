import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RepositionableNetworkImage extends StatefulWidget {
  final String imageUrl;
  final Future<String> Function(String url) imageUrlLoader;
  final String positionKey;
  final double frameAspectRatio;
  final Widget Function() placeholderBuilder;

  const RepositionableNetworkImage({
    super.key,
    required this.imageUrl,
    required this.imageUrlLoader,
    required this.positionKey,
    required this.frameAspectRatio,
    required this.placeholderBuilder,
  });

  @override
  State<RepositionableNetworkImage> createState() =>
      _RepositionableNetworkImageState();
}

class _RepositionableNetworkImageState
    extends State<RepositionableNetworkImage> {
  late Future<String> _displayUrl;
  Alignment _alignment = Alignment.center;

  String get _xPreferenceKey => '${widget.positionKey}.alignment-x';
  String get _yPreferenceKey => '${widget.positionKey}.alignment-y';

  @override
  void initState() {
    super.initState();
    _displayUrl = widget.imageUrlLoader(widget.imageUrl);
    _loadAlignment();
  }

  @override
  void didUpdateWidget(covariant RepositionableNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _displayUrl = widget.imageUrlLoader(widget.imageUrl);
      _alignment = Alignment.center;
      _saveAlignment(Alignment.center);
    }
    if (oldWidget.positionKey != widget.positionKey) {
      _alignment = Alignment.center;
      _loadAlignment();
    }
  }

  Future<void> _loadAlignment() async {
    final preferences = await SharedPreferences.getInstance();
    final x = preferences.getDouble(_xPreferenceKey);
    final y = preferences.getDouble(_yPreferenceKey);
    if (!mounted || (x == null && y == null)) return;
    setState(() {
      _alignment = Alignment((x ?? 0).clamp(-1, 1), (y ?? 0).clamp(-1, 1));
    });
  }

  Future<void> _saveAlignment(Alignment alignment) async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setDouble(_xPreferenceKey, alignment.x),
      preferences.setDouble(_yPreferenceKey, alignment.y),
    ]);
  }

  Future<void> _openPreview(String url) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withAlpha(220),
      builder: (previewContext) {
        final colorScheme = Theme.of(previewContext).colorScheme;
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920, maxHeight: 760),
            child: SizedBox(
              width: double.infinity,
              height: MediaQuery.sizeOf(previewContext).height * 0.82,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Image preview',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close preview',
                          onPressed: () => Navigator.pop(previewContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: colorScheme.outlineVariant),
                  Expanded(
                    child: ColoredBox(
                      color: Colors.black,
                      child: InteractiveViewer(
                        minScale: 0.8,
                        maxScale: 5,
                        child: Center(
                          child: Image.network(
                            url,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                widget.placeholderBuilder(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    minimum: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _openPositionEditor(url),
                        icon: const Icon(Icons.open_with),
                        label: const Text('Reposition'),
                      ),
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

  Future<void> _openPositionEditor(String url) async {
    final updatedAlignment = await showDialog<Alignment>(
      context: context,
      barrierDismissible: false,
      builder: (editorContext) {
        var draftAlignment = _alignment;
        return StatefulBuilder(
          builder: (context, setEditorState) {
            final colorScheme = Theme.of(context).colorScheme;
            return Dialog.fullscreen(
              backgroundColor: colorScheme.surface,
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Cancel',
                            onPressed: () => Navigator.pop(editorContext),
                            icon: const Icon(Icons.close),
                          ),
                          const Expanded(
                            child: Text(
                              'Reposition image',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(editorContext, draftAlignment),
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Drag the image until the crop looks right.',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final availableWidth = math
                              .min(constraints.maxWidth - 32, 920)
                              .toDouble();
                          final availableHeight = constraints.maxHeight - 32;
                          var frameWidth = availableWidth;
                          var frameHeight =
                              frameWidth / widget.frameAspectRatio;
                          if (frameHeight > availableHeight) {
                            frameHeight = availableHeight;
                            frameWidth = frameHeight * widget.frameAspectRatio;
                          }

                          return Center(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanUpdate: (details) {
                                setEditorState(() {
                                  draftAlignment = Alignment(
                                    (draftAlignment.x -
                                            details.delta.dx / (frameWidth / 2))
                                        .clamp(-1, 1),
                                    (draftAlignment.y -
                                            details.delta.dy /
                                                (frameHeight / 2))
                                        .clamp(-1, 1),
                                  );
                                });
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: SizedBox(
                                  width: frameWidth,
                                  height: frameHeight,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(
                                        url,
                                        fit: BoxFit.cover,
                                        alignment: draftAlignment,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                widget.placeholderBuilder(),
                                      ),
                                      IgnorePointer(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.white.withAlpha(
                                                190,
                                              ),
                                              width: 2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.open_with,
                                              color: Colors.white,
                                              size: 38,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black54,
                                                  blurRadius: 8,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      top: false,
                      minimum: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      child: OutlinedButton.icon(
                        onPressed: () => setEditorState(
                          () => draftAlignment = Alignment.center,
                        ),
                        icon: const Icon(Icons.center_focus_strong),
                        label: const Text('Reset to centre'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (updatedAlignment == null || !mounted) return;
    setState(() => _alignment = updatedAlignment);
    await _saveAlignment(updatedAlignment);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _displayUrl,
      builder: (context, snapshot) {
        final url = snapshot.data;
        if (url == null || url.isEmpty) return widget.placeholderBuilder();

        return Semantics(
          button: true,
          label: 'Open image preview and reposition image',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _openPreview(url),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  url,
                  fit: BoxFit.cover,
                  alignment: _alignment,
                  errorBuilder: (context, error, stackTrace) =>
                      widget.placeholderBuilder(),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(145),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.zoom_out_map,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
