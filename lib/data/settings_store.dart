import 'package:hive_flutter/hive_flutter.dart';

class AppSettings {
  final String language; // e.g. 'en'
  final String defaultCurrency; // e.g. 'EUR'
  final String homeTotalMode; // 'monthly' | 'annual'
  final String monthlyTotalView; // 'next' | 'current'
  final bool showPrice;
  final bool showRecurrence;
  final bool showRenewalDate;
  final bool showUsageFrequency;
  final bool showBadges;

  const AppSettings({
    required this.language,
    required this.defaultCurrency,
    required this.homeTotalMode,
    required this.monthlyTotalView,
    required this.showPrice,
    required this.showRecurrence,
    required this.showRenewalDate,
    required this.showUsageFrequency,
    required this.showBadges,
  });

  factory AppSettings.defaults() => const AppSettings(
        language: 'en',
        defaultCurrency: 'EUR',
        homeTotalMode: 'monthly',
        monthlyTotalView: 'next',
        showPrice: true,
        showRecurrence: true,
        showRenewalDate: true,
        showUsageFrequency: true,
        showBadges: true,
      );

  AppSettings copyWith({
    String? language,
    String? defaultCurrency,
    String? homeTotalMode,
    String? monthlyTotalView,
    bool? showPrice,
    bool? showRecurrence,
    bool? showRenewalDate,
    bool? showUsageFrequency,
    bool? showBadges,
  }) {
    return AppSettings(
      language: language ?? this.language,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      homeTotalMode: homeTotalMode ?? this.homeTotalMode,
      monthlyTotalView: monthlyTotalView ?? this.monthlyTotalView,
      showPrice: showPrice ?? this.showPrice,
      showRecurrence: showRecurrence ?? this.showRecurrence,
      showRenewalDate: showRenewalDate ?? this.showRenewalDate,
      showUsageFrequency: showUsageFrequency ?? this.showUsageFrequency,
      showBadges: showBadges ?? this.showBadges,
    );
  }
}

class SettingsStore {
  static const _boxName = 'app_settings';

  // keys
  static const _kLanguage = 'language';
  static const _kDefaultCurrency = 'defaultCurrency';
  static const _kHomeTotalMode = 'homeTotalMode';
  static const _kMonthlyTotalView = 'monthlyTotalView';
  static const _kShowPrice = 'showPrice';
  static const _kShowRecurrence = 'showRecurrence';
  static const _kShowRenewalDate = 'showRenewalDate';
  static const _kShowUsageFrequency = 'showUsageFrequency';
  static const _kShowBadges = 'showBadges';

  Future<Box> _box() async => Hive.openBox(_boxName);

  Future<AppSettings> get() async {
    final box = await _box();
    final d = AppSettings.defaults();

    return AppSettings(
      language: (box.get(_kLanguage) as String?) ?? d.language,
      defaultCurrency: (box.get(_kDefaultCurrency) as String?) ?? d.defaultCurrency,
      homeTotalMode: (box.get(_kHomeTotalMode) as String?) ?? d.homeTotalMode,
      monthlyTotalView: (box.get(_kMonthlyTotalView) as String?) ?? d.monthlyTotalView,
      showPrice: (box.get(_kShowPrice) as bool?) ?? d.showPrice,
      showRecurrence: (box.get(_kShowRecurrence) as bool?) ?? d.showRecurrence,
      showRenewalDate: (box.get(_kShowRenewalDate) as bool?) ?? d.showRenewalDate,
      showUsageFrequency: (box.get(_kShowUsageFrequency) as bool?) ?? d.showUsageFrequency,
      showBadges: (box.get(_kShowBadges) as bool?) ?? d.showBadges,
    );
  }

  Future<void> set(AppSettings s) async {
    final box = await _box();
    await box.put(_kLanguage, s.language);
    await box.put(_kDefaultCurrency, s.defaultCurrency);
    await box.put(_kHomeTotalMode, s.homeTotalMode);
    await box.put(_kMonthlyTotalView, s.monthlyTotalView);
    await box.put(_kShowPrice, s.showPrice);
    await box.put(_kShowRecurrence, s.showRecurrence);
    await box.put(_kShowRenewalDate, s.showRenewalDate);
    await box.put(_kShowUsageFrequency, s.showUsageFrequency);
    await box.put(_kShowBadges, s.showBadges);
  }
}