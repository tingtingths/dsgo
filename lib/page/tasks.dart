import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:synodownloadstation/bloc/connection_bloc.dart' as cBloc;
import 'package:synodownloadstation/bloc/ui_evt_bloc.dart';
import 'package:synodownloadstation/event/streams.dart';
import 'package:synodownloadstation/model/model.dart';
import 'package:synodownloadstation/syno/api/context.dart';
import 'package:synodownloadstation/syno/api/modeled/downloadstation.dart';
import 'package:synodownloadstation/syno/api/modeled/model.dart';
import 'package:synodownloadstation/util/const.dart';
import 'package:synodownloadstation/util/format.dart';

class TasksPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _TaskPageState();
}

enum TaskShows { ALL, Downloading }

class _TaskPageState extends State<TasksPage>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  Animation _colorTween;
  var _noborder = OutlineInputBorder(borderSide: BorderSide.none);
  var _taskDisplay = TaskShows.ALL;
  var _fetchDatetime = '?';
  UiEventBloc uiBloc;

  _TaskPageState();

  _TaskPageState.shows(this._taskDisplay);

  @override
  void initState() {
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 1000));
    _colorTween = ColorTween(begin: Colors.green, end: Colors.green.withOpacity(0))
        .animate(_animationController);

    uiBloc = BlocProvider.of<UiEventBloc>(context);
    uiBloc.listen((state) {
      if (state.name == 'tasks_fetched') {
        print('tasks_fetched');
        _animationController.forward(from: 0.0).orCancel;
        var dt = state.payload[0] as DateTime;
        setState(() {
          _fetchDatetime = dt.toString();
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _animationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              border: _noborder,
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).accentColor)),
            ),
            onChanged: (val) {
              uiBloc.add(UiEventState(this, 'filter_task', [val]));
            },
          ),
        ),
        Divider(),
        AnimatedBuilder(
          animation: _colorTween,
          builder: (context, child) => Container(
            color: _colorTween.value,
            child: Text(_fetchDatetime),
          ),
        ),
        TaskList(),
      ],
    );
  }
}

class TaskList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  ListTaskInfo futureTaskInfo = null;
  Stream fetchStream;
  Connection _connection;
  var filter = '';
  bool _fetching = false;

  @override
  void initState() {
    super.initState();

    fetchStream = Stream.periodic(Duration(seconds: 1));
    fetchStream.listen((event) async {
      if (_connection == null || _fetching) return;

      _fetching = true;
      var fetched = await fetchTaskInfo(_connection);
      if (mounted) {
        setState(() {
          futureTaskInfo = fetched;
        });
        BlocProvider.of<UiEventBloc>(context)
            .add(UiEventState(null, 'tasks_fetched', [DateTime.now()]));
      }
      _fetching = false;
    });

    StreamManager()
        .stream<Connection>(StreamKey.ActiveConnectionChange.key,
            defaultController: StreamController<Connection>.broadcast())
        .listen((conn) {
      if (conn != null) print('Got conn: ' + conn.buildUri());
      if (mounted) {
        setState(() {
          _connection = conn;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<UiEventBloc>(context).listen((state) {
      if (state.name == 'filter_task') {
        var filterStr = state.payload.join();
        setState(() {
          filter = filterStr;
        });
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
          return Expanded(child: Center(child: CircularProgressIndicator()));
        }

        if (info.total == 0) {
          return Text('No tasks');
        }

        return Expanded(
          child: ListView.builder(
              itemCount: info.total,
              itemBuilder: (cntx, idx) {
                var task = info.tasks[idx];

                if (filter != null && filter.trim().isNotEmpty) {
                  if (!task.title
                      .toUpperCase()
                      .contains(filter.toUpperCase())) {
                    return null;
                  }
                }

                var totalSize = humanifySize(task.size);
                var downloaded =
                    humanifySize(task.additional?.transfer?.sizeDownloaded);
                var progress =
                    (task.additional?.transfer?.sizeDownloaded ?? 0) /
                        task.size;
                progress = progress.isFinite ? progress : 0;
                var downSpeed = humanifySize(
                        task.additional?.transfer?.speedDownload ?? 0,
                        p: 0) +
                    '/s';
                var upSpeed = humanifySize(
                        task.additional?.transfer?.speedUpload ?? 0,
                        p: 0) +
                    '/s';

                return Card(
                    elevation: 5,
                    margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
                    child: Column(
                      children: <Widget>[
                        ListTile(
                            title: Text(
                              task.title,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  '${task.status.toUpperCase()} | $downloaded of $totalSize | ${fmtNum(progress * 100, p: 0)}%',
                                ),
                                Text('DL $downSpeed | UP $upSpeed'),
                              ],
                            )),
                        Container(
                            child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            IconButton(
                                icon: Icon(Icons.play_arrow), onPressed: () {}),
                            IconButton(
                                icon: Icon(Icons.pause), onPressed: () {}),
                            IconButton(
                                icon: Icon(Icons.delete), onPressed: () {}),
                            IconButton(
                                icon: Icon(Icons.edit), onPressed: () {}),
                          ],
                        )),
                        LinearProgressIndicator(
                          backgroundColor: Colors.white,
                          value: progress,
                        ),
                      ],
                    ));
              }),
        );
      },
    );
  }
}

Future<ListTaskInfo> fetchTaskInfo(Connection conn) async {
  print('fetch');
  var cntx = APIContext(conn.host, proto: conn.proto, port: conn.port);

  if (!cntx.appSid.containsKey('DownloadStation') ||
      cntx.appSid['DownloadStation'] == null) {
    await cntx.authApp('DownloadStation', conn.user, conn.password);
  }
  var dsApi = DownloadStationAPI(cntx);

  return dsApi.taskList().then((value) => value.data);
}
