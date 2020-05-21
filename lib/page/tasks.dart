import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:synodownloadstation/bloc/connection_bloc.dart' as cBloc;
import 'package:synodownloadstation/bloc/ui_evt_bloc.dart';
import 'package:synodownloadstation/model/model.dart';
import 'package:synodownloadstation/syno/api/context.dart';
import 'package:synodownloadstation/syno/api/modeled/downloadstation.dart';
import 'package:synodownloadstation/syno/api/modeled/model.dart';
import 'package:synodownloadstation/util/format.dart';

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
            .add(UiEventState(null, UiEvent.tasks_fetched, [DateTime.now()]));
      }
      _fetching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
          itemCount: info.total * 2,
          itemBuilder: (cntx, idx) {
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

            return Card(
              elevation: 5,
              margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                children: <Widget>[
                  ListTile(
                    //contentPadding: EdgeInsets.fromLTRB(5, 5, 5, 5),
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
                        Text(
                          '${task.status.toUpperCase()} | $downloaded of $totalSize | ${fmtNum(progress * 100, p: 0)}%',
                        ),
                        Text('DL $downSpeed | UP $upSpeed'),
                      ],
                    ),
                  ),
                  LinearProgressIndicator(
                    backgroundColor: Colors.white,
                    value: progress,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

Future<ListTaskInfo> fetchTaskInfo(Connection conn) async {
  var cntx = APIContext(conn.host, proto: conn.proto, port: conn.port);

  if (!cntx.appSid.containsKey('DownloadStation') ||
      cntx.appSid['DownloadStation'] == null) {
    await cntx.authApp('DownloadStation', conn.user, conn.password);
  }
  var dsApi = DownloadStationAPI(cntx);

  return dsApi.taskList().then((value) => value.data);
}
