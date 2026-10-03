// S08 trip screen and S09 end states. Text status only: no map and no
// animations on this screen. The elapsed ticker runs only while visible.
// See PLAN.md S08 and S09.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pontual/domain/trip/trip_state.dart';
import 'package:pontual/features/trip/trip_controller.dart';

/// Active trip screen.
class TripScreen extends StatefulWidget {
  /// Creates a trip screen driven by [controller].
  const TripScreen({required this.controller, super.key});

  /// Trip controller owning the trip.
  final TripController controller;

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final TripController c = widget.controller;
    if (c.endKind != null && c.state is TripIdle) {
      return EndCard(kind: c.endKind!, detail: c.endDetail);
    }
    final String elapsed = _elapsed(c);
    return Scaffold(
      appBar: AppBar(title: const Text('Compartilhando viagem')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
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
          const Text('Conexão     ✓ Conectado'),
          Text('Seu celular  ${_roleText(c)}'),
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
        return 'Encerramos por tempo máximo ou falta de sinal.';
      case TripEndKind.permission:
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
