import 'dart:async';

import 'package:animations/animations.dart';
import 'package:dsgo/datasource/connection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:synoapi/synoapi.dart';

import 'datasource/user_settings.dart';
import 'model/model.dart';
import 'page/add_task.dart';
import 'page/connection.dart';
import 'page/drawer.dart';
import 'page/tasks.dart';
import 'util/utils.dart';

final userSettingsProvider = StateProvider<UserSettings>((ref) => UserSettings());
final connectionProvider = StateProvider<Connection?>((ref) => null);
final apiContextProvider = StateProvider<APIContext?>((ref) {
  var connection = ref.watch(connectionProvider).state;
  if (connection == null || connection.uri == null) return null;
  if (connection.sid == null)
    return APIContext.uri(connection.uri!);
  else
    return APIContext.uri(connection.uri!, sid: {Syno.DownloadStation.name: connection.sid!});
});
final dsAPIProvider = Provider<DownloadStationAPI?>((ref) {
  var context = ref.watch(apiContextProvider).state;
  if (context == null) return null;
  return DownloadStationAPI(context);
});

// main page provider
final tasksInfoProvider = StateProvider<ListTaskInfo?>((ref) => null);
final statsInfoProvider = StateProvider<DownloadStationStatisticGetInfo?>((ref) => null);
final searchTextProvider = StateProvider((ref) => '');

void main() {
  // logger configuration
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((l) {
    print('${l.time} ${l.level} ${l.loggerName} | ${l.message}${l.error ?? ''}${l.stackTrace ?? ''}');
  });
  Logger.detached('SynoAPI').level = Level.WARNING;

  runApp(ProviderScope(child: App()));
}

class App extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => AppState();
}

class AppState extends State<App> {
  @override
  void initState() {
    // load configurations from storage
    context.read(userSettingsDatastoreProvider).get().then((userSettings) {
      context.read(userSettingsProvider).state = userSettings;
    });
    context.read(connectionDatastoreProvider).getAll().then((connections) {
      if (connections.length > 0) {
        context.read(connectionProvider).state = connections[0];
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, watch, _) {
      var settings = watch(userSettingsProvider).state;
      return MaterialApp(
        home: Material(child: MainScaffold(settings)),
        themeMode: settings.themeMode,
        theme: ThemeData.light().copyWith(
          iconTheme: IconThemeData(color: Color(0xff4f4f4f)),
        ),
        darkTheme: ThemeData.dark().copyWith(appBarTheme: AppBarTheme(color: Color(0xff404040))),
      );
    });
  }
}

class MainScaffold extends StatefulWidget {
  final UserSettings settings;

  MainScaffold(this.settings);

  @override
  State<StatefulWidget> createState() => MainScaffoldState(settings);
}

class MainScaffoldState extends State<MainScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final searchController = TextEditingController();
  final List<StreamSubscription> subscriptions = [];
  final UserSettings settings;
  final otpProvider = StateProvider((ref) => '');
  bool isLoginInProgress = false;

  MainScaffoldState(this.settings);

  @override
  void dispose() {
    subscriptions.forEach((e) => e.cancel());
    super.dispose();
  }

  @override
  void initState() {
    searchController.addListener(() {
      context.read(searchTextProvider).state = searchController.text;
    });

    // periodically retrieve overall tasks info from server
    subscriptions.add(Stream.periodic(Duration(milliseconds: settings.apiRequestFrequency)).listen((event) async {
      var apiContext = context.read(apiContextProvider).state;
      if (apiContext == null || !apiContext.hasSid(Syno.DownloadStation.name)) return;

      var api = context.read(dsAPIProvider);
      if (api != null) {
        api.task.list(additional: ['transfer']).then((resp) {
          context.read(tasksInfoProvider).state = resp.data;
        });
        api.statistic.getInfo().then((resp) {
          context.read(statsInfoProvider).state = resp.data;
        });
      }
    }));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var apiContext = context.read(apiContextProvider).state;
    if (apiContext != null && !apiContext.hasSid(Syno.DownloadStation.name) && !isLoginInProgress) {
      isLoginInProgress = true;
      var connection = context.read(connectionProvider).state!;
      apiContext.authApp(Syno.DownloadStation.name, connection.user ?? '', connection.password ?? '',
          otpCallback: () async {
        return await showOTPDialog(context) ?? '';
      }).then((authOK) {
        isLoginInProgress = false;
        connection.sid = apiContext.getSid(Syno.DownloadStation.name);
        context.read(connectionProvider).state = connection;
        context.read(connectionDatastoreProvider).replace(0, connection);
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(buildSnackBar('Login ${authOK ? 'success' : 'failed'}!',
              duration: Duration(seconds: 3), showProgressIndicator: false));
      });
    }

    return GestureDetector(
      onTap: () {
        var node = FocusScope.of(context);
        if (!node.hasPrimaryFocus) {
          node.unfocus();
        }
      },
      child: SafeArea(
          child: Scaffold(
        key: _scaffoldKey,
        body: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Expanded(
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverPadding(
                    padding: EdgeInsets.only(left: 20, right: 20, top: 5),
                    sliver: SliverAppBar(
                        backgroundColor: Theme.of(context).bottomAppBarColor,
                        iconTheme: Theme.of(context).iconTheme,
                        forceElevated: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        leading: IconButton(
                          icon: Icon(Icons.menu),
                          onPressed: () {
                            _scaffoldKey.currentState!.openDrawer();
                          },
                        ),
                        title: TextField(
                          textInputAction: TextInputAction.search,
                          controller: searchController,
                          decoration: InputDecoration(hintText: 'Search tasks', border: InputBorder.none),
                        )),
                  ),
                  TaskList(settings),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: OpenContainer(
          closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          closedColor: Colors.transparent,
          closedBuilder: (context, openContainerCallback) {
            return FloatingActionButton(
              child: Icon(
                Icons.add,
                size: 32,
              ),
              onPressed: openContainerCallback,
            );
          },
          openBuilder: (context, CloseContainerActionCallback<String> closeContainerCallback) {
            return AddTaskForm();
          },
          onClosed: (String? data) {
            if (data != null) {
              ScaffoldMessenger.of(context)
                ..removeCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(data),
                ));
            }
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          child: Container(
              padding: EdgeInsets.only(left: 5),
              height: 45 + (kIsWeb ? 20 : 0),
              // TODO - temporary solution for iphone bottom tab bar on fullscreen browser
              child: Stack(
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      IconButton(
                        icon: Icon(Icons.play_arrow),
                        onPressed: () {
                          var api = context.read(dsAPIProvider);
                          var tasksInfo = context.read(tasksInfoProvider).state;
                          if (api != null && tasksInfo?.tasks.isNotEmpty == true) {
                            api.task.resume(tasksInfo!.tasks.map((t) => t.id).toList() as List<String>).then((resp) {
                              if (resp.success) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tasks resumed.')));
                              }
                            });
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.pause),
                        onPressed: () {
                          // pause all tasks
                          var api = context.read(dsAPIProvider);
                          var tasksInfo = context.read(tasksInfoProvider).state;
                          if (api != null && tasksInfo?.tasks.isNotEmpty == true) {
                            api.task.pause(tasksInfo!.tasks.map((t) => t.id).toList() as List<String>).then((resp) {
                              if (resp.success) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tasks paused.')));
                              }
                            });
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.content_paste),
                        onPressed: () {
                          var api = context.read(dsAPIProvider);
                          if (api == null) return;
                          Clipboard.getData('text/plain').then((data) {
                            var text = data?.text ?? '';
                            if (Uri.parse(text).isAbsolute) {
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text('Add from clipboard'),
                                      content: Text(text),
                                      actions: <Widget>[
                                        FlatButton(
                                          child: Text('Cancel'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        FlatButton(
                                          child: Text('Add'),
                                          onPressed: () {
                                            var api = context.read(dsAPIProvider);
                                            if (api == null) return;
                                            // submit task
                                            Navigator.of(context).pop();
                                            ScaffoldMessenger.of(_scaffoldKey.currentState!.context)
                                                .showSnackBar(buildSnackBar('Submitting tasks...'));
                                            api.task.create(uris: [text]).then((resp) {
                                              if (resp.success) {
                                                ScaffoldMessenger.of(_scaffoldKey.currentState!.context)
                                                    .removeCurrentSnackBar();
                                                ScaffoldMessenger.of(_scaffoldKey.currentState!.context)
                                                    .showSnackBar(SnackBar(
                                                  content: Text('Task Submitted.'),
                                                ));
                                              }
                                            });
                                          },
                                        )
                                      ],
                                    );
                                  });
                            } else {
                              ScaffoldMessenger.of(_scaffoldKey.currentState!.context).removeCurrentSnackBar();
                              ScaffoldMessenger.of(_scaffoldKey.currentState!.context).showSnackBar(SnackBar(
                                content: Text('No Uri in clipboard...'),
                                duration: Duration(milliseconds: 500),
                              ));
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ],
              )),
        ),
        drawer: AppDrawer(),
      )),
    );
  }
}
