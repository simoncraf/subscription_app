import '../../data/subscription.dart';
import '../../data/settings_store.dart';

class HomeData {
  final List<Subscription> subs;
  final AppSettings settings;

  const HomeData(this.subs, this.settings);
}
