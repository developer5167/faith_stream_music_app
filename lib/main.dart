import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'config/app_theme.dart';
import 'config/app_router.dart';
import 'services/api_client.dart';
import 'services/storage_service.dart';
import 'services/audio_player_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'repositories/auth_repository.dart';
import 'repositories/home_repository.dart';
import 'services/notification_service.dart';
import 'services/search_service.dart';
import 'services/deep_link_service.dart';

import 'repositories/stream_repository.dart';
import 'repositories/library_repository.dart';
import 'repositories/user_repository.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/home/home_bloc.dart';
import 'blocs/home/home_event.dart';
import 'blocs/player/player_bloc.dart';
import 'blocs/search/search_bloc.dart';
import 'blocs/library/library_bloc.dart';
import 'blocs/library/library_event.dart';
import 'blocs/profile/profile_bloc.dart';
import 'blocs/profile/profile_event.dart';

void main() async {
  debugPrint('🚀 App Starting...');
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // White icons for dark theme
      statusBarBrightness: Brightness.dark, // For iOS
    ),
  );

  try {
    debugPrint('🔧 Initializing dependencies...');

    // Initialize just_audio_background for lock screen controls
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.faithstream.audio',
      androidNotificationChannelName: 'FaithStream Audio',
      androidNotificationOngoing: true,
    );
    debugPrint('✅ Audio background service initialized');

    // Initialize dependencies
    const secureStorage = FlutterSecureStorage();
    final prefs = await SharedPreferences.getInstance();
    debugPrint('✅ Storage initialized');

    final storageService = StorageService(secureStorage, prefs);
    final apiClient = ApiClient(storageService);
    final authRepository = AuthRepository(apiClient);
    final homeRepository = HomeRepository(apiClient);
    final streamRepository = StreamRepository(apiClient);
    final libraryRepository = LibraryRepository(apiClient);
    final userRepository = UserRepository(apiClient);
    final audioPlayerService = AudioPlayerService();
    final searchService = SearchService(apiClient);

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final notificationService = NotificationService(apiClient);
    await notificationService.init();
    debugPrint('✅ Firebase & Notifications initialized');

    debugPrint('✅ All dependencies initialized');

    runApp(
      MyApp(
        storageService: storageService,
        authRepository: authRepository,
        homeRepository: homeRepository,
        streamRepository: streamRepository,
        libraryRepository: libraryRepository,
        userRepository: userRepository,
        audioPlayerService: audioPlayerService,
        notificationService: notificationService,
        searchService: searchService,
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('Error initializing app: $e');
    debugPrint('StackTrace: $stackTrace');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 20),
                  const Text(
                    'Failed to initialize app',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final StorageService storageService;
  final AuthRepository authRepository;
  final HomeRepository homeRepository;
  final StreamRepository streamRepository;
  final LibraryRepository libraryRepository;
  final UserRepository userRepository;
  final AudioPlayerService audioPlayerService;
  final NotificationService notificationService;
  final SearchService searchService;

  const MyApp({
    super.key,
    required this.storageService,
    required this.authRepository,
    required this.homeRepository,
    required this.streamRepository,
    required this.libraryRepository,
    required this.userRepository,
    required this.audioPlayerService,
    required this.notificationService,
    required this.searchService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<StorageService>.value(value: storageService),
        RepositoryProvider<HomeRepository>.value(value: homeRepository),
        RepositoryProvider<StreamRepository>.value(value: streamRepository),
        RepositoryProvider<UserRepository>.value(value: userRepository),
        RepositoryProvider<AudioPlayerService>.value(value: audioPlayerService),
        RepositoryProvider<SearchService>.value(value: searchService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(
              authRepository: authRepository,
              storageService: storageService,
              notificationService: notificationService,
            ),
          ),
          BlocProvider(
            create: (context) => HomeBloc(
              homeRepository: homeRepository,
              streamRepository: streamRepository,
            )..add(const HomeLoadRequested()),
          ),
          BlocProvider(
            create: (context) => PlayerBloc(
              audioService: audioPlayerService,
              streamRepository: streamRepository,
              storageService: storageService,
            ),
          ),
          BlocProvider(create: (context) => SearchBloc(searchService)),
          BlocProvider(
            create: (context) =>
                LibraryBloc(libraryRepository)..add(LibraryLoadAll()),
          ),
          BlocProvider(
            create: (context) =>
                ProfileBloc(userRepository)..add(ProfileLoad()),
          ),
        ],
        child: Builder(
          builder: (context) {
            final authBloc = context.read<AuthBloc>();
            final appRouter = AppRouter(authBloc, storageService);
            final router = appRouter.router;

            // Initialize DeepLinkService
            DeepLinkService(router).init();

            return DynamicColorBuilder(
              builder: (lightDynamic, darkDynamic) {
                // Use darkDynamic to customize our dark theme if available
                final theme = AppTheme.darkTheme.copyWith(
                  colorScheme: darkDynamic ?? AppTheme.darkTheme.colorScheme,
                );

                return MaterialApp.router(
                  title: 'FaithStream',
                  debugShowCheckedModeBanner: false,
                  theme: theme,
                  themeMode: ThemeMode.dark,
                  routerConfig: router,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
