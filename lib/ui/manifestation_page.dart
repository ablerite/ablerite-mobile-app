import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/focus_app_bar_actions.dart';

import '../services/navigation_service.dart';
import 'cosmic_ordering_page.dart';
import 'expectations_page.dart';
import 'widgets/hub_intro_panel.dart';
import 'widgets/tablet_layout.dart';

class ManifestationPage extends StatefulWidget {
  const ManifestationPage({super.key});

  @override
  State<ManifestationPage> createState() => _ManifestationPageState();
}

class _ManifestationPageState extends State<ManifestationPage> {
  @override
  void initState() {
    super.initState();
    pushPage();
  }

  @override
  void dispose() {
    popPage();
    super.dispose();
  }

  void _openExpectations() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExpectationsPage()),
    );
  }

  void _openCosmicOrdering() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CosmicOrderingPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).height < 760;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: FocusAwareAppBarTitle(
          child: Text(
            'Manifestation',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: const FocusAwareBackButton(),
        actions: const [FocusAppBarActions(guide: FocusHelpGuide.exploration)],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final landscapeTablet = isTabletLandscape(context);
            final cosmicOrderingCard = _ManifestationOptionCard(
              icon: Icons.auto_awesome,
              title: 'Cosmic Ordering',
              subtitle:
                  'Place orders, add images, and sync fulfilled desires with desktop.',
              bannerAsset: 'assets/images/manifestation/cosmicodering.png',
              color: const Color(0xFF8B5CF6),
              bannerScale: 1.12,
              onTap: _openCosmicOrdering,
            );
            final expectationsCard = _ManifestationOptionCard(
              icon: Icons.track_changes,
              title: 'Expectations',
              subtitle:
                  'Name what you expect, organize it by life area, and keep it visible as you grow.',
              bannerAsset: 'assets/images/manifestation/expectations.png',
              color: const Color(0xFF2FA7A0),
              onTap: _openExpectations,
            );
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, compact ? 4 : 8, 16, 12),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 16,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 4,
                          right: 4,
                          bottom: 8,
                        ),
                        child: Text(
                          'Set the signal, then keep moving with intention.',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: colorScheme.onSurface.withAlpha(160),
                            height: 1.25,
                          ),
                        ),
                      ),
                      Expanded(
                        child: landscapeTablet
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(child: cosmicOrderingCard),
                                        const SizedBox(height: 10),
                                        Expanded(child: expectationsCard),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    flex: 4,
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: HubLandscapeInfoPanel(
                                        icon: Icons.auto_awesome_outlined,
                                        title:
                                            'Set intention, then stay available',
                                        body:
                                            'Manifestation works best when clarity and action stay together. Name what you want, notice the expectations guiding you, and keep moving toward opportunities that match the signal.',
                                        highlights: [
                                          'Cosmic Ordering captures desires and evidence.',
                                          'Expectations reveals the standards shaping your choices.',
                                        ],
                                        accentColor: Color(0xFF8B5CF6),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: cosmicOrderingCard),
                                  const SizedBox(height: 10),
                                  Expanded(child: expectationsCard),
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
    );
  }
}

class _ManifestationOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String bannerAsset;
  final Color color;
  final double bannerScale;
  final VoidCallback onTap;

  const _ManifestationOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.bannerAsset,
    required this.color,
    this.bannerScale = 1,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withAlpha(46)),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(14),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: AspectRatio(
                  aspectRatio: isTabletLandscape(context) ? 16 / 6.5 : 16 / 9,
                  child: ClipRect(
                    child: Transform.scale(
                      scale: bannerScale,
                      alignment: isTabletLandscape(context)
                          ? Alignment.topCenter
                          : Alignment.center,
                      child: Image.asset(
                        bannerAsset,
                        fit: BoxFit.cover,
                        alignment: isTabletLandscape(context)
                            ? Alignment.topCenter
                            : Alignment.center,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: color.withAlpha(24),
                            child: Icon(icon, color: color, size: 36),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: colorScheme.onSurface.withAlpha(110),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: colorScheme.onSurface.withAlpha(150),
                          height: 1.28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
