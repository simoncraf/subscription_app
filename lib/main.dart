import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/subscription.dart';
import 'ui/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(SubscriptionAdapter());

  runApp(const SubscriptionsApp());
}

class SubscriptionsApp extends StatelessWidget {
  const SubscriptionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Subscriptions',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}