import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'providers/player_provider.dart';
import 'providers/track_list_provider.dart';
import 'repositories/track_repository.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Hive.initFlutter();
  await Hive.openBox(TrackRepository.cacheBoxName);
  runApp(const ChoiraApp());
}

class ChoiraApp extends StatelessWidget {
  const ChoiraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TrackListProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
      ],
      child: MaterialApp(
        title: 'Choira Music',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
