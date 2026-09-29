import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'blocs/playback/playback_bloc.dart';
import 'blocs/track_list/track_list_bloc.dart';
import 'blocs/track_list/track_list_event.dart';
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
    return MultiBlocProvider(
      providers: [
        // Events are processed asynchronously, so adding the first load here
        // is safe - no addPostFrameCallback workaround needed like in Provider.
        BlocProvider(
          create: (_) =>
              TrackListBloc()..add(const TrackListLoadInitialRequested()),
        ),
        BlocProvider(create: (_) => PlaybackBloc()),
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
