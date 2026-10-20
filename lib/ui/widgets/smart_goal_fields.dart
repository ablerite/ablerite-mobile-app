import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SmartGoalFields extends StatefulWidget {
  const SmartGoalFields({
    super.key,
    required this.specificController,
    required this.measurableController,
    required this.achievableController,
    required this.relevantController,
    this.initiallyExpanded = false,
    this.collapsible = true,
  });

  final TextEditingController specificController;
  final TextEditingController measurableController;
  final TextEditingController achievableController;
  final TextEditingController relevantController;
  final bool initiallyExpanded;
  final bool collapsible;

  @override
  State<SmartGoalFields> createState() => _SmartGoalFieldsState();
}

class _SmartGoalFieldsState extends State<SmartGoalFields> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final fields = [
      (
        letter: 'S',
        label: 'Specific',
        hint: 'What exactly do you want to achieve?',
        controller: widget.specificController,
      ),
      (
        letter: 'M',
        label: 'Measurable',
        hint: 'How will you measure progress or success?',
        controller: widget.measurableController,
      ),
      (
        letter: 'A',
        label: 'Achievable',
        hint: 'What makes this realistic and within your control?',
        controller: widget.achievableController,
      ),
      (
        letter: 'R',
        label: 'Relevant',
        hint: 'How does this support what matters to you?',
        controller: widget.relevantController,
      ),
    ];
    final completedFields = fields
        .where((field) => field.controller.text.trim().isNotEmpty)
        .length;
    final theme = Theme.of(context);
    final isExpanded = !widget.collapsible || _isExpanded;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.primary.withAlpha(55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: widget.collapsible
                ? () => setState(() => _isExpanded = !_isExpanded)
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: theme.colorScheme.primary.withAlpha(30),
                    child: Icon(
                      Icons.track_changes,
                      color: theme.colorScheme.primary,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Make it SMART',
                          style: GoogleFonts.outfit(
                            color: theme.colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          completedFields == 0
                              ? 'Add the four optional SMART details'
                              : '$completedFields of 4 SMART details added',
                          style: GoogleFonts.outfit(
                            color: theme.colorScheme.onSurface.withAlpha(150),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.collapsible)
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: theme.colorScheme.onSurface.withAlpha(170),
                      ),
                    ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: theme.colorScheme.primary.withAlpha(45)),
                  const SizedBox(height: 4),
                  Text(
                    'Your due date covers Time-bound. Add the other four parts below.',
                    style: GoogleFonts.outfit(
                      color: theme.colorScheme.onSurface.withAlpha(150),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...fields.map(
                    (field) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: field.controller,
                        minLines: 2,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: '${field.letter} — ${field.label}',
                          hintText: field.hint,
                          alignLabelWithHint: true,
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12),
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: theme.colorScheme.primary
                                  .withAlpha(30),
                              child: Text(
                                field.letter,
                                style: GoogleFonts.outfit(
                                  color: theme.colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
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
