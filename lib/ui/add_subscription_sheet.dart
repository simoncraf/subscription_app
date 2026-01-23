import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../data/subscription.dart';
import '../data/subscription_store.dart';

class AddSubscriptionSheet extends StatefulWidget {
  final Subscription? initial;

  const AddSubscriptionSheet({super.key, this.initial});

  @override
  State<AddSubscriptionSheet> createState() => _AddSubscriptionSheetState();
}

class _AddSubscriptionSheetState extends State<AddSubscriptionSheet> {
  final _store = SubscriptionStore();
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _cardCtrl = TextEditingController(text: 'Default card');

  String _currency = 'EUR';
  String _recurrence = 'monthly'; // ✅ NEW: monthly (default) or annual

  DateTime _renewalDate = DateTime.now().add(const Duration(days: 30));

  bool _hasTrial = false;
  DateTime? _trialEnds;

  int _usagePerWeek = 1;

  bool _remindersEnabled = false;
  int _reminderDaysBefore = 1;

  final _df = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();

    final s = widget.initial;
    if (s != null) {
      _nameCtrl.text = s.name;
      _priceCtrl.text = s.price.toString();
      _cardCtrl.text = s.paymentCardLabel;

      _currency = s.currency;
      _renewalDate = s.renewalDate;

      _hasTrial = s.hasFreeTrial;
      _trialEnds = s.freeTrialEnds;

      _usagePerWeek = s.usagePerWeek;

      _remindersEnabled = s.remindersEnabled;
      _reminderDaysBefore = s.reminderDaysBefore == 0 ? 1 : s.reminderDaysBefore;

      // ✅ NEW: load recurrence (null => monthly for old data)
      _recurrence = s.recurrence ?? 'monthly';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _cardCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_hasTrial && _trialEnds == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set trial end date.')),
      );
      return;
    }

    final price = double.parse(_priceCtrl.text.replaceAll(',', '.'));
    final existing = widget.initial;

    final sub = Subscription(
      id: existing?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      price: price,
      currency: _currency,
      renewalDate: _renewalDate,
      hasFreeTrial: _hasTrial,
      freeTrialEnds: _hasTrial ? _trialEnds : null,
      paymentCardLabel: _cardCtrl.text.trim(),
      usagePerWeek: _usagePerWeek,
      remindersEnabled: _remindersEnabled,
      reminderDaysBefore: _remindersEnabled ? _reminderDaysBefore : 0,
      isCanceled: existing?.isCanceled ?? false,
      canceledAt: existing?.canceledAt,

      // ✅ NEW
      recurrence: _recurrence,
    );

    await _store.upsert(sub);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.initial == null ? 'Add subscription' : 'Edit subscription',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context, false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Price',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Required';
                                final parsed = double.tryParse(v.replaceAll(',', '.'));
                                if (parsed == null || parsed < 0) return 'Invalid price';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 110,
                            child: DropdownButtonFormField<String>(
                              value: _currency,
                              items: const [
                                DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                                DropdownMenuItem(value: 'PLN', child: Text('PLN')),
                                DropdownMenuItem(value: 'USD', child: Text('USD')),
                              ],
                              onChanged: (v) => setState(() => _currency = v ?? 'EUR'),
                              decoration: const InputDecoration(
                                labelText: 'Currency',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ✅ NEW: Recurrence selector
                      DropdownButtonFormField<String>(
                        value: _recurrence,
                        decoration: const InputDecoration(
                          labelText: 'Recurrence',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                          DropdownMenuItem(value: 'annual', child: Text('Annual')),
                        ],
                        onChanged: (v) => setState(() => _recurrence = v ?? 'monthly'),
                      ),

                      const SizedBox(height: 12),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Renewal date'),
                        subtitle: Text(_df.format(_renewalDate)),
                        trailing: const Icon(Icons.calendar_month),
                        onTap: () => _pickDate(
                          initial: _renewalDate,
                          onPicked: (d) => setState(() => _renewalDate = d),
                        ),
                      ),

                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Free trial'),
                        value: _hasTrial,
                        onChanged: (v) {
                          setState(() {
                            _hasTrial = v;
                            if (!v) _trialEnds = null;
                          });
                        },
                      ),

                      if (_hasTrial)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Trial ends'),
                          subtitle: Text(
                            _trialEnds == null ? 'Not set' : _df.format(_trialEnds!),
                          ),
                          trailing: const Icon(Icons.calendar_month),
                          onTap: () => _pickDate(
                            initial: _trialEnds ?? DateTime.now(),
                            onPicked: (d) => setState(() => _trialEnds = d),
                          ),
                        ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _cardCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Payment card label',
                          hintText: 'e.g. Revolut, Visa **** 1234',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),

                      const SizedBox(height: 16),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Usage per week: $_usagePerWeek',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Slider(
                        value: _usagePerWeek.toDouble(),
                        min: 0,
                        max: 21,
                        divisions: 21,
                        label: '$_usagePerWeek',
                        onChanged: (v) => setState(() => _usagePerWeek = v.toInt()),
                      ),

                      const SizedBox(height: 12),

                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Reminders'),
                        subtitle: const Text('Save preference (notifications later)'),
                        value: _remindersEnabled,
                        onChanged: (v) => setState(() => _remindersEnabled = v),
                      ),

                      if (_remindersEnabled)
                        DropdownButtonFormField<int>(
                          value: _reminderDaysBefore,
                          decoration: const InputDecoration(
                            labelText: 'Remind me before (days)',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('1 day')),
                            DropdownMenuItem(value: 3, child: Text('3 days')),
                            DropdownMenuItem(value: 7, child: Text('7 days')),
                            DropdownMenuItem(value: 14, child: Text('14 days')),
                          ],
                          onChanged: (v) => setState(() => _reminderDaysBefore = v ?? 1),
                        ),

                      const SizedBox(height: 20),

                      FilledButton(
                        onPressed: _save,
                        child: Text(widget.initial == null ? 'Save' : 'Update'),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}