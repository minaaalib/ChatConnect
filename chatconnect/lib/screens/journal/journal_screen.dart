import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../../models/journal_entry.dart';
import '../../services/journal_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/apple_emoji.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              _JournalHeader(onBack: () => Navigator.of(context).maybePop()),
              Expanded(
                child: Consumer<JournalService>(
                  builder: (context, journal, _) {
                    final entries = journal.entries;
                    if (entries.isEmpty) {
                      return Center(
                        child: Text(
                          'No entries yet. Tap + to write your first one.',
                          style: textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (context, i) =>
                          _JournalEntryCard(entry: entries[i]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryContainer,
        onPressed: () => _openComposer(context),
        child: const Icon(
          PhosphorIconsBold.plus,
          color: AppColors.onPrimaryContainer,
        ),
      ),
    );
  }

  void _openComposer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _JournalComposerSheet(),
    );
  }
}

class _JournalHeader extends StatelessWidget {
  const _JournalHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              PhosphorIconsBold.arrowLeft,
              color: AppColors.primary,
            ),
          ),
          const Icon(PhosphorIconsFill.notePencil, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('Journal', style: textTheme.headlineSmall),
        ],
      ),
    );
  }
}

class _JournalEntryCard extends StatelessWidget {
  const _JournalEntryCard({required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (entry.moodEmoji != null) ...[
                AppleEmoji(entry.moodEmoji!, size: 22),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  entry.title,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              Text(
                _formatDate(entry.createdAt),
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            entry.content,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '$diff days ago';
  }
}

class _JournalComposerSheet extends StatefulWidget {
  const _JournalComposerSheet();

  @override
  State<_JournalComposerSheet> createState() => _JournalComposerSheetState();
}

class _JournalComposerSheetState extends State<_JournalComposerSheet> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _selectedMood;

  static const _moods = ['😊', '😐', '😔', '😡', '😰'];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) return;
    context.read<JournalService>().addEntry(
      title: title,
      content: content,
      moodEmoji: _selectedMood,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New journal entry',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: "What's on your mind?",
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final mood in _moods)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _MoodPickerChip(
                      emoji: mood,
                      selected: _selectedMood == mood,
                      onTap: () => setState(() => _selectedMood = mood),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Save entry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodPickerChip extends StatelessWidget {
  const _MoodPickerChip({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryContainer.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primaryContainer : Colors.transparent,
          ),
        ),
        child: AppleEmoji(emoji, size: 26),
      ),
    );
  }
}
