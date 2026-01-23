import 'package:flutter/material.dart';
import '../data/settings_store.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _store = SettingsStore();

  AppSettings? _settings;
  bool _saving = false;

  // Options (keep simple for now)
  static const _languages = <String, String>{
    'en': 'English',
    'es': 'Spanish',
    'it': 'Italian',
    'pl': 'Polish',
  };

  static const _currencies = <String>['EUR', 'PLN', 'USD'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _store.get();
    if (!mounted) return;
    setState(() => _settings = s);
  }

  Future<void> _update(AppSettings next) async {
    setState(() {
      _settings = next;
      _saving = true;
    });

    await _store.set(next);

    if (!mounted) return;
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = _settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
            ),
        ],
      ),
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'General',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),

                // Language
                DropdownButtonFormField<String>(
                  value: s.language,
                  decoration: const InputDecoration(
                    labelText: 'Language',
                    border: OutlineInputBorder(),
                  ),
                  items: _languages.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    _update(s.copyWith(language: v));
                  },
                ),
                const SizedBox(height: 12),

                // Default currency
                DropdownButtonFormField<String>(
                  value: s.defaultCurrency,
                  decoration: const InputDecoration(
                    labelText: 'Default currency',
                    border: OutlineInputBorder(),
                  ),
                  items: _currencies
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    _update(s.copyWith(defaultCurrency: v));
                  },
                ),

                const SizedBox(height: 24),

                Text(
                  'Home page',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),

                // Totals mode
                DropdownButtonFormField<String>(
                  value: s.homeTotalMode,
                  decoration: const InputDecoration(
                    labelText: 'Show totals as',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly total')),
                    DropdownMenuItem(value: 'annual', child: Text('Annual total')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    _update(s.copyWith(homeTotalMode: v));
                  },
                ),

                const SizedBox(height: 24),

                Text(
                  'Subscription card fields',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Price'),
                  value: s.showPrice,
                  onChanged: (v) => _update(s.copyWith(showPrice: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Recurrence'),
                  value: s.showRecurrence,
                  onChanged: (v) => _update(s.copyWith(showRecurrence: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Renewal date'),
                  value: s.showRenewalDate,
                  onChanged: (v) => _update(s.copyWith(showRenewalDate: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Usage frequency'),
                  value: s.showUsageFrequency,
                  onChanged: (v) => _update(s.copyWith(showUsageFrequency: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Badges (renewal/trial warnings)'),
                  value: s.showBadges,
                  onChanged: (v) => _update(s.copyWith(showBadges: v)),
                ),

                const SizedBox(height: 12),

                // Optional: quick explanation
                Text(
                  'These preferences are saved on your phone. We will apply them to Home and other screens next.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
    );
  }
}