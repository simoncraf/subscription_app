import '../../data/settings_store.dart';
import '../../data/subscription.dart';

class StatsData {
  final List<Subscription> subs;
  final AppSettings settings;
  const StatsData(this.subs, this.settings);
}
