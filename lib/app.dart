import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gpt_flutter/pages/splash_screen.dart';
import 'package:gpt_flutter/routes/app_routes.dart';
import 'package:gpt_flutter/routes/routes.dart';
import 'package:gpt_flutter/state/init_data.dart';
import 'package:gpt_flutter/utils/app_config.dart';
import 'package:gpt_flutter/utils/local_notification_observer.dart';
import 'package:provider/provider.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:stream_chat_localizations/stream_chat_localizations.dart';
import 'package:stream_chat_persistence/stream_chat_persistence.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

import 'utils/localizations.dart';

final chatPersistentClient = StreamChatPersistenceClient(
  logLevel: Level.SEVERE,
  connectionMode: ConnectionMode.regular,
);

StreamChatClient buildStreamChatClient(String apiKey) {
  late Level logLevel;
  if (kDebugMode) {
    logLevel = Level.INFO;
  } else {
    logLevel = Level.SEVERE;
  }

  return StreamChatClient(apiKey, logLevel: logLevel)
    ..chatPersistenceClient = chatPersistentClient;
}

class ChatGptApp extends StatefulWidget {
  const ChatGptApp({super.key});

  @override
  State<ChatGptApp> createState() => _ChatGptAppState();
}

class _ChatGptAppState extends State<ChatGptApp>
    with SplashScreenStateMixin, TickerProviderStateMixin {
  final InitNotifier _initNotifier = InitNotifier();
  StreamSubscription<String?>? userIdSubscription;

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey();
  LocalNotificationObserver? localNotificationObserver;

  Future<InitData> _initConnection() async {
    String? apiKey, userId, token;
    if (!kIsWeb) {
      /* const secureStorage = FlutterSecureStorage(); 
      apiKey = await secureStorage.read(key: kStreamApiKey);
      userId = await secureStorage.read(key: kStreamUserId);
      token = await secureStorage.read(key: kStreamToken); */
    }

    final client = buildStreamChatClient(apiKey ?? kDefaultStreamApiKey);
    late User user;
    if (kDebugMode) {
      user = User(
          id: "5b87bb36-4303-43cc-9800-ed5777a20c98",
          name: "User 29",
          image: "https://picsum.photos/id/488/300/300");
    } else {
      user = User(
          id: Uuid().v4(),
          name: "User ${Random().nextInt(10000)}",
          image: "https://picsum.photos/id/${Random().nextInt(1000)}/300/300");
    }
    await client.connectUser(user, client.devToken(user.id).rawValue);
    final prefs = await StreamingSharedPreferences.instance;
    return InitData(client, prefs);
  }

  @override
  void initState() {
    final timeOfStartMs = DateTime.now().microsecondsSinceEpoch;
    _initConnection().then((initData) => {
          setState(() {
            _initNotifier.initData = initData;
          })
        });
    super.initState();
  }

  GoRouter _setupRouter() {
    if (localNotificationObserver != null) {
      localNotificationObserver!.dispose();
    }
    localNotificationObserver = LocalNotificationObserver(
        _initNotifier.initData!.client, _navigatorKey);

    return GoRouter(
      refreshListenable: _initNotifier,
      initialLocation: Routes.CHANNEL_LIST_PAGE.path,
      navigatorKey: _navigatorKey,
      observers: [localNotificationObserver!],
      redirect: (context, state) {
        final loggedIn =
            _initNotifier.initData?.client.state.currentUser != null;
        final loggingIn = state.matchedLocation == Routes.CHOOSE_USER.path ||
            state.matchedLocation == Routes.ADVANCED_OPTIONS.path;
        return Routes.CHANNEL_LIST_PAGE.path;
      },
      routes: appRoutes,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_initNotifier.initData != null)
          ChangeNotifierProvider.value(
            value: _initNotifier,
            builder: (context, child) => Builder(builder: (context) {
              context.watch<InitNotifier>();
              return PreferenceBuilder<int>(
                preference: _initNotifier.initData!.preferences
                    .getInt('theme', defaultValue: 0),
                builder: (context, snapshot) => MaterialApp.router(
                  theme: ThemeData.light(),
                  darkTheme: ThemeData.dark(),
                  themeMode: const {
                    -1: ThemeMode.dark,
                    0: ThemeMode.system,
                    1: ThemeMode.light,
                  }[snapshot],
                  supportedLocales: const [
                    Locale('en'),
                    Locale('zh'),
                  ],
                  localizationsDelegates: const [
                    AppLocalizationsDelegate(),
                    GlobalStreamChatLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                  ],
                  builder: (context, child) => StreamChat(
                    client: _initNotifier.initData!.client,
                    child: child,
                  ),
                  routerConfig: _setupRouter(),
                ),
              );
            }),
          ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
    userIdSubscription?.cancel();
  }
}

extension on List<StreamSubscription> {
  void cancelAll() {
    for (final subscription in this) {
      unawaited(subscription.cancel());
    }
    clear();
  }
}
