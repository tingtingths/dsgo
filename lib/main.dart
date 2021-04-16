import 'dart:async';

import 'package:animations/animations.dart';
import 'bloc/connection_bloc.dart';
import 'bloc/delegate.dart';
import 'bloc/syno_api_bloc.dart';
import 'bloc/ui_evt_bloc.dart';
import 'page/add_task.dart';
import 'page/tasks.dart';
import 'provider/user_settings.dart';
import 'util/format.dart';
import 'util/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:synoapi/synoapi.dart';

import 'model/model.dart';
import 'page/drawer.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  UserSettings settings;

  @override
  void initState() {
    MobileUserSettingsProvider().get().then((settings) {
      if (mounted) {
        setState(() {
          this.settings = settings;
        });
      }
    });
    MobileUserSettingsProvider().onSet().listen((settings) {
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
          create: (_) => DSConnectionBloc(),
        ),
        BlocProvider<UiEventBloc>(
          create: (_) => UiEventBloc(),
        ),
        BlocProvider<SynoApiBloc>(
          create: (_) => SynoApiBloc(),
        )
      ],
      child: MaterialApp(
        home: Material(child: MyScaffold(settings)),
        themeMode: settings.themeMode,
        theme: ThemeData.light().copyWith(
          iconTheme: IconThemeData(color: Color(0xff4f4f4f)),
        ),
        darkTheme: ThemeData.dark().copyWith(appBarTheme: AppBarTheme(color: Color(0xff404040))),
      ),
    );
  }
}

class MyScaffold extends StatefulWidget {
  UserSettings settings;

  MyScaffold(this.settings);

  @override
  State<StatefulWidget> createState() => MyScaffoldState(settings);
}

class MyScaffoldState extends State<MyScaffold> {
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  var _searchController = TextEditingController();
  UiEventBloc uiBloc;
  SynoApiBloc apiBloc;
  DSConnectionBloc connBloc;
  List<StreamSubscription> _subs = [];
  var _fetching = false;
  var totalUp = 0;
  var totalDown = 0;
  var infoWidgets = <Widget>[];
  var _addTaskReqId;
  List<String> taskIds = [];
  UserSettings settings;

  MyScaffoldState(this.settings);

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

    _subs.add(Stream.periodic(Duration(milliseconds: settings.apiRequestFrequency)).listen((event) {
      if (!_fetching) {
        apiBloc.add(SynoApiEvent(RequestType.statistic_info));
      }
    }));

    apiBloc.listen((SynoApiState state) {
      // get statistic
      if (state.event?.requestType == RequestType.statistic_info && state.resp?.data != null) {
        var info = state.resp.data as DownloadStationStatisticGetInfo;
        setState(() {
          totalDown = info.speedDownload ?? 0 + info.emuleSpeedDownload ?? 0;
          totalUp = info.speedUpload ?? 0 + info.emuleSpeedUpload ?? 0;
        });
      }

      if (state.event?.requestType == RequestType.task_list) {
        APIResponse<ListTaskInfo> info = state.resp;
        if (info?.data == null) return;

        taskIds.replaceRange(0, taskIds.length, info.data.tasks.map((task) => task.id).toList());
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    infoWidgets.clear();

    if (false && totalDown != null) {
      infoWidgets.add(Text(humanifySize(totalDown)));
      infoWidgets.add(Icon(Icons.arrow_downward));
    }
    if (false && totalUp != null) {
      infoWidgets.add(Text(humanifySize(totalUp)));
      infoWidgets.add(Icon(Icons.arrow_upward));
    }

    var scaffold = Scaffold(
      key: _scaffoldKey,
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Expanded(
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverPadding(
                    padding: EdgeInsets.only(left: 20, right: 20),
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
                            _scaffoldKey.currentState.openDrawer();
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
      ),
      floatingActionButton: OpenContainer(
        closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
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
        onClosed: (String data) {
          if (data != null) {
            var scaffold = _scaffoldKey.currentState;
            scaffold.removeCurrentSnackBar();
            scaffold.showSnackBar(SnackBar(
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
            height: 45,
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
                          if (state.resp.success) {
                            _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text('Tasks resumed.')));
                          }
                        }));
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.pause),
                      onPressed: () {
                        // pause all tasks
                        apiBloc.add(SynoApiEvent.pauseTask(taskIds, onCompleted: (state) {
                          if (state.resp.success) {
                            _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text('Tasks paused.')));
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
                                          _scaffoldKey.currentState.showSnackBar(buildSnackBar('Submitting tasks...'));
                                          apiBloc.add(SynoApiEvent.addTask(
                                            uris: [text],
                                            onCompleted: (state) {
                                              _scaffoldKey.currentState.removeCurrentSnackBar();
                                              if (state.resp.success) {
                                                _scaffoldKey.currentState.showSnackBar(SnackBar(
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
                            _scaffoldKey.currentState.removeCurrentSnackBar();
                            _scaffoldKey.currentState.showSnackBar(SnackBar(
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
      drawer: MyDrawer(),
    );

    return GestureDetector(
      onTap: () {
        print('taptap');
        var node = FocusScope.of(context);
        if (!node.hasPrimaryFocus) {
          node.unfocus();
        }
      },
      child: scaffold,
    );
  }
}
