import 'package:flutter/material.dart';

import '../../app/iter_theme.dart';
import '../../models/trip_models.dart' show JourneyRoute;
import '../../widgets/journey_media.dart';
import 'chat_first_data.dart';
import 'chat_first_preview_sheet.dart';

/// Chat-first Home: one featured decision, then horizontal rows for resume and
/// inspiration. Every card shows a single city name, a poster and the why.
class ChatFirstHomeScreen extends StatelessWidget {
  const ChatFirstHomeScreen({
    super.key,
    required this.journeys,
    required this.resumable,
    required this.onStartChat,
    required this.onResume,
    required this.onOpenChats,
    required this.unread,
  });

  final List<JourneyRoute> journeys;
  final List<ChatThread> resumable;
  final ValueChanged<JourneyRoute> onStartChat;
  final ValueChanged<ChatThread> onResume;
  final VoidCallback onOpenChats;
  final int unread;

  static String _greetingFor(DateTime now) =>
      now.hour < 13 ? 'Buongiorno' : 'Buonasera';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final ranked = List<JourneyRoute>.of(journeys)
      ..sort((a, b) => b.matchScore.compareTo(a.matchScore));
    final featured = ranked.isNotEmpty ? ranked.first : null;
    final traveledCities =
        resumable.map((t) => t.summary.title).toSet();
    final picks = ranked
        .where((j) => j != featured && !traveledCities.contains(journeyCity(j)))
        .take(6)
        .toList(growable: false);
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 110),
        children: <Widget>[
          _TopBar(unread: unread, onOpenChats: onOpenChats),
          const SizedBox(height: 20),
          Text(
            _greetingFor(now),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Un viaggio da tenere a mente e le tue conversazioni in corso.',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (featured != null) ...<Widget>[
            const SizedBox(height: 18),
            _FeaturedBanner(
              journey: featured,
              onStartChat: () => onStartChat(featured),
            ),
          ],
          if (resumable.isNotEmpty) ...<Widget>[
            const SizedBox(height: 30),
            _SectionTitle(
              title: 'Riprendi',
              trailingLabel: 'Tutte',
              onTrailing: onOpenChats,
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 128,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: resumable.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) => _ResumeCard(
                  thread: resumable[index],
                  onTap: () => onResume(resumable[index]),
                ),
              ),
            ),
          ],
          if (picks.isNotEmpty) ...<Widget>[
            const SizedBox(height: 30),
            const _SectionTitle(title: 'Ispirazioni per te'),
            const SizedBox(height: 14),
            SizedBox(
              height: 316,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: picks.length,
                separatorBuilder: (_, _) => const SizedBox(width: 16),
                itemBuilder: (context, index) => _IdeaCard(
                  journey: picks[index],
                  onTap: () => _showPreview(context, picks[index]),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showPreview(BuildContext context, JourneyRoute journey) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChatPreviewSheet(
        journey: journey,
        onStartChat: () {
          Navigator.of(context).pop();
          onStartChat(journey);
        },
      ),
    );
  }
}

String _modeEmoji(String mode) {
  final text = mode.toLowerCase();
  if (text.contains('treno')) return '🚆';
  if (text.contains('aereo') || text.contains('volo')) return '✈️';
  if (text.contains('a piedi')) return '🚶';
  if (text.contains('bici')) return '🚲';
  if (text.contains('metro')) return '🚇';
  if (text.contains('auto') || text.contains('macchina')) return '🚗';
  if (text.contains('traghetto') || text.contains('mare')) return '⛴️';
  return '🧭';
}

String _seasonEmoji(String season) {
  final text = season.toLowerCase();
  if (text.contains('primavera')) return '🌸';
  if (text.contains('estate') || text.contains('giugno')) return '☀️';
  if (text.contains('autunno') ||
      text.contains('settembre') ||
      text.contains('novembre') ||
      text.contains('ottobre')) {
    return '🍂';
  }
  if (text.contains('inverno')) return '❄️';
  return '✨';
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.unread, required this.onOpenChats});

  final int unread;
  final VoidCallback onOpenChats;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        Text(
          'Iter',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: onOpenChats,
          tooltip: 'Chat',
          icon: unread > 0
              ? Badge.count(
                  count: unread,
                  backgroundColor: colors.primary,
                  textColor: colors.onPrimary,
                  child: const Icon(Icons.chat_bubble_outline),
                )
              : const Icon(Icons.chat_bubble_outline),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailingLabel, this.onTrailing});

  final String title;
  final String? trailingLabel;
  final VoidCallback? onTrailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailingLabel != null && onTrailing != null)
          TextButton(
            onPressed: onTrailing,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(trailingLabel!),
          ),
      ],
    );
  }
}

/// The hero: one large poster with the city, the essentials and a single
/// decision to organise the trip. The banner itself is never tappable.
class _FeaturedBanner extends StatelessWidget {
  const _FeaturedBanner({required this.journey, required this.onStartChat});

  final JourneyRoute journey;
  final VoidCallback onStartChat;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final city = journeyCity(journey);
    final poster =
        DemoMedia.postersForDestination(journey.destinationIds.first).first;
    return Container(
      height: 340,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(poster, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              color: context.iterColors.videoScrim,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: context.iterColors.videoScrim,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'Scelto per te',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.onInverseSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ClipRect(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: colors.onInverseSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${journey.stops.join(' · ')} · ${journey.durationLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: colors.onInverseSurface.withValues(alpha: 0.92),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            _GhostChip(label: journey.travelMode),
                            _GhostChip(label: journey.season),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onStartChat,
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Organizza un viaggio'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GhostChip extends StatelessWidget {
  const _GhostChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: context.iterColors.videoScrim,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colors.onInverseSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Continue-watching card for a conversation already under way.
class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.thread, required this.onTap});

  final ChatThread thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final summary = thread.summary;
    return Semantics(
      button: true,
      label: 'Riprendi: ${summary.title}',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 224,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image.asset(summary.avatar.asset, fit: BoxFit.cover),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.scrim.withValues(alpha: 0.5),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      summary.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.onInverseSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      summary.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.tertiary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The rich suggestion card: poster, city, facts, score and the AI why.
class _IdeaCard extends StatelessWidget {
  const _IdeaCard({required this.journey, required this.onTap});

  final JourneyRoute journey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final city = journeyCity(journey);
    final poster =
        DemoMedia.postersForDestination(journey.destinationIds.first).first;
    return SizedBox(
      width: 254,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 150,
                width: 254,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Image.asset(poster, fit: BoxFit.cover),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: _GhostChip(label: _modeEmoji(journey.travelMode)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    city,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'Ti somiglia ${journey.matchScore}%',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${journey.durationLabel} · ${_seasonEmoji(journey.season)} ${journey.season}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  journey.whyItFits,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
