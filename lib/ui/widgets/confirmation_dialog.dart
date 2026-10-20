import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<bool?> showDeleteConfirmation(
  BuildContext context, {
  String title = 'Delete Item?',
  String content = 'This action cannot be undone.',
  String confirmText = 'Delete', // Unused but kept for API compatibility
}) {
  return showDeleteBottomSheet(context, title: title, subtitle: content);
}

/// Show a consistent options bottom sheet with Edit and Delete options
Future<String?> showOptionsBottomSheet(
  BuildContext context, {
  required String title,
  String? subtitle,
  required String editLabel,
  required String deleteLabel,
  String? moveLabel,
  bool showEdit = true,
}) {
  return showModalBottomSheet<String>(
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
          // Title
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Subtitle if provided
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 24),
          // Edit option
          if (showEdit)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: Text(
                editLabel,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
          if (showEdit)
            Divider(
              color: Theme.of(context).dividerColor.withAlpha(50),
              height: 1,
            ),

          // Move option
          if (moveLabel != null)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.drive_file_move_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: Text(
                moveLabel,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () => Navigator.pop(context, 'move'),
            ),
          if (moveLabel != null)
            Divider(
              color: Theme.of(context).dividerColor.withAlpha(50),
              height: 1,
            ),

          // Delete option
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete, color: Colors.red),
            ),
            title: Text(
              deleteLabel,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () => Navigator.pop(context, 'delete'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Show a simple delete confirmation bottom sheet
Future<bool?> showDeleteBottomSheet(
  BuildContext context, {
  required String title,
  String? subtitle,
}) {
  return showModalBottomSheet<bool>(
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
          // Warning icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFFEE2E2), // Light red circle
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFEF4444),
              size: 32,
            ), // Solid red icon
          ),
          const SizedBox(height: 20),
          // Title
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          // Subtitle if provided
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 32),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFFE5E7EB),
                      width: 1.5,
                    ), // Grey outline
                    shape:
                        const StadiumBorder(), // Pill-shaped as in the design
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF6B7280),
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFFEF4444,
                    ), // Solid red background
                    foregroundColor: Colors.white,
                    shape:
                        const StadiumBorder(), // Pill-shaped as in the design
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0, // Flat appearance like the design
                  ),
                  child: Text(
                    'Delete',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Show a "Coming Soon" bottom sheet for features not yet implemented
Future<void> showComingSoonBottomSheet(
  BuildContext context, {
  String title = 'Coming Soon',
  String? subtitle,
  IconData icon = Icons.mic,
}) {
  return showModalBottomSheet<void>(
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
          // Coming soon icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          // Subtitle if provided
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          // OK button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'OK',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
