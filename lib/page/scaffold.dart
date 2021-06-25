import 'package:animations/animations.dart';
import 'package:dsgo/datasource/connection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neat_periodic_task/neat_periodic_task.dart';
import 'package:synoapi/synoapi.dart';

import '../main.dart';
import '../model/model.dart';
import '../page/add_task.dart';
import '../page/connection.dart';
import '../page/drawer.dart';
import '../page/tasks.dart';
import '../util/utils.dart';

class MainScaffold extends StatefulWidget {
  final UserSettings settings;

  MainScaffold(this.settings);

  @override
  State<StatefulWidget> createState() => MainScaffoldState(settings);
}

class MainScaffoldState extends State<MainScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final searchController = TextEditingController();
  UserSettings settings;
  final otpProvider = StateProvider((ref) => '');
  bool isLoginInProgress = false;
  bool isLoginFailed = false;
  NeatPeriodicTaskScheduler? apiTasksScheduler;
  NeatPeriodicTaskScheduler? statisticScheduler;

  MainScaffoldState(this.settings);

  @override
  void dispose() {
    apiTasksScheduler?.stop();
    statisticScheduler?.stop();
    super.dispose();
  }

  @override
  void initState() {
    searchController.addListener(() {
      context.read(searchTextProvider).state = searchController.text;
    });
    context.read(userSettingsProvider).addListener((newSettings) {
      settings = newSettings;
      setupSchedulers();
    });
    context.read(connectionProvider).addListener((state) {
      this.isLoginFailed = false;
    });
    setupSchedulers();
    super.initState();
  }

  void setupSchedulers() {
    apiTasksScheduler?.stop();
    statisticScheduler?.stop();

    l.info('init scheduler, ${settings.apiRequestFrequency}');
    apiTasksScheduler = NeatPeriodicTaskScheduler(
      name: 'Task list',
      interval: Duration(milliseconds: settings.apiRequestFrequency),
      task: () async {
        if (isLoginFailed) return;

        final l10n = AppLocalizations.of(context)!;
        var apiContext = context.read(apiContextProvider).state;
        if (apiContext == null || !apiContext.hasSid(Syno.DownloadStation.name)) return;

        var api = context.read(dsAPIProvider);
        if (api != null) {
          final resp = await api.task.list(additional: ['transfer']);
          if (resp.success) {
            context.read(tasksInfoProvider).state = resp.data;
          } else {
            l.warning("Error retrieving task list, ${resp.error}");
            // failed to get updates from server due to auth failure?
            // if so, pause the request and redirect to login page
            if ([105, 106, 107].contains(resp.error?['code'])) {
              isLoginFailed = true;
              ScaffoldMessenger.of(context)
                ..removeCurrentSnackBar()
                ..showSnackBar(buildSnackBar(
                    '${l10n.loginFailed}',
                    duration: Duration(seconds: 8),
                    showProgressIndicator: false,
                  action: SnackBarAction(label: '${l10n.login}', onPressed: () {
                    final connectionContext = context.read(connectionProvider).state;
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ConnectionEditForm.edit(0, connectionContext)),
                    );
                  })
                ));
            } else {
              ScaffoldMessenger.of(context)
                ..removeCurrentSnackBar()
                ..showSnackBar(buildSnackBar(
                    '${l10n.failed}. ${resp.error}',
                    duration: Duration(seconds: 3),
                    showProgressIndicator: false
                ));
            }
          }
        }
      },
      timeout: Duration(seconds: 30),
      minCycle: Duration(milliseconds: 250),
    );
    apiTasksScheduler?.start();

    statisticScheduler = NeatPeriodicTaskScheduler(
      name: 'Task list',
      interval: Duration(milliseconds: settings.apiRequestFrequency),
      task: () async {
        var apiContext = context.read(apiContextProvider).state;
        if (apiContext == null || !apiContext.hasSid(Syno.DownloadStation.name)) return;

        var api = context.read(dsAPIProvider);
        if (api != null) {
          final resp = await api.statistic.getInfo();
          if (resp.success) context.read(statsInfoProvider).state = resp.data;
        }
      },
      timeout: Duration(seconds: 30),
      minCycle: Duration(milliseconds: 250),
    );
    statisticScheduler?.start();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          ..showSnackBar(buildSnackBar('${authOK ? l10n.loginSuccess : l10n.loginFailed}',
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
                          decoration: InputDecoration(hintText: l10n.searchBarText, border: InputBorder.none),
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
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.taskResumed)));
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
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.taskPaused)));
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
                                      title: Text(l10n.clipboard),
                                      content: Text(text),
                                      actions: <Widget>[
                                        FlatButton(
                                          child: Text(l10n.cancel),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        FlatButton(
                                          child: Text(l10n.add),
                                          onPressed: () {
                                            var api = context.read(dsAPIProvider);
                                            if (api == null) return;
                                            // submit task
                                            Navigator.of(context).pop();
                                            ScaffoldMessenger.of(_scaffoldKey.currentState!.context)
                                                .showSnackBar(buildSnackBar(l10n.taskSubmitting));
                                            api.task.create(uris: [text]).then((resp) {
                                              if (resp.success) {
                                                ScaffoldMessenger.of(_scaffoldKey.currentState!.context)
                                                    .removeCurrentSnackBar();
                                                ScaffoldMessenger.of(_scaffoldKey.currentState!.context)
                                                    .showSnackBar(SnackBar(
                                                  content: Text(l10n.taskCreated),
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
                                content: Text(l10n.warningClipboardEmpty),
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
