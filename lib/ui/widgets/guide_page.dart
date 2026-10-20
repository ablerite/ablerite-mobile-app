import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GuideSectionData {
  final IconData icon;
  final String title;
  final String body;
  final String? imageAsset;
  final String? headingBadgeAsset;
  final double? imagePreviewAspectRatio;
  final Alignment imagePreviewAlignment;

  const GuideSectionData({
    required this.icon,
    required this.title,
    required this.body,
    this.imageAsset,
    this.headingBadgeAsset,
    this.imagePreviewAspectRatio,
    this.imagePreviewAlignment = Alignment.center,
  });
}

/// Shared visual shell for the per-hub "guide" pages opened from the book
/// icon next to a hub's walkthrough (?) button. Keeps every guide (MBS,
/// Media, Action Center, Exploration, Home) visually consistent.
class GuidePage extends StatelessWidget {
  final String appBarTitle;
  final String? heroImageAsset;
  final String? heroHeadline;
  final List<GuideSectionData> sections;

  const GuidePage({
    super.key,
    required this.appBarTitle,
    this.heroImageAsset,
    this.heroHeadline,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          appBarTitle,
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
          children: [
            if (heroHeadline != null) ...[
              _GuideHero(imageAsset: heroImageAsset, headline: heroHeadline!),
              const SizedBox(height: 16),
            ],
            for (final section in sections) _GuideSectionCard(section: section),
          ],
        ),
      ),
    );
  }
}

class _GuideHero extends StatelessWidget {
  final String? imageAsset;
  final String headline;

  const _GuideHero({required this.imageAsset, required this.headline});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withAlpha(42)),
        image: imageAsset == null
            ? null
            : DecorationImage(
                image: AssetImage(imageAsset!),
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
            headline,
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

class _GuideSectionCard extends StatelessWidget {
  final GuideSectionData section;

  const _GuideSectionCard({required this.section});

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(section.icon, color: colorScheme.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  section.title,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              if (section.headingBadgeAsset != null) ...[
                const SizedBox(width: 6),
                Image.asset(
                  section.headingBadgeAsset!,
                  width: 44,
                  height: 21,
                  fit: BoxFit.contain,
                  semanticLabel: 'Feature access badge',
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            section.body,
            style: GoogleFonts.outfit(
              fontSize: 14,
              height: 1.45,
              color: colorScheme.onSurface.withAlpha(180),
            ),
          ),
          if (section.imageAsset != null) ...[
            const SizedBox(height: 14),
            _GuideImagePreview(
              imageAsset: section.imageAsset!,
              title: section.title,
              aspectRatio: section.imagePreviewAspectRatio,
              alignment: section.imagePreviewAlignment,
            ),
          ],
        ],
      ),
    );
  }
}

class _GuideImagePreview extends StatelessWidget {
  final String imageAsset;
  final String title;
  final double? aspectRatio;
  final Alignment alignment;

  const _GuideImagePreview({
    required this.imageAsset,
    required this.title,
    required this.aspectRatio,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              _GuideImageViewerPage(imageAsset: imageAsset, title: title),
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              color: colorScheme.surface,
              // Most guide images keep their full aspect ratio. Individual
              // sections can opt into a compact cover crop for tall screens;
              // tapping the preview still opens the complete image.
              child: aspectRatio == null
                  ? Image.asset(
                      imageAsset,
                      fit: BoxFit.fitWidth,
                      width: double.infinity,
                    )
                  : AspectRatio(
                      aspectRatio: aspectRatio!,
                      child: Image.asset(
                        imageAsset,
                        fit: BoxFit.cover,
                        alignment: alignment,
                      ),
                    ),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(140),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.zoom_in, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideImageViewerPage extends StatelessWidget {
  final String imageAsset;
  final String title;

  const _GuideImageViewerPage({required this.imageAsset, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(title, style: GoogleFonts.outfit()),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: Image.asset(imageAsset, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
