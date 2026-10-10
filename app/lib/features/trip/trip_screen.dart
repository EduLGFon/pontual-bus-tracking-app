// S08 trip screen and S09 end states. Text status only: no map and no
// animations on this screen. The elapsed ticker runs only while visible.
// See PLAN.md S08 and S09.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pontual/app/strings_pt.dart';
import 'package:pontual/domain/trip/trip_state.dart';
import 'package:pontual/features/trip/trip_controller.dart';
import 'package:pontual/platform/web/visibility.dart';
import 'package:pontual/platform/web/wake_lock.dart';
import 'package:pontual/platform/web/web_banner.dart';

/// Active trip screen.
class TripScreen extends StatefulWidget {
  /// Creates a trip screen driven by [controller].
  const TripScreen({required this.controller, super.key});

  /// Trip controller owning the trip.
  final TripController controller;

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> with WidgetsBindingObserver {
  Timer? _ticker;
  Timer? _visibilityTimer;
  bool _promptOpen = false;
  bool _wakeUnsupported = false;
  final WebVisibilityTracker _visibility = WebVisibilityTracker();

  /// Wake lock holder; replaced in tests. (Web only.)
  @visibleForTesting
  WebWakeLock wakeLock = const ProdWebWakeLock();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    widget.controller.addListener(_maybePrompt);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
    if (kIsWeb) {
      WidgetsBinding.instance.addObserver(this);
      unawaited(_holdWakeLock());
      _visibilityTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _visibility.check(DateTime.now().millisecondsSinceEpoch);
        if (_visibility.paused && !widget.controller.isWebHidden) {
          widget.controller.setWebHidden(true);
        }
      });
    }
  }

  Future<void> _holdWakeLock() async {
    await wakeLock.enable();
    final bool held = await wakeLock.enabled;
    if (mounted && !held) {
      setState(() {
        _wakeUnsupported = true;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!kIsWeb) {
      return;
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _visibility.onHidden(DateTime.now().millisecondsSinceEpoch);
    } else if (state == AppLifecycleState.resumed) {
      _visibility.onVisible();
      widget.controller.setWebHidden(false);
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      WidgetsBinding.instance.removeObserver(this);
      _visibilityTimer?.cancel();
      unawaited(wakeLock.disable());
    }
    _ticker?.cancel();
    widget.controller.removeListener(_refresh);
    widget.controller.removeListener(_maybePrompt);
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  void _maybePrompt() {
    if (!widget.controller.walkingPromptVisible || _promptOpen) {
      return;
    }
    _promptOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_showWalking());
      } else {
        _promptOpen = false;
      }
    });
  }

  Future<void> _showWalking() async {
    final TripController c = widget.controller;
    final bool? still = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(StringsPt.walkingTitle),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(StringsPt.walkingNo),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(StringsPt.walkingYes),
            ),
          ],
        );
      },
    );
    _promptOpen = false;
    if (!mounted) {
      return;
    }
    if (still == true) {
      c.confirmStillRiding();
    } else {
      await c.confirmLeftBus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final TripController c = widget.controller;
    if (c.endKind != null && c.state is TripIdle) {
      return EndCard(kind: c.endKind!, detail: c.endDetail);
    }
    final String elapsed = _elapsed(c);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) async {
        // System back must end the server trip too; otherwise it
        // lingers as a ghost until the server timeout.
        if (didPop || c.state is! TripActive) {
          return;
        }
        await c.endTrip();
        if (context.mounted) {
          context.pop();
        }
      },
      child: _scaffold(c, elapsed),
    );
  }

  /// Trip status body. Split out so the back-button guard above does
  /// not reindent the whole screen.
  Widget _scaffold(TripController c, String elapsed) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compartilhando viagem')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (kIsWeb)
            WebTripBanner(
              paused: c.isWebHidden,
              wakeUnsupported: _wakeUnsupported,
            ),
          if (kIsWeb) const SizedBox(height: 12),
          Semantics(
            label: 'Compartilhando',
            liveRegion: true,
            child: const Row(
              children: <Widget>[
                Icon(Icons.circle, color: Colors.green, size: 12),
                SizedBox(width: 8),
                Text('Compartilhando'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Tempo de viagem  $elapsed'),
          const SizedBox(height: 12),
          Text(c.isOffline ? StringsPt.disconnected : StringsPt.connected),
          Text(c.isPaused ? StringsPt.gpsOff : StringsPt.gpsGood),
          Text('Seu celular  ${_roleText(c)}'),
          if (c.isPaused) ...<Widget>[
            const SizedBox(height: 12),
            const Text(StringsPt.gpsOffBanner),
          ],
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
            onPressed: () async {
              await c.endTrip();
            },
            child: const Text('Desci - encerrar viagem'),
          ),
        ],
      ),
    );
  }

  String _elapsed(TripController c) {
    final int? start = c.startedAtMs;
    if (start == null) {
      return '00:00:00';
    }
    final int secs = (DateTime.now().millisecondsSinceEpoch - start) ~/ 1000;
    final int h = secs ~/ 3600;
    final int m = (secs % 3600) ~/ 60;
    final int s = secs % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(h)}:${two(m)}:${two(s)}';
  }

  String _roleText(TripController c) {
    switch (activeRole(c.state)) {
      case TripRole.leader:
        return 'Enviando com mais frequência';
      case TripRole.follower:
        return 'Modo economia';
      case TripRole.offlineSaver:
        return StringsPt.offlineSaver;
      default:
        return 'Aguardando o ônibus sair…';
    }
  }
}

/// S09 end card with the reason included for automatic ends.
class EndCard extends StatelessWidget {
  /// Creates an end card.
  const EndCard({required this.kind, this.detail, super.key});

  /// How the trip ended.
  final TripEndKind kind;

  /// Optional server detail.
  final String? detail;

  /// End message in pt-BR.
  String message() {
    switch (kind) {
      case TripEndKind.user:
        return 'Viagem encerrada. Obrigado por ajudar!';
      case TripEndKind.automatic:
        if (detail == 'idle') {
          return 'Encerramos porque o celular ficou parado por 10 minutos.';
        }
        if (detail == 'walking') {
          return 'Encerramos porque parecia que você já tinha descido.';
        }
        return 'Encerramos por tempo máximo ou falta de sinal.';
      case TripEndKind.permission:
        if (detail == 'gps') {
          return 'Encerramos porque a localização ficou desligada.';
        }
        return 'Encerramos porque a permissão de localização foi removida.';
      case TripEndKind.abuse:
        return 'Encerramos por envios de localização inconsistentes.';
      case TripEndKind.server:
        return 'Serviço em manutenção. Tente mais tarde.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Viagem')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                message(),
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Voltar às linhas'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// /trip route: shows the active trip and owns the controller created by
/// the share flow. Leaving the screen disposes the controller.
class TripRoute extends StatefulWidget {
  /// Creates the trip route for [controller].
  const TripRoute({required this.controller, super.key});

  /// Controller started by [shareTrip].
  final TripController controller;

  @override
  State<TripRoute> createState() => _TripRouteState();
}

class _TripRouteState extends State<TripRoute> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TripScreen(controller: widget.controller);
  }
}
