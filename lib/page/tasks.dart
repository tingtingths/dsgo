import 'dart:async';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:morpheus/morpheus.dart';
import 'package:synoapi/synoapi.dart';

import '../bloc/connection_bloc.dart';
import '../bloc/syno_api_bloc.dart';
import '../bloc/ui_evt_bloc.dart';
import '../model/model.dart';
import '../page/task_details.dart';
import '../util/const.dart';
import '../util/extension.dart';
import '../util/format.dart';
import '../util/utils.dart';

class TaskList extends StatefulWidget {
  UserSettings? settings;

  TaskList(this.settings);

  @override
  State<StatefulWidget> createState() => _TaskListState(settings);
}

class _TaskListState extends State<TaskList> with SingleTickerProviderStateMixin {
  ListTaskInfo? taskInfo;
  var filter = '';
  late TextTheme textTheme;
  List<GlobalKey> _cardKeys = [];
  Map<String, StreamSubscription> _subscriptions = {};
  late SynoApiBloc apiBloc;
  late UiEventBloc uiBloc;
  List<Task> pendingRemove = [];
  Timer? pendingRemoveCountdown;
  static const String fetchingStreamKey = 'STREAM_FETCH';
  UserSettings? settings;

  _TaskListState(this.settings);

  @override
  void dispose() {
    _subscriptions.values.forEach((e) => e.cancel());
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    uiBloc = BlocProvider.of<UiEventBloc>(context);
    apiBloc = BlocProvider.of<SynoApiBloc>(context);

    _subscriptions[fetchingStreamKey] =
        Stream.periodic(Duration(milliseconds: settings!.apiRequestFrequency!)).listen((event) async {
      uiBloc.add(UiEventState.noPayload(this, UiEvent.task_fetching));
      apiBloc.add(SynoApiEvent.params(RequestType.task_list, {
        'additional': ['transfer']
      }));
    });

    apiBloc.stream.listen((state) {
      if (state.event != null && state.event!.requestType == RequestType.task_list) {
        APIResponse<ListTaskInfo>? info = state.resp as APIResponse<ListTaskInfo>?;
        if (info == null) return;

        if (mounted && info.success) {
          setState(() {
            taskInfo = info.data;
          });
          BlocProvider.of<UiEventBloc>(context)
              .add(UiEventState(null, UiEvent.tasks_fetched, [DateTime.now(), info.data]));
        }
      }

      if (state.event != null && state.event!.requestType == RequestType.remove_task) {
        pendingRemove.removeWhere((task) => state.event!.params['ids'].contains(task.id));
      }
    });

    BlocProvider.of<UiEventBloc>(context).stream.listen((state) {
      if (state.event == UiEvent.tasks_filter_change) {
        var filterStr = state.payload.join();
        if (mounted) {
          setState(() {
            filter = filterStr;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    textTheme = Theme.of(context).textTheme;
    var info = taskInfo;

    if (!apiBloc.isReady()) {
      return SliverFillRemaining(child: Center(child: Text('...')));
    }

    if (info == null) {
      return SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
    }

    var count = info.tasks.length;
    var tasks = List<Task>.from(info.tasks);
    pendingRemove.forEach((pendingRemove) {
      var found = tasks.firstWhereOrNull((task) => task.id == pendingRemove.id);
      if (found == null) return;

      count -= 1;
      tasks.remove(found);
    });

    if (info.total == 0) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            TXT_NOTHING,
          ),
        ),
      );
    }

    return SliverList(
        delegate: SliverChildBuilderDelegate((context, idx) {
      if (_cardKeys.length <= idx) _cardKeys.add(GlobalKey());

      var task = tasks[idx];

      if (filter.trim().isNotEmpty) {
        var sanitizedTitle = task.title!.replaceAll(RegExp(r'[^\w+]'), '').toUpperCase();
        var sanitizedMatcher = filter.replaceAll(RegExp(r'[^\w+]'), '').toUpperCase();
        if (!sanitizedTitle.contains(sanitizedMatcher)) {
          return SizedBox.shrink();
        }
      }

      var totalSize = humanifySize(task.size);
      var downloaded = humanifySize(task.additional?.transfer?.sizeDownloaded);
      var progress = (task.additional?.transfer?.sizeDownloaded ?? 0) / task.size!;
      progress = progress.isFinite ? progress : 0;
      var downSpeed = humanifySize(task.additional?.transfer?.speedDownload ?? 0, p: 0) + '/s';
      var upSpeed = humanifySize(task.additional?.transfer?.speedUpload ?? 0, p: 0) + '/s';
      var progressText = fmtNum(progress * 100, p: 0);

      String? remainingTime;
      if (task.status == TaskStatus.downloading) {
        var remainingSeconds = (task.size! - (task.additional?.transfer?.sizeDownloaded ?? 0)) /
            (task.additional?.transfer?.speedDownload ?? 0);
        remainingSeconds = remainingSeconds.isFinite ? remainingSeconds : 0;
        remainingTime = humanifySeconds(remainingSeconds.round(), maxUnits: 1);
      }

      var progressBar = LinearProgressIndicator(
        backgroundColor: Theme.of(context).backgroundColor,
        value: progress,
      );

      var statusIcon = _getStatusIcon(task.status, () {
        var params = {
          'ids': [task.id]
        };
        /*
        i.e.
          Downloading -> Pause
          Pause -> Downloading
          ..etc?
         */
        if (TaskStatus.downloading == task.status) {
          // pause it
          apiBloc.add(SynoApiEvent.params(RequestType.pause_task, params));
          setState(() {
            task.status = TaskStatus.paused;
          });
        } else if (TaskStatus.paused == task.status) {
          // resume it
          apiBloc.add(SynoApiEvent.params(RequestType.resume_task, params));
          setState(() {
            task.status = TaskStatus.waiting;
          });
        }
      }, onLongPress: () {
        // TODO : trigger multiple selection here
      });

      return Dismissible(
        direction: DismissDirection.horizontal,
        key: ValueKey(task.id),
        background: Container(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.fromLTRB(15, 0, 0, 0),
          color: Colors.red,
          child: Icon(
            Icons.delete_forever,
            size: Theme.of(context).iconTheme.size ?? 42,
          ),
        ),
        secondaryBackground: Container(
          margin: EdgeInsets.zero,
          alignment: Alignment.centerRight,
          padding: EdgeInsets.fromLTRB(0, 0, 15, 0),
          color: Colors.red,
          child: Icon(
            Icons.delete_forever,
            size: Theme.of(context).iconTheme.size ?? 42,
          ),
        ),
        child: Column(
          key: _cardKeys[idx],
          children: <Widget>[
            Divider(
              indent: 15,
              endIndent: 15,
            ),
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
                            value: BlocProvider.of<DSConnectionBloc>(context),
                            child: TaskDetailsPage(task, settings),
                          );
                        })).then((result) {
                  result = (result ?? {});
                  if (result['requestType'] == RequestType.remove_task && result['taskId'] != null) {
                    removeTaskFromModel(result['taskId']);
                  }
                });
              },
              title: Text(
                task.title ?? '',
                // TODO - fade not working on mobile browser. https://github.com/flutter/flutter/issues/71413
                overflow: kIsWeb ? TextOverflow.ellipsis : TextOverflow.fade,
                softWrap: false,
                style: TextStyle(fontSize: Theme.of(context).textTheme.headline6!.fontSize),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Divider(
                    height: 5,
                  ),
                  Text((['seeding', 'finished'].contains(task.status!.name.toLowerCase())
                      ? '${task.status!.name.capitalize()}'
                      : '$progressText% | ${task.status!.name.capitalize()}' +
                          (remainingTime == null || remainingTime.isEmpty ? '' : ' | ~$remainingTime'))),
                  Text('$downloaded of $totalSize'),
                  Row(
                    children: [
                      Icon(
                        Icons.arrow_downward,
                        size: textTheme.bodyText1!.fontSize,
                      ),
                      Text(downSpeed),
                      Icon(Icons.arrow_upward, size: textTheme.bodyText1!.fontSize),
                      Text(upSpeed),
                    ],
                  )
                ],
              ),
            ),
            progressBar,
          ],
        ),
        onDismissed: (direction) {
          removeTaskFromModel(task.id);
        },
      );
    }, childCount: count));
  }

  void removeTaskFromModel(String? taskId) {
    var found = taskInfo!.tasks.firstWhereOrNull((t) => t.id == taskId);

    if (found != null) {
      setState(() {
        taskInfo!.tasks.remove(found);
        taskInfo!.total -= 1;
      });
      pendingRemove.add(found);
      var confirmDuration = Duration(seconds: 4);

      // reset timer
      if (pendingRemoveCountdown != null) {
        pendingRemoveCountdown!.cancel();
      }
      pendingRemoveCountdown = Timer(confirmDuration, () {
        apiBloc
            .add(SynoApiEvent.params(RequestType.remove_task, {'ids': pendingRemove.map((task) => task.id).toList()}));
      });

      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          buildSnackBar(
            '${pendingRemove.length} Task${pendingRemove.length > 1 ? 's' : ''} removed.',
            duration: confirmDuration,
            showProgressIndicator: false,
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                pendingRemoveCountdown!.cancel();
                pendingRemoveCountdown = null;
                setState(() {
                  pendingRemove.clear();
                });
              },
            ),
          ),
        );
    }
  }

  Widget _getStatusIcon(TaskStatus? status, Function onPressed, {Function? onLongPress}) {
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
      case null:
        break;
    }

    return GestureDetector(
      onTap: onPressed as void Function()?,
      onLongPress: onLongPress as void Function()?,
      child: IconButton(
        iconSize: size,
        icon: icon,
        color: color,
        onPressed: onPressed as void Function()?,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
