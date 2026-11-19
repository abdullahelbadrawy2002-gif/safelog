import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/incident_db.dart';
import '../models/incident.dart';
import 'incident_form_screen.dart';

/// Main screen. Phones (< 720 px wide) show a single list and open details
/// on a new page; tablets show the list and the details side by side.
class IncidentListScreen extends StatefulWidget {
  const IncidentListScreen({super.key, required this.db});

  final IncidentDb db;

  static const tabletBreakpoint = 720.0;

  @override
  State<IncidentListScreen> createState() => _IncidentListScreenState();
}

class _IncidentListScreenState extends State<IncidentListScreen> {
  final _searchCtrl = TextEditingController();
  List<Incident> _items = [];
  Incident? _selected;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final q = _searchCtrl.text.trim();
    final items = q.isEmpty ? await widget.db.all() : await widget.db.search(q);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
      if (_selected != null) {
        _selected = items.where((i) => i.id == _selected!.id).firstOrNull;
      }
    });
  }

  Future<void> _openForm([Incident? existing]) async {
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => IncidentFormScreen(db: widget.db, existing: existing),
    ));
    if (saved == true) await _reload();
  }

  Future<void> _delete(Incident incident) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete incident?'),
        content: Text('"${incident.title}" will be removed permanently.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await widget.db.delete(incident.id!);
    if (!mounted) return;
    if (_selected?.id == incident.id) _selected = null;
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isTablet = constraints.maxWidth >= IncidentListScreen.tabletBreakpoint;
      final list = _buildList(isTablet);
      return Scaffold(
        appBar: AppBar(title: const Text('SafeLog incidents')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add),
          label: const Text('New incident'),
          tooltip: 'Record a new incident',
        ),
        body: isTablet
            ? Row(children: [
                SizedBox(width: 360, child: list),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _selected == null
                      ? const Center(child: Text('Select an incident to see details'))
                      : IncidentDetails(
                          incident: _selected!,
                          onEdit: () => _openForm(_selected),
                          onDelete: () => _delete(_selected!),
                        ),
                ),
              ])
            : list,
      );
    });
  }

  Widget _buildList(bool isTablet) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          controller: _searchCtrl,
          decoration: const InputDecoration(
            labelText: 'Search by title',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _reload(),
        ),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? const Center(child: Text('No incidents recorded yet'))
                : ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final item = _items[i];
                      return ListTile(
                        selected: isTablet && item.id == _selected?.id,
                        leading: SeverityBadge(severity: item.severity),
                        title: Text(item.title),
                        subtitle: Text(
                            '${DateFormat.yMMMd().format(item.date)} · ${item.status}'),
                        onTap: () {
                          if (isTablet) {
                            setState(() => _selected = item);
                          } else {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => Scaffold(
                                appBar: AppBar(title: const Text('Incident')),
                                body: IncidentDetails(
                                  incident: item,
                                  onEdit: () async {
                                    Navigator.of(context).pop();
                                    await _openForm(item);
                                  },
                                  onDelete: () => _delete(item),
                                ),
                              ),
                            ));
                          }
                        },
                      );
                    },
                  ),
      ),
    ]);
  }
}

class IncidentDetails extends StatelessWidget {
  const IncidentDetails({
    super.key,
    required this.incident,
    required this.onEdit,
    required this.onDelete,
  });

  final Incident incident;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListView(padding: const EdgeInsets.all(24), children: [
      Text(incident.title, style: t.headlineSmall),
      const SizedBox(height: 12),
      Wrap(spacing: 8, children: [
        SeverityBadge(severity: incident.severity, showLabel: true),
        Chip(label: Text(incident.status)),
        Chip(label: Text(DateFormat.yMMMMd().format(incident.date))),
      ]),
      const SizedBox(height: 16),
      Text(incident.description.isEmpty ? 'No description.' : incident.description,
          style: t.bodyLarge),
      const SizedBox(height: 24),
      Row(children: [
        FilledButton.icon(
            onPressed: onEdit, icon: const Icon(Icons.edit), label: const Text('Edit')),
        const SizedBox(width: 12),
        OutlinedButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete')),
      ]),
    ]);
  }
}

/// Severity is shown by text and icon as well as colour, so it does not
/// rely on colour alone (accessibility).
class SeverityBadge extends StatelessWidget {
  const SeverityBadge({super.key, required this.severity, this.showLabel = false});

  final String severity;
  final bool showLabel;

  static const _colors = {
    'Low': Colors.green,
    'Medium': Colors.amber,
    'High': Colors.deepOrange,
    'Critical': Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[severity] ?? Colors.grey;
    final avatar = CircleAvatar(
      backgroundColor: color.withAlpha(51),
      child: Text(severity[0],
          style: TextStyle(color: color.shade800, fontWeight: FontWeight.bold)),
    );
    if (!showLabel) return Semantics(label: '$severity severity', child: avatar);
    return Chip(avatar: Icon(Icons.warning_amber, color: color), label: Text(severity));
  }
}
