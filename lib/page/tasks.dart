import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:morpheus/morpheus.dart';
import 'package:synodownloadstation/bloc/connection_bloc.dart' as cBloc;
import 'package:synodownloadstation/bloc/syno_api_bloc.dart';
import 'package:synodownloadstation/bloc/ui_evt_bloc.dart';
import 'package:synodownloadstation/model/model.dart';
import 'package:synodownloadstation/page/task_tab.dart';
import 'package:synodownloadstation/syno/api/modeled/model.dart';
import 'package:synodownloadstation/util/const.dart';
import 'package:synodownloadstation/util/extension.dart';
import 'package:synodownloadstation/util/format.dart';
import 'package:uuid/uuid.dart';

class TaskList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _TaskListState();
}

class _TaskListState extends State<TaskList>
    with SingleTickerProviderStateMixin {
  ListTaskInfo futureTaskInfo = null;
  Connection _connection;
  var filter = '';
  bool _fetching = false;
  TextTheme textTheme;
  AnimationController _pgsBarAnimController;
  Animation<Color> _pgsBarAnim;
  List<GlobalKey> _cardKeys = [];
  List<StreamSubscription> _subscriptions = [];

  @override
  void dispose() {
    _subscriptions.forEach((e) => e.cancel());
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // animate color progress bar color
    _pgsBarAnimController = AnimationController(
        duration: Duration(milliseconds: FETCH_INTERVAL_MS), vsync: this)
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
    var apiBloc = BlocProvider.of<SynoApiBloc>(context);

    _subscriptions.add(
        Stream.periodic(Duration(milliseconds: FETCH_INTERVAL_MS))
            .listen((event) async {
      if (_connection == null || _fetching) return;

      _fetching = true;
      uiBloc.add(UiEventState.noPayload(this, UiEvent.task_fetching));
      apiBloc.add(SynoApiEvent.params(RequestType.task_list, {
        'additional': ['transfer']
      }));
    }));

    apiBloc.listen((state) {
      if (state.event != null &&
          state.event.requestType == RequestType.task_list) {
        APIResponse<ListTaskInfo> info = state.resp;

        if (mounted && info.success) {
          setState(() {
            futureTaskInfo = info.data;
          });
          BlocProvider.of<UiEventBloc>(context).add(UiEventState(
              null, UiEvent.tasks_fetched, [DateTime.now(), info.data]));
        }
        _fetching = false;
      }
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
        if (mounted) {
          setState(() {
            _connection = state.activeConnection;
          });
        }
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
          return Text('Empty...', style: TextStyle(color: Colors.grey),);
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

            String remainingTime;
            if (task.status == TaskStatus.downloading) {
              var remainingSeconds =
                  (task.size - task.additional?.transfer?.sizeDownloaded) /
                      task.additional?.transfer?.speedDownload;
              remainingSeconds =
                  remainingSeconds.isFinite ? remainingSeconds : 0;
              remainingTime =
                  humanifySeconds(remainingSeconds?.round(), maxUnits: 1);
            }

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
                            ' | $downloaded of $totalSize' +
                            (remainingTime == null
                                ? ''
                                : ' | ~$remainingTime')),
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
      case TaskStatus.paused:
        icon = Icon(Icons.pause);
        break;
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
  bool _fetching = false;
  String _fetchingId;
  Uuid _uuid;
  List<StreamSubscription> _subscriptions = [];

  TaskDetailsPageState(this._task) : assert(_task != null);

  @override
  void dispose() {
    _subscriptions.forEach((e) => e.cancel());
    super.dispose();
  }

  @override
  void initState() {
    var apiBloc = BlocProvider.of<SynoApiBloc>(context);
    _uuid = Uuid();

    tabs = <Tab>[
      Tab(icon: Icon(Icons.info)), // general info
      Tab(icon: Icon(Icons.import_export)), // transfer
      Tab(icon: Icon(Icons.dns)), // trackers
      Tab(icon: Icon(Icons.people)), // peers
      Tab(icon: Icon(Icons.folder)), // files
    ];

    _fetchingId = _uuid.v4();
    apiBloc.add(SynoApiEvent.params(RequestType.task_info, {
      'ids': [_task.id],
      '_fetchingId': _fetchingId
    }));

    _subscriptions.add(
        Stream.periodic(Duration(milliseconds: FETCH_INTERVAL_MS))
            .listen((event) {
      if (!_fetching) {
        _fetchingId = _uuid.v4();
        apiBloc.add(SynoApiEvent.params(RequestType.task_info, {
          'ids': [_task.id],
          '_fetchingId': _fetchingId
        }));
      }
    }));

    apiBloc.listen((state) {
      if (state.event.requestType == RequestType.task_info &&
          (state.event.params ?? {})['_fetchingId'] == _fetchingId) {
        _fetching = false;

        List<Task> tasks = state.resp.data ?? [];
        List<String> ids = tasks.map((e) => e.id).toList();
        if (ids == null || !ids.contains(_task.id)) {
          if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
          return;
        }

        Task task =
            tasks.firstWhere((t) => t.id == _task.id, orElse: () => null);

        if (task != null && mounted) {
          setState(() {
            _task = task;
          });
        }
      }
    });

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
          TrackerInfoTab(_task),
          PeerInfoTab(_task),
          FileInfoTab(_task),
        ],
      ),
    );
  }
}
