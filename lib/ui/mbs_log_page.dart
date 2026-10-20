import 'package:flutter/material.dart';
import 'widgets/ablerite_loading_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/item.dart';

/// Dedicated page showing this week's logged entries for an MBS section,
/// with edit and delete support.
class MBSLogPage extends StatefulWidget {
  final String title;
  final String section;
  final Color color;

  const MBSLogPage({
    super.key,
    required this.title,
    required this.section,
    required this.color,
  });

  @override
  State<MBSLogPage> createState() => _MBSLogPageState();
}

class _MBSLogPageState extends State<MBSLogPage> {
  List<Item> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  // ── Date helpers ────────────────────────────────────────────────────────────

  Map<String, DateTime> _getCurrentWeekRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final startOfWeek = start.subtract(Duration(days: start.weekday % 7));
    return {
      'start': startOfWeek,
      'end': startOfWeek.add(const Duration(days: 7)),
    };
  }

  bool _isInCurrentWeek(String? dateStr) {
    if (dateStr == null) return false;
    final d = DateTime.tryParse(dateStr);
    if (d == null) return false;
    final r = _getCurrentWeekRange();
    return d.isAfter(r['start']!.subtract(const Duration(days: 1))) &&
        d.isBefore(r['end']!);
  }

  // ── Data ────────────────────────────────────────────────────────────────────

  Future<void> _fetchLogs() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final res = await Supabase.instance.client
          .from('items')
          .select()
          .eq('user_id', userId)
          .eq('section', widget.section)
          .order('date', ascending: false);
      if (mounted) {
        setState(() {
          _logs = (res as List).map((e) => Item.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteLog(Item log) async {
    try {
      await Supabase.instance.client.from('items').delete().eq('id', log.id);
      setState(() => _logs.removeWhere((l) => l.id == log.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _editLog(Item log) async {
    final controller = TextEditingController(text: '${log.value ?? ''}');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Entry',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Minutes',
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: widget.color.withAlpha(80)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: widget.color, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final v = int.tryParse(controller.text);
              if (v != null && v > 0) Navigator.pop(ctx, v);
            },
            child: Text(
              'Save',
              style: GoogleFonts.outfit(
                color: widget.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (result != null) {
      try {
        await Supabase.instance.client
            .from('items')
            .update({'value': result})
            .eq('id', log.id);
        setState(() {
          final idx = _logs.indexWhere((l) => l.id == log.id);
          if (idx != -1) {
            _logs[idx] = Item(
              id: log.id,
              text: log.text,
              section: log.section,
              value: result,
              date: log.date,
              userId: log.userId,
            );
          }
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _confirmDelete(Item log) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Entry?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Remove this ${log.value} min entry from ${log.date}?',
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(170),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteLog(log);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.outfit(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final weekLogs = _logs.where((l) => _isInCurrentWeek(l.date)).toList();
    final allLogs = _logs.where((l) => !_isInCurrentWeek(l.date)).toList();
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: onSurface),
        title: Text(
          '${widget.title} — Log',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: onSurface,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: AbleriteLoadingIndicator())
          : _logs.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: onSurface.withAlpha(60),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No entries yet',
                    style: GoogleFonts.outfit(
                      color: onSurface.withAlpha(100),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (weekLogs.isNotEmpty) ...[
                  _SectionHeader(label: 'THIS WEEK', color: widget.color),
                  const SizedBox(height: 8),
                  ...weekLogs.map(
                    (log) => _LogTile(
                      log: log,
                      color: widget.color,
                      onEdit: () => _editLog(log),
                      onDelete: () => _confirmDelete(log),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (allLogs.isNotEmpty) ...[
                  _SectionHeader(
                    label: 'EARLIER',
                    color: onSurface.withAlpha(100),
                  ),
                  const SizedBox(height: 8),
                  ...allLogs.map(
                    (log) => _LogTile(
                      log: log,
                      color: widget.color,
                      onEdit: () => _editLog(log),
                      onDelete: () => _confirmDelete(log),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

// ── Small widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: GoogleFonts.outfit(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: 1.5,
    ),
  );
}

class _LogTile extends StatelessWidget {
  final Item log;
  final Color color;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LogTile({
    required this.log,
    required this.color,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor.withAlpha(30)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${log.value ?? 0}',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        title: Text(
          '${log.value ?? 0} mins',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          _formatDate(log.date),
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(130),
              ),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 18,
                color: Colors.red,
              ),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final d = DateTime.parse(dateStr);
      return DateFormat('EEE, d MMM yyyy').format(d);
    } catch (_) {
      return dateStr;
    }
  }
}
