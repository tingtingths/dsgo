import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:morpheus/morpheus.dart';
import 'package:synodownloadstation/bloc/connection_bloc.dart' as cBloc;
import 'package:synodownloadstation/bloc/ui_evt_bloc.dart';
import 'package:synodownloadstation/model/model.dart';
import 'package:synodownloadstation/page/task_tab.dart';
import 'package:synodownloadstation/syno/api/context.dart';
import 'package:synodownloadstation/syno/api/modeled/downloadstation.dart';
import 'package:synodownloadstation/syno/api/modeled/model.dart';
import 'package:synodownloadstation/util/extension.dart';
import 'package:synodownloadstation/util/format.dart';

Future<ListTaskInfo> fetchTaskInfo(Connection conn) async {
  var cntx = APIContext(conn.host, proto: conn.proto, port: conn.port);

  if (!cntx.appSid.containsKey('DownloadStation') ||
      cntx.appSid['DownloadStation'] == null) {
    await cntx.authApp('DownloadStation', conn.user, conn.password);
  }
  var dsApi = DownloadStationAPI(cntx);

  return dsApi.taskList().then((value) => value.data);
}

class TaskList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _TaskListState();
}

class _TaskListState extends State<TaskList>
    with SingleTickerProviderStateMixin {
  ListTaskInfo futureTaskInfo = null;
  Stream fetchStream;
  Connection _connection;
  var filter = '';
  bool _fetching = false;
  TextTheme textTheme;
  AnimationController _pgsBarAnimController;
  Animation<Color> _pgsBarAnim;
  List<GlobalKey> _cardKeys = [];

  @override
  void initState() {
    super.initState();

    // animate color progress bar color
    _pgsBarAnimController =
        AnimationController(duration: Duration(seconds: 1), vsync: this)
          ..repeat(reverse: true)
          ..addListener(() {
            if (mounted) setState(() {});
          });
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      _pgsBarAnim = ColorTween(
              begin: Theme.of(context).primaryColor,
              end: Theme.of(context).primaryColorLight)
          .animate(_pgsBarAnimController);
    });

    var uiBloc = BlocProvider.of<UiEventBloc>(context);
    fetchStream = Stream.periodic(Duration(seconds: 1));
    fetchStream.listen((event) async {
      if (_connection == null || _fetching) return;

      _fetching = true;
      uiBloc.add(UiEventState.noPayload(this, UiEvent.task_fetching));
      var fetched = await fetchTaskInfo(_connection);
      if (mounted) {
        setState(() {
          futureTaskInfo = fetched;
        });
        BlocProvider.of<UiEventBloc>(context)
            .add(UiEventState(null, UiEvent.tasks_fetched, [DateTime.now(), fetched]));
      }
      _fetching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    textTheme = Theme.of(context).textTheme;

    BlocProvider.of<UiEventBloc>(context).listen((state) {
      if (state.event == UiEvent.tasks_filter_change) {
        var filterStr = state.payload.join();
        if (mounted) {
          setState(() {
            filter = filterStr;
          });
        }
      }
    });

    return BlocConsumer<cBloc.ConnectionBloc, cBloc.ConnectionState>(
      bloc: BlocProvider.of<cBloc.ConnectionBloc>(context),
      listener: (cntx, state) {
        setState(() {
          _connection = state.activeConnection;
        });
      },
      builder: (cntx, state) {
        var info = futureTaskInfo;

        if (_connection == null) {
          return Text('Select account first');
        }

        if (info == null) {
          return Center(child: CircularProgressIndicator());
        }

        if (info.total == 0) {
          return Text('No tasks');
        }

        return ListView.builder(
          addAutomaticKeepAlives: true,
          itemCount: info.total,
          itemBuilder: (cntx, idx) {
            if (_cardKeys.length <= idx) _cardKeys.add(GlobalKey());

            var task = info.tasks[idx % info.total];

            if (filter != null && filter.trim().isNotEmpty) {
              if (!task.title.toUpperCase().contains(filter.toUpperCase())) {
                return null;
              }
            }

            var totalSize = humanifySize(task.size);
            var downloaded =
                humanifySize(task.additional?.transfer?.sizeDownloaded);
            var progress =
                (task.additional?.transfer?.sizeDownloaded ?? 0) / task.size;
            progress = progress.isFinite ? progress : 0;
            var downSpeed = humanifySize(
                    task.additional?.transfer?.speedDownload ?? 0,
                    p: 0) +
                '/s';
            var upSpeed = humanifySize(
                    task.additional?.transfer?.speedUpload ?? 0,
                    p: 0) +
                '/s';
            var progressText = fmtNum(progress * 100, p: 0);

            var progressBar;
            if (false && TaskStatus.seeding == task.status) {
              progressBar = Stack(
                children: [
                  LinearProgressIndicator(
                    backgroundColor: Colors.white,
                    value: progress,
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return ConstrainedBox(
                        constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth * progress),
                        child: LinearProgressIndicator(),
                      );
                    },
                  ),
                ],
              );
            } else {
              progressBar = LinearProgressIndicator(
                backgroundColor: Colors.white,
                value: progress,
              );
            }

            var statusIcon = _getStatusIcon(task.status, () {
              print('icon selected');
              // TODO : trigger next action statue here
              /*
              i.e.
                Downloading -> Pause
                Pause -> Downloading
                ..etc?
               */
            }, onLongPress: () {
              // TODO : trigger multiple selection here
            });

            return Card(
              key: _cardKeys[idx],
              elevation: 5,
              margin: EdgeInsets.fromLTRB(10, 5, 10, 5),
              child: Column(
                children: <Widget>[
                  ListTile(
                    dense: false,
                    leading: statusIcon,
                    //contentPadding: EdgeInsets.fromLTRB(5, 5, 5, 5),
                    onTap: () {
                      Navigator.push(
                          context,
                          MorpheusPageRoute(
                              parentKey: _cardKeys[idx],
                              builder: (context) {
                                return BlocProvider.value(
                                  value: BlocProvider.of<cBloc.ConnectionBloc>(
                                      context),
                                  child: TaskDetailsPage(task),
                                );
                              }));
                    },
                    title: Text(
                      task.title,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: TextStyle(
                          fontSize:
                              Theme.of(context).textTheme.headline6.fontSize),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Divider(
                          height: 5,
                        ),
                        Text('${task.status.name.capitalize()}' +
                            (['seeding', 'finished']
                                    .contains(task.status.name.toLowerCase())
                                ? ''
                                : ' $progressText') +
                            ' | $downloaded of $totalSize'),
                        Row(
                          children: [
                            Icon(
                              Icons.arrow_downward,
                              size: textTheme.bodyText1.fontSize,
                            ),
                            Text(downSpeed),
                            Icon(Icons.arrow_upward,
                                size: textTheme.bodyText1.fontSize),
                            Text(upSpeed),
                          ],
                        )
                      ],
                    ),
                  ),
                  progressBar,
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _getStatusIcon(TaskStatus status, Function onPressed,
      {Function onLongPress}) {
    Color color = Colors.grey;
    double size = 38;
    Icon icon = Icon(Icons.info_outline);

    switch (status) {
      case TaskStatus.downloading:
        color = Colors.green;
        icon = Icon(Icons.file_download);
        break;
      case TaskStatus.error:
        color = Colors.amber;
        icon = Icon(Icons.pause);
        break;
      case TaskStatus.finishing:
        color = Colors.blue;
        icon = Icon(Icons.hourglass_empty);
        break;
      case TaskStatus.finished:
        color = Colors.blue;
        icon = Icon(Icons.check);
        break;
      case TaskStatus.hash_checking:
        color = Colors.amber;
        icon = Icon(Icons.hourglass_empty);
        break;
      case TaskStatus.seeding:
        color = Colors.blue;
        icon = Icon(Icons.file_upload);
        break;
      case TaskStatus.filehosting_waiting:
        color = Colors.amber;
        icon = Icon(Icons.hourglass_empty);
        break;
      case TaskStatus.extracting:
        color = Colors.amber;
        icon = Icon(Icons.present_to_all);
        break;
      case TaskStatus.error:
        color = Colors.red;
        icon = Icon(Icons.error_outline);
        break;
      case TaskStatus.waiting:
        color = Colors.deepOrange;
        icon = Icon(Icons.hourglass_empty);
        break;
    }

    return GestureDetector(
      onTap: onPressed,
      onLongPress: onLongPress,
      child: IconButton(
        iconSize: size,
        icon: icon,
        color: color,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class TaskDetailsPage extends StatefulWidget {
  Task _task;

  TaskDetailsPage(this._task) : assert(_task != null);

  @override
  State<StatefulWidget> createState() => TaskDetailsPageState(_task);
}

class TaskDetailsPageState extends State<TaskDetailsPage>
    with TickerProviderStateMixin {
  Task _task;
  List<Tab> tabs;
  TabController tabController;

  TaskDetailsPageState(this._task) : assert(_task != null);

  @override
  void initState() {
    tabs = <Tab>[
      Tab(icon: Icon(Icons.info)), // general info
      Tab(icon: Icon(Icons.import_export)), // transfer
      Tab(icon: Icon(Icons.dns)), // trackers
      Tab(icon: Icon(Icons.people)), // peers
      Tab(icon: Icon(Icons.folder)), // files
    ];

    tabController = TabController(
      vsync: this,
      length: tabs.length,
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_task.title),
        bottom:
            TabBar(isScrollable: false, tabs: tabs, controller: tabController),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          GeneralTaskInfoTab(_task),
          TransferInfoTab(_task),
          Text('Trackers'),
          Text('Peers'),
          Text('Files'),
        ],
      ),
    );
  }
}
