import 'dart:async';

import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:synoapi/synoapi.dart';

import 'bloc/connection_bloc.dart';
import 'bloc/delegate.dart';
import 'bloc/syno_api_bloc.dart';
import 'bloc/ui_evt_bloc.dart';
import 'model/model.dart';
import 'page/add_task.dart';
import 'page/drawer.dart';
import 'page/tasks.dart';
import 'datasource/user_settings.dart';
import 'util/utils.dart';

void main() {
  // logger configuration
  Logger.root.level = Level.FINE;
  Logger.root.onRecord.listen((l) {
    print('${l.time} ${l.level} ${l.loggerName} | ${l.message}${l.error ?? ''}${l.stackTrace ?? ''}');
  });
  Logger.detached('SynoAPI').level = Level.WARNING;

  runApp(App());
}

class App extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => AppState();
}

class AppState extends State<App> {
  UserSettings? settings;
  late UserSettingsDatasource userSettingsProvider;
  var lastConnection; // for connection change detection

  // blocs
  final connectionBloc = DSConnectionBloc();
  final apiBloc = SynoApiBloc();
  final uiBloc = UiEventBloc();

  AppState() {
    if (kIsWeb) {
      userSettingsProvider = WebUserSettingsDatasource();
    } else {
      userSettingsProvider = MobileUserSettingsDatasource();
    }

    // auto update api context when connection changed
    connectionBloc.stream.listen((event) {
      if (event.activeConnection == null) {
        apiBloc.apiContext = null;
      }

      if (event.activeConnection != null && lastConnection != event.activeConnection) {
        var c = event.activeConnection!;
        if (c.uri == null) return;
        var context = APIContext.uri(c.uri!);
        context.authApp('DownloadStation', c.user!, c.password!).then((authOk) {
          if (authOk) {
            apiBloc.apiContext = context;
          } else {
            l.info('Authentication failed!');
          }
        });
      }
    });
  }

  @override
  void initState() {
    userSettingsProvider.get().then((settings) {
      if (mounted) {
        setState(() {
          this.settings = settings;
        });
      }
    });
    userSettingsProvider.onSet()!.listen((settings) {
      if (mounted) {
        setState(() {
          this.settings = settings;
        });
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (settings == null) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    Bloc.observer = BlocLogDelegate();

    return MultiBlocProvider(
      providers: [
        BlocProvider<DSConnectionBloc>(
          create: (_) => connectionBloc,
        ),
        BlocProvider<UiEventBloc>(
          create: (_) => uiBloc,
        ),
        BlocProvider<SynoApiBloc>(
          create: (_) => apiBloc,
        )
      ],
      child: MaterialApp(
        home: Material(child: MainScaffold(settings)),
        themeMode: settings!.themeMode,
        theme: ThemeData.light().copyWith(
          iconTheme: IconThemeData(color: Color(0xff4f4f4f)),
        ),
        darkTheme: ThemeData.dark().copyWith(appBarTheme: AppBarTheme(color: Color(0xff404040))),
      ),
    );
  }
}

class MainScaffold extends StatefulWidget {
  UserSettings? settings;

  MainScaffold(this.settings);

  @override
  State<StatefulWidget> createState() => MainScaffoldState(settings);
}

class MainScaffoldState extends State<MainScaffold> {
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  var _searchController = TextEditingController();
  late UiEventBloc uiBloc;
  late SynoApiBloc apiBloc;
  DSConnectionBloc? connBloc;
  List<StreamSubscription> _subs = [];
  var _fetching = false;
  var totalUp = 0;
  var totalDown = 0;
  var infoWidgets = <Widget>[];
  List<String?> taskIds = [];
  UserSettings? settings;

  MainScaffoldState(this.settings);

  @override
  void dispose() {
    _subs.forEach((e) => e.cancel());
    super.dispose();
  }

  @override
  void initState() {
    uiBloc = BlocProvider.of<UiEventBloc>(context);
    apiBloc = BlocProvider.of<SynoApiBloc>(context);
    connBloc = BlocProvider.of<DSConnectionBloc>(context);

    _searchController.addListener(() {
      final text = _searchController.text;
      uiBloc.add(UiEventState(this, UiEvent.tasks_filter_change, [text]));
      if (mounted) setState(() {});
    });

    _subs.add(Stream.periodic(Duration(milliseconds: settings!.apiRequestFrequency!)).listen((event) {
      if (!_fetching) {
        apiBloc.add(SynoApiEvent(RequestType.statistic_info));
      }
    }));

    apiBloc.stream.listen((SynoApiState state) {
      // get statistic
      if (state.event?.requestType == RequestType.statistic_info && state.resp?.data != null) {
        var info = state.resp!.data as DownloadStationStatisticGetInfo?;
        setState(() {
          totalDown = (info?.speedDownload ?? 0) + (info?.emuleSpeedDownload ?? 0);
          totalUp = (info?.speedUpload ?? 0) + (info?.emuleSpeedUpload ?? 0);
        });
      }

      if (state.event?.requestType == RequestType.task_list) {
        APIResponse<ListTaskInfo>? info = state.resp as APIResponse<ListTaskInfo>?;
        if (info?.data == null) return;

        taskIds.replaceRange(0, taskIds.length, info!.data!.tasks.map((task) => task.id).toList());
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    infoWidgets.clear();

    // TODO - this would block buttons on narrow screen
    // total up/down speed
    //infoWidgets.add(Text(humanifySize(totalDown)));
    //infoWidgets.add(Icon(Icons.arrow_downward));
    //infoWidgets.add(Text(humanifySize(totalUp)));
    //infoWidgets.add(Icon(Icons.arrow_upward));

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
                              controller: _searchController,
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
                  var scaffold = _scaffoldKey.currentState!;
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
                  height: 45 + (kIsWeb ? 20 : 0), // TODO - temporary solution for iphone bottom tab bar on fullscreen browser
                  child: Stack(
                    children: <Widget>[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          IconButton(
                            icon: Icon(Icons.play_arrow),
                            onPressed: () {
                              // start all tasks
                              apiBloc.add(SynoApiEvent.resumeTask(taskIds, onCompleted: (state) {
                                if (state.resp!.success) {
                                  ScaffoldMessenger.of(_scaffoldKey.currentState!.context)
                                      .showSnackBar(SnackBar(content: Text('Tasks resumed.')));
                                }
                              }));
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.pause),
                            onPressed: () {
                              // pause all tasks
                              apiBloc.add(SynoApiEvent.pauseTask(taskIds, onCompleted: (state) {
                                if (state.resp!.success) {
                                  ScaffoldMessenger.of(_scaffoldKey.currentState!.context)
                                      .showSnackBar(SnackBar(content: Text('Tasks paused.')));
                                }
                              }));
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.content_paste),
                            onPressed: () {
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
                                                // submit task
                                                Navigator.of(context).pop();
                                                ScaffoldMessenger.of(_scaffoldKey.currentState!.context)
                                                    .showSnackBar(buildSnackBar('Submitting tasks...'));
                                                apiBloc.add(SynoApiEvent.addTask(
                                                  uris: [text],
                                                  onCompleted: (state) {
                                                    ScaffoldMessenger.of(_scaffoldKey.currentState!.context)
                                                        .removeCurrentSnackBar();
                                                    if (state.resp!.success) {
                                                      ScaffoldMessenger.of(_scaffoldKey.currentState!.context)
                                                          .showSnackBar(SnackBar(
                                                        content: Text('Task Submitted.'),
                                                      ));
                                                    }
                                                  },
                                                ));
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
                      Center(
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.max,
                              children: infoWidgets)),
                    ],
                  )),
            ),
            drawer: AppDrawer(),
          )),
    );
  }
}
