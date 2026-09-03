import 'package:flutter/material.dart';

import 'profile_availability_sheet.dart';
import 'profile_models.dart';

class ChatFirstProfileScreen extends StatelessWidget {
  const ChatFirstProfileScreen({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
    required this.onOpenChats,
    this.memoryTags = const <String>[],
    this.availability = const <AvailabilityEntry>[],
    this.stats = const TravelStats(
      completedTrips: 3,
      visitedPlaces: 18,
      estimatedKilometers: 1240,
    ),
    this.onAddAvailability,
    this.onRemoveAvailability,
    this.currentUserEmail,
    this.onSignInWithEmail,
    this.onSignOut,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final VoidCallback onOpenChats;
  final List<String> memoryTags;
  final List<AvailabilityEntry> availability;
  final TravelStats stats;
  final ValueChanged<AvailabilityEntry>? onAddAvailability;
  final ValueChanged<String>? onRemoveAvailability;
  final String? currentUserEmail;
  final Future<bool> Function(String email)? onSignInWithEmail;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 128),
        children: <Widget>[
          const _ProfileHeader(),
          const SizedBox(height: 24),
          _StatsRow(stats: stats),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 26),
          Text(
            'Il tuo modo di partire',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Qualche traccia utile per proporti viaggi che ti somigliano. ✨',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          if (memoryTags.isEmpty)
            Text(
              'Ancora nessuna preferenza: la costruiamo insieme in chat.',
              style: Theme.of(context).textTheme.bodyLarge,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final item in memoryTags.take(4))
                  Chip(
                    label: Text(item),
                    avatar: const Icon(Icons.favorite_border, size: 17),
                    side: BorderSide(color: colors.outlineVariant),
                    backgroundColor: colors.surface,
                  ),
              ],
            ),
          const SizedBox(height: 28),
          _SectionHeading(
            title: 'Aspetto',
            icon: Icons.palette_outlined,
            subtitle: 'Scegli come vuoi vedere Iter.',
          ),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            segments: const <ButtonSegment<ThemeMode>>[
              ButtonSegment<ThemeMode>(
                value: ThemeMode.light,
                label: Text('Chiaro'),
                icon: Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.dark,
                label: Text('Scuro'),
                icon: Icon(Icons.dark_mode_outlined),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.system,
                label: Text('Sistema'),
                icon: Icon(Icons.brightness_auto_outlined),
              ),
            ],
            selected: <ThemeMode>{themeMode},
            onSelectionChanged: (selection) => onThemeChanged(selection.first),
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(minimumSize: const Size(0, 48)),
          ),
          const SizedBox(height: 28),
          _SectionHeading(
            title: 'Disponibilità',
            icon: Icons.calendar_month_outlined,
            subtitle: 'Segna quando potresti partire o quando lavori. 🗓️',
          ),
          const SizedBox(height: 10),
          if (availability.isEmpty)
            Text(
              'Nessun giorno segnato. Bastano pochi tocchi per dare a Iter un '
              'po’ di contesto.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
            )
          else
            for (final entry in availability)
              _AvailabilityTile(
                entry: entry,
                onRemove: onRemoveAvailability == null
                    ? null
                    : () => onRemoveAvailability!(entry.id),
              ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _openAvailabilitySheet(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 48),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Aggiungi disponibilità'),
          ),
          const SizedBox(height: 28),
          const _SectionHeading(
            title: 'Memoria appresa',
            icon: Icons.auto_awesome_outlined,
            subtitle:
                'Iter usa queste tracce per rendere i suggerimenti più tuoi.',
          ),
          const SizedBox(height: 10),
          Text(
            'Puoi cambiare idea in qualsiasi momento: il profilo non è un '
            'questionario da completare.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          _LinkTile(
            icon: Icons.help_outline,
            title: 'Domande frequenti',
            subtitle: 'Come funziona Iter e cosa resta nella demo',
            onTap: () => _showInfo(
              context,
              title: 'Domande frequenti',
              body:
                  'Iter parte dalle tue parole, costruisce una proposta e ti '
                  'lascia decidere ogni modifica. In questa versione tutto è '
                  'mock e resta sul dispositivo.',
            ),
          ),
          _LinkTile(
            icon: Icons.lock_outline,
            title: 'Privacy',
            subtitle: 'Conversazioni e piani restano nella demo locale',
            onTap: () => _showInfo(
              context,
              title: 'Privacy',
              body:
                  'Per ora Iter è una demo: non vengono inviati dati personali '
                  'a provider di viaggio o a servizi di pagamento.',
            ),
          ),
          _LinkTile(
            icon: Icons.chat_bubble_outline,
            title: 'Le tue conversazioni',
            subtitle: 'Riapri un piano o inizia un viaggio nuovo',
            onTap: onOpenChats,
          ),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 18),
          _LinkTile(
            icon: currentUserEmail == null
                ? Icons.account_circle_outlined
                : Icons.verified_user_outlined,
            title: currentUserEmail ?? 'Accedi o crea un account',
            subtitle: currentUserEmail == null
                ? 'Sincronizza i tuoi viaggi e piani su tutti i dispositivi'
                : 'Account collegato · Tocca per gestire la sessione',
            onTap: () => _openAccountSheet(context),
          ),
        ],
      ),
    );
  }

  Future<void> _openAccountSheet(BuildContext context) async {
    final email = currentUserEmail;
    final emailController = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          28 + MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              email == null ? 'Accedi a Iter' : 'Il tuo account',
              style: Theme.of(
                sheetContext,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            if (email != null) ...[
              Text(
                'Sei autenticato con $email. I tuoi piani e messaggi sono sincronizzati sul cloud.',
                style: Theme.of(sheetContext).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Annulla'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: () {
                      onSignOut?.call();
                      Navigator.of(sheetContext).pop();
                    },
                    child: const Text('Esci dall\'account'),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'Inserisci la tua email per ricevere un link magico di accesso immediato, senza password.',
                style: Theme.of(sheetContext).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'es. nome@esempio.it',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Chiudi'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      final input = emailController.text.trim();
                      if (input.isNotEmpty && onSignInWithEmail != null) {
                        final ok = await onSignInWithEmail!(input);
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Link inviato a $input! Controlla la tua posta.'
                                    : 'Impossibile inviare il link. Riprova più tardi.',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Invia Magic Link'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openAvailabilitySheet(BuildContext context) async {
    final entry = await showModalBottomSheet<AvailabilityEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const ProfileAvailabilitySheet(),
    );
    if (entry != null) onAddAvailability?.call(entry);
  }

  Future<void> _showInfo(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(
                sheetContext,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(body, style: Theme.of(sheetContext).textTheme.bodyLarge),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('Chiudi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      key: const Key('profile-header'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Tu', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 4),
        Text('🌿  🎒  ✨', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          'Un profilo leggero, costruito viaggiando.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final TravelStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final values = <({String value, String label})>[
      (value: '${stats.completedTrips}', label: 'viaggi'),
      (value: '${stats.visitedPlaces}', label: 'luoghi'),
      (value: '${stats.estimatedKilometers}', label: 'km stimati'),
    ];
    return Semantics(
      key: const Key('profile-stats'),
      container: true,
      label: 'Statistiche di viaggio',
      child: Row(
        children: <Widget>[
          for (var index = 0; index < values.length; index++) ...<Widget>[
            if (index > 0)
              Container(width: 1, height: 34, color: colors.outlineVariant),
            Expanded(
              child: Column(
                children: <Widget>[
                  Text(
                    values[index].value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    values[index].label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.icon,
    required this.subtitle,
  });

  final String title;
  final IconData icon;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, color: colors.primary, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvailabilityTile extends StatelessWidget {
  const _AvailabilityTile({required this.entry, required this.onRemove});

  final AvailabilityEntry entry;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final kindLabel = entry.kind == AvailabilityKind.free ? 'Libero' : 'Turno';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        entry.kind == AvailabilityKind.free
            ? Icons.wb_sunny_outlined
            : Icons.work_outline,
        color: colors.primary,
      ),
      title: Text(_formatDate(entry.date)),
      subtitle: Text(
        '$kindLabel · ${entry.timeRange}${entry.note.isEmpty ? '' : ' · ${entry.note}'}',
      ),
      trailing: onRemove == null
          ? null
          : IconButton(
              onPressed: onRemove,
              tooltip: 'Rimuovi disponibilità',
              style: IconButton.styleFrom(
                minimumSize: const Size(48, 48),
              ),
              icon: const Icon(Icons.close),
            ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

String _formatDate(DateTime date) {
  const months = <String>[
    'gennaio',
    'febbraio',
    'marzo',
    'aprile',
    'maggio',
    'giugno',
    'luglio',
    'agosto',
    'settembre',
    'ottobre',
    'novembre',
    'dicembre',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
