import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/incident_db.dart';
import '../models/incident.dart';
import '../validators.dart';

/// Create or edit an incident. Nothing is saved unless every field passes
/// the rules in [Validators].
class IncidentFormScreen extends StatefulWidget {
  const IncidentFormScreen({super.key, required this.db, this.existing});

  final IncidentDb db;
  final Incident? existing;

  @override
  State<IncidentFormScreen> createState() => _IncidentFormScreenState();
}

class _IncidentFormScreenState extends State<IncidentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late String _severity;
  late String _status;
  late DateTime _date;
  String? _dateError;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _severity = e?.severity ?? 'Medium';
    _status = e?.status ?? 'Open';
    _date = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100), // the validator, not the picker, enforces "not in the future"
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    setState(() => _dateError = Validators.date(_date));
    final fieldsOk = _formKey.currentState!.validate();
    if (!fieldsOk || _dateError != null) return;

    setState(() => _saving = true);
    final incident = Incident(
      id: widget.existing?.id,
      title: _title.text.trim(),
      description: _description.text.trim(),
      severity: _severity,
      date: _date,
      status: _status,
    );
    if (_isEdit) {
      await widget.db.update(incident);
    } else {
      await widget.db.insert(incident);
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit incident' : 'New incident')),
      body: Center(
        child: ConstrainedBox(
          // Keeps the form readable on wide tablet screens.
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              TextFormField(
                controller: _title,
                maxLength: Validators.titleMax,
                decoration: const InputDecoration(
                    labelText: 'Title *', border: OutlineInputBorder()),
                validator: Validators.title,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                maxLength: Validators.descriptionMax,
                maxLines: 5,
                decoration: const InputDecoration(
                    labelText: 'Description', border: OutlineInputBorder()),
                validator: Validators.description,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _severity,
                decoration: const InputDecoration(
                    labelText: 'Severity *', border: OutlineInputBorder()),
                items: Incident.severities
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _severity = v!),
                validator: Validators.severity,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                    labelText: 'Status *', border: OutlineInputBorder()),
                items: Incident.statuses
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _status = v!),
                validator: Validators.status,
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date of incident *',
                  border: const OutlineInputBorder(),
                  errorText: _dateError,
                ),
                child: Row(children: [
                  Expanded(child: Text(DateFormat.yMMMMd().format(_date))),
                  TextButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Change'),
                  ),
                ]),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_isEdit ? 'Save changes' : 'Save incident'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
