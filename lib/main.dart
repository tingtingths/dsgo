import 'dart:ui';

import 'package:dsgo/datasource/connection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:synoapi/synoapi.dart';

import 'datasource/user_settings.dart';
import 'model/model.dart';
import 'page/scaffold.dart';

final userSettingsProvider = StateProvider<UserSettings>((ref) => UserSettings());
final connectionProvider = StateProvider<Connection?>((ref) => null);
final apiContextProvider = StateProvider<APIContext?>((ref) {
  var connection = ref.watch(connectionProvider);
  if (connection == null || connection.uri == null) return null;
  if (connection.sid == null)
    return APIContext.uri(connection.uri!);
  else
    return APIContext.uri(connection.uri!, sid: {Syno.DownloadStation.name: connection.sid!});
});
final dsAPIProvider = Provider<DownloadStationAPI?>((ref) {
  var context = ref.watch(apiContextProvider);
  if (context == null) return null;
  return DownloadStationAPI(context);
});

// main page provider
final tasksInfoProvider = StateProvider<ListTaskInfo?>((ref) => null);
final statsInfoProvider = StateProvider<DownloadStationStatisticGetInfo?>((ref) => null);
final searchTextProvider = StateProvider((ref) => '');

void main() {
  // logger configuration
  hierarchicalLoggingEnabled = true;
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((l) {
    print('${l.time} ${l.level} ${l.loggerName} | ${l.message}${l.error ?? ''}${l.stackTrace ?? ''}');
  });
  Logger.detached('SynoAPI').level = Level.WARNING;
  Logger('neat_periodic_task').level = Level.WARNING;

  runApp(ProviderScope(child: App()));
}

class App extends ConsumerStatefulWidget {
  @override
  ConsumerState<App> createState() => AppState();
}

class AppState extends ConsumerState<App> {
  final l = Logger('AppState');

  @override
  void initState() {
    // load configurations from storage
    ref.read(userSettingsDatastoreProvider).get().then((userSettings) {
      ref.read(userSettingsProvider.state).state = userSettings;
    });
    ref.read(connectionDatastoreProvider).getAll().then((connections) {
      if (connections.length > 0) {
        ref.read(connectionProvider.state).state = connections[0];
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, watch, _) {
      var settings = ref.watch(userSettingsProvider.state).state;
      final locale = settings.locale ?? PlatformDispatcher.instance.locale;

      return MaterialApp(
          home: Material(child: MainScaffold(settings)),
          themeMode: settings.themeMode,
          theme: ThemeData.light().copyWith(
            colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.teal),
            appBarTheme: ThemeData.light().appBarTheme.copyWith(color: Colors.teal),
            iconTheme: IconThemeData(color: Color(0xff4f4f4f)),
          ),
          darkTheme: ThemeData.dark().copyWith(appBarTheme: AppBarTheme(color: Color(0xff404040))),
          // localization
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            const Locale('en'),
            const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
          ],
          locale: locale);
    });
  }
}
