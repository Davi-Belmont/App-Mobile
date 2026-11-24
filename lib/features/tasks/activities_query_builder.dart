import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_planner/data/api_client.dart';
import 'package:study_planner/data/models/activity.dart';
import 'package:study_planner/data/models/activity_query.dart';
import 'package:study_planner/features/tasks/activities_provider.dart';

class ActivitiesResult {
  const ActivitiesResult({
    required this.items,
    required this.loading,
    required this.error,
    required this.reload,
  });

  final List<Activity> items;
  final bool loading;
  final String? error;
  final Future<void> Function() reload;
}

/// Busca GET /activities com filtros no servidor e se atualiza sozinho
/// quando o [ActivitiesProvider] muda (criar, editar, concluir, excluir).
class ActivitiesQueryBuilder extends StatefulWidget {
  const ActivitiesQueryBuilder({super.key, required this.query, required this.builder});

  final ActivityQuery query;
  final Widget Function(BuildContext context, ActivitiesResult result) builder;

  @override
  State<ActivitiesQueryBuilder> createState() => _ActivitiesQueryBuilderState();
}

class _ActivitiesQueryBuilderState extends State<ActivitiesQueryBuilder> {
  List<Activity> _items = const [];
  bool _loading = true;
  String? _error;
  int _seq = 0; // evita que uma resposta antiga sobrescreva uma mais nova
  late int _revision;

  @override
  void initState() {
    super.initState();
    _revision = context.read<ActivitiesProvider>().revision;
    _load(showLoading: false);
  }

  @override
  void didUpdateWidget(covariant ActivitiesQueryBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) _load(showLoading: true);
  }

  Future<void> _load({required bool showLoading}) async {
    final seq = ++_seq;
    if (showLoading) {
      setState(() {
        _items = const [];
        _loading = true;
        _error = null;
      });
    }
    try {
      final list = await context.read<ActivitiesProvider>().fetch(widget.query);
      if (!mounted || seq != _seq) return;
      setState(() {
        _items = list;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _loading = false;
        if (_items.isEmpty) _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivitiesProvider>();
    if (provider.revision != _revision) {
      _revision = provider.revision;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load(showLoading: false);
      });
    }
    return widget.builder(
      context,
      ActivitiesResult(
        items: provider.overlay(_items),
        loading: _loading,
        error: _error,
        reload: () => _load(showLoading: false),
      ),
    );
  }
}