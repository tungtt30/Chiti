import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';

class AddTripScreen extends ConsumerStatefulWidget {
  final Trip? existing;
  const AddTripScreen({super.key, this.existing});

  @override
  ConsumerState<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends ConsumerState<AddTripScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _destCtrl;
  late String _currency;
  late DateTime _startDate;
  late DateTime _endDate;

  Trip? get _existing => widget.existing;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: _existing?.name ?? '');
    _destCtrl = TextEditingController(text: _existing?.destination ?? '');
    _currency = _existing?.currency ?? 'USD';
    _startDate = _existing?.startDate ?? DateTime.now();
    _endDate = _existing?.endDate ?? _startDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _destCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_existing != null) {
      await ref
          .read(tripDetailProvider(_existing!.id).notifier)
          .updateTrip(
            _existing!.copyWith(
              name: _nameCtrl.text.trim(),
              destination: _destCtrl.text.trim(),
              currency: _currency,
              startDate: _startDate,
              endDate: _endDate,
            ),
          );
    } else {
      await ref
          .read(tripListProvider.notifier)
          .createTrip(
            name: _nameCtrl.text.trim(),
            destination: _destCtrl.text.trim(),
            currency: _currency,
            startDate: _startDate,
            endDate: _endDate,
          );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? 'Create Trip' : 'Edit Trip'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Trip Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flight),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _destCtrl,
              decoration: const InputDecoration(
                labelText: 'Destination',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.place),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _currency,
              decoration: const InputDecoration(
                labelText: 'Currency',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on),
              ),
              items: kSupportedCurrencies
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _currency = v);
              },
            ),
            const SizedBox(height: 16),
            _DateTile(
              icon: Icons.calendar_month,
              label: 'Start Date',
              value: formatDateCompact(_startDate),
              onTap: _pickStartDate,
            ),
            const SizedBox(height: 8),
            _DateTile(
              icon: Icons.calendar_month_outlined,
              label: 'End Date',
              value: formatDateCompact(_endDate),
              onTap: _pickEndDate,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(_existing == null ? 'Create Trip' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
      trailing: const Icon(Icons.edit_calendar),
      onTap: onTap,
    );
  }
}
