import 'package:flutter/material.dart';
import 'ablerite_loading_indicator.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../services/subscription_service.dart';
import 'tablet_layout.dart';

class DesktopAppDialog {
  static const String desktopAppUrl = 'https://app.ablerite.com/';

  static Future<void> show(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;

    Future<void> copyDesktopAppUrl() async {
      await Clipboard.setData(const ClipboardData(text: desktopAppUrl));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Desktop app link copied'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }

    Future<void> openDesktopAppUrl() async {
      final uri = Uri.parse(desktopAppUrl);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open desktop app link')),
        );
      }
    }

    await showDialog(
      context: context,
      builder: (dialogContext) => _DesktopAppDialogContent(
        colorScheme: colorScheme,
        copyDesktopAppUrl: copyDesktopAppUrl,
        openDesktopAppUrl: openDesktopAppUrl,
      ),
    );
  }
}

class _DesktopAppDialogContent extends StatefulWidget {
  final ColorScheme colorScheme;
  final Future<void> Function() copyDesktopAppUrl;
  final Future<void> Function() openDesktopAppUrl;

  const _DesktopAppDialogContent({
    required this.colorScheme,
    required this.copyDesktopAppUrl,
    required this.openDesktopAppUrl,
  });

  @override
  State<_DesktopAppDialogContent> createState() =>
      _DesktopAppDialogContentState();
}

class _DesktopAppDialogContentState extends State<_DesktopAppDialogContent> {
  late final VideoPlayerController _controller;
  late final Future<void> _initializeVideo;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(
      'assets/video/desktop/desktop.mp4',
    );
    _initializeVideo = _prepareVideo();
  }

  Future<void> _prepareVideo() async {
    await _controller.initialize();
    await _controller.setLooping(true);
    await _controller.setVolume(0);
    if (!mounted) return;
    setState(() => _isReady = true);
    await _controller.play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.colorScheme;
    final isTablet = isTabletLayout(context);
    final isLandscapeTablet = isTabletLandscape(context);
    final videoPreview = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: FutureBuilder<void>(
          future: _initializeVideo,
          builder: (context, snapshot) {
            if (_isReady) {
              return ColoredBox(
                color: Colors.black,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              );
            }
            return Container(
              color: colorScheme.primary.withAlpha(18),
              child: Center(
                child: AbleriteLoadingIndicator(color: colorScheme.primary),
              ),
            );
          },
        ),
      ),
    );
    final details = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'The Ablerite desktop app is available for paid users and is designed to work on Samsung DeX, macOS, and Windows PCs.',
          style: TextStyle(
            color: colorScheme.onSurface.withAlpha(180),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        SelectableText(
          DesktopAppDialog.desktopAppUrl,
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.copyDesktopAppUrl,
                child: const Text('Copy URL'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: widget.openDesktopAppUrl,
                child: const Text('Open Link'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (!context.mounted) return;
              await SubscriptionService().showDirectPaywallIfNeeded();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            child: const Text('Go Pro'),
          ),
        ),
      ],
    );

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      scrollable: isTablet && !isLandscapeTablet,
      constraints: isTablet
          ? tabletDialogConstraints(
              context,
              portraitWidth: 660,
              landscapeWidth: 860,
              heightFactor: 0.78,
            )
          : null,
      insetPadding: isTablet
          ? const EdgeInsets.symmetric(horizontal: 24, vertical: 32)
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      title: Text(
        'Pro Desktop App',
        style: TextStyle(color: colorScheme.onSurface),
      ),
      content: isLandscapeTablet
          ? SizedBox(
              width: 800,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: videoPreview),
                  const SizedBox(width: 24),
                  Expanded(flex: 4, child: details),
                ],
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: isTablet ? 330 : 240),
                  child: videoPreview,
                ),
                const SizedBox(height: 16),
                details,
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}
