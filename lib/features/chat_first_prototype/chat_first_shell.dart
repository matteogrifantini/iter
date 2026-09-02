import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../organization/adapters/mock_travel_search_provider.dart';
import '../organization/adapters/unavailable_stay_search_provider.dart';
import '../organization/engine/session_registry.dart';
import '../organization/providers/organization_ai_gateway.dart';
import '../chat/trip_chat_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../trips/trip_details_screen.dart';
import '../trips/trip_entity.dart';
import '../trips/trips_list_screen.dart';
import 'chat_first_controller.dart';
import 'iter_ui_primitives.dart';

/// Bottom navigation with WhatsApp-style chat grammar and Iter's identity.
class ChatFirstShell extends StatefulWidget {
  const ChatFirstShell({
    super.key,
    required this.controller,
    required this.themeMode,
    required this.onThemeChanged,
    this.sessionRegistry,
  });

  final ChatFirstPrototypeController controller;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final SessionRegistry? sessionRegistry;

  @override
  State<ChatFirstShell> createState() => _ChatFirstShellState();
}

class _ChatFirstShellState extends State<ChatFirstShell> {
  var _tabIndex = 0;
  var _isScrolled = false;
  late final SessionRegistry _sessionRegistry;
  var _ownsSessionRegistry = false;

  @override
  void initState() {
    super.initState();
    if (widget.sessionRegistry != null) {
      _sessionRegistry = widget.sessionRegistry!;
    } else {
      _sessionRegistry = SessionRegistry(
        aiGateway: const _FallbackAiGateway(),
        travelProvider: MockTravelSearchProvider(),
        stayProvider: const UnavailableStaySearchProvider(),
      );
      _ownsSessionRegistry = true;
    }
    widget.controller.addListener(_maybeShowPurchaseReturnPrompt);
    // Cold start: a persisted `purchaseOpened` never triggers a prompt, the
    // launch flag is session state; this initial check is a no-op by design.
    _maybeShowPurchaseReturnPrompt();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_maybeShowPurchaseReturnPrompt);
    if (_ownsSessionRegistry) {
      _sessionRegistry.disposeAll();
    }
    super.dispose();
  }

  /// Consumes the first pending purchase-return prompt and shows its dialog
  /// exactly once. Consuming before showing keeps a second resume silent.
  void _maybeShowPurchaseReturnPrompt() {
    final pending = widget.controller.pendingPurchasePrompts;
    if (pending.isEmpty) return;
    final prompt = pending.first;
    widget.controller.consumePurchasePrompt(prompt.conversationId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showPurchaseReturnDialog(prompt);
    });
  }

  Future<void> _showPurchaseReturnDialog(PurchaseReturnPrompt prompt) async {
    final controller = widget.controller;
    final snapshot = controller.conversationOf(prompt.conversationId).snapshot;
    // Only the provider voice: no prices, codes or personal data in the dialog.
    final label = switch (prompt.kind) {
      ExternalPurchaseKind.travel => snapshot?.travelSelection?.option.label,
      ExternalPurchaseKind.stay => snapshot?.staySelection?.option.label,
    }?.split(' · ').first;
    final confirmed = await showDialog<bool>(
      context: context,
      // The traveler is already back in the app: they must settle the
      // purchase explicitly. Tapping outside or system Back never leaves a
      // dangling `purchaseOpened`.
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sei tornato dal sito di prenotazione.'),
        content: Text(
          label == null
              ? 'Hai completato l’acquisto? Aggiorna il piano o lascia tutto com’è.'
              : 'Hai completato l’acquisto di “$label”?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Non ancora'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sì, aggiorna'),
          ),
        ],
      ),
    );
    if (confirmed == null || !mounted) return;
    if (confirmed) {
      controller.confirmExternalPurchase(
        conversationId: prompt.conversationId,
        kind: prompt.kind,
        optionId: prompt.optionId,
      );
    } else {
      controller.dismissExternalPurchasePrompt(
        conversationId: prompt.conversationId,
        kind: prompt.kind,
        optionId: prompt.optionId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return Scaffold(

          body: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.depth != 0) return false;
              final scrolled = notification.metrics.pixels > 80;
              if (scrolled != _isScrolled) {
                setState(() => _isScrolled = scrolled);
              }
              return false;
            },
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
              Positioned.fill(
                child: IterPageFrame(
                  padding: EdgeInsets.zero,
                  expandHeight: true,
                  child: IndexedStack(
                    index: _tabIndex,
                    children: <Widget>[
                      HomeScreen(
                        onOpenNewTripChat: ({destination}) =>
                            _openTripChat(context, destination: destination),
                        onOpenTripDetails: (trip) =>
                            _openSnapshotFromTrip(context, trip),
                        onOpenProfile: () => setState(() => _tabIndex = 2),
                      ),
                      TripsListScreen(
                        onOpenTripChat: (trip) => _openTripChat(
                          context,
                          tripId: trip.id,
                          destination: trip.destination,
                        ),
                        onOpenTripSnapshot: (trip) =>
                            _openSnapshotFromTrip(context, trip),
                        onStartNewTrip: () => _openTripChat(context),
                      ),
                      const ProfileScreen(),
                    ],
                  ),

                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _ChatBottomNavigation(
                  currentIndex: _tabIndex,
                  unread: widget.controller.unread,
                  isScrolled: _isScrolled,
                  onChanged: (index) => setState(() => _tabIndex = index),
                ),
              ),
            ],
          ),
          ),
        );
      },
    );
  }

  void _openTripChat(
    BuildContext context, {
    String? destination,
    String? tripId,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TripChatScreen(
          initialPrompt: destination != null
              ? 'Vorrei organizzare un viaggio a $destination'
              : null,
          initialTripId: tripId,
          onOpenSnapshot: (trip) => _openSnapshotFromTrip(context, trip),
        ),
      ),
    );
  }

  void _openSnapshotFromTrip(BuildContext context, TripEntity trip) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TripDetailsScreen(trip: trip),
      ),
    );
  }
}

class _ChatBottomNavigation extends StatelessWidget {
  const _ChatBottomNavigation({
    required this.currentIndex,
    required this.unread,
    required this.onChanged,
    this.isScrolled = false,
  });

  final int currentIndex;
  final int unread;
  final ValueChanged<int> onChanged;
  final bool isScrolled;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = math
              .min(360.0, math.max(0.0, constraints.maxWidth - 32))
              .toDouble();
          return Center(
            child: SizedBox(
              width: width,
              child: Semantics(
                label: 'Navigazione principale',
                container: true,
                explicitChildNodes: true,
                // Task 3: IterMaterialSurface diretto (non IterGlassBar) per
                // preservare key/padding6/radius32 esistenti; translucent:true
                // consuma già blur/tint/fallback highContrast di Task 2 via IterGlassRoles.
                child: IterMaterialSurface(
                  key: const Key('shell-floating-dock'),
                  padding: const EdgeInsets.all(6),
                  borderRadius: BorderRadius.circular(32),
                  translucent: true,
                  child: AnimatedContainer(
                    duration: reducedMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    height: isScrolled ? 44.0 : 52.0,
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: _FloatingDestination(
                            tooltip: 'Oggi',
                            semantics: 'Oggi',
                            selected: currentIndex == 0,
                            icon: const Icon(Icons.home_outlined),
                            selectedIcon: const Icon(Icons.home),
                            onTap: () => onChanged(0),
                            compact: isScrolled,
                          ),
                        ),
                        Expanded(
                          child: _FloatingDestination(
                            tooltip: 'Viaggi',
                            semantics: unread > 0
                                ? 'Viaggi, $unread messaggi non letti'
                                : 'Viaggi',
                            selected: currentIndex == 1,
                            icon: _UnreadIcon(
                              unread: unread,
                              icon: Icons.chat_bubble_outline,
                            ),
                            selectedIcon: _UnreadIcon(
                              unread: unread,
                              icon: Icons.chat_bubble,
                            ),
                            onTap: () => onChanged(1),
                            compact: isScrolled,
                          ),
                        ),
                        Expanded(
                          child: _FloatingDestination(
                            tooltip: 'Tu',
                            semantics: 'Tu',
                            selected: currentIndex == 2,
                            icon: const Icon(Icons.person_outline),
                            selectedIcon: const Icon(Icons.person),
                            onTap: () => onChanged(2),
                            compact: isScrolled,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FloatingDestination extends StatelessWidget {
  const _FloatingDestination({
    required this.tooltip,
    required this.semantics,
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.onTap,
    this.compact = false,
  });

  final String tooltip;
  final String semantics;
  final bool selected;
  final Widget icon;
  final Widget selectedIcon;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    // Label collassabile: con reduced motion il cambio è istantaneo senza
    // AnimatedSize (Duration.zero si auto-muterebbe in layout).
    final Widget label = compact
        ? const SizedBox.shrink()
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 2),
              Text(
                tooltip,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          );
    return Semantics(
      label: semantics,
      selected: selected,
      button: true,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (selected)
                AnimatedContainer(
                  duration: reducedMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: selectedIcon,
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: icon,
                ),
              // Sincronizzata con lo shrink del dock (180ms ease-out): la
              // label collassa insieme all'altezza così nessun frame intermedio
              // va in overflow. Semantics, icone e badge restano invariati.
              if (reducedMotion)
                label
              else
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  child: label,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnreadIcon extends StatelessWidget {
  const _UnreadIcon({required this.unread, required this.icon});

  final int unread;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget child = Icon(icon);
    if (unread > 0) {
      child = Badge.count(
        count: unread,
        backgroundColor: colors.primary,
        textColor: colors.onPrimary,
        child: child,
      );
    }
    return Semantics(
      label: unread > 0 ? 'Viaggi, $unread messaggi non letti' : 'Viaggi',
      child: child,
    );
  }
}

class _FallbackAiGateway implements OrganizationAiGateway {
  const _FallbackAiGateway();

  @override
  Future<AiOrganizationResponse> decideNextStep(
    OrganizationAiContext context,
  ) async {
    return AiOrganizationResponse(
      explanation: 'Organizzazione assistita attiva.',
    );
  }
}
