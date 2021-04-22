import 'dart:async';

import 'package:animations/animations.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:synoapi/synoapi.dart';

import '../main.dart';
import '../model/model.dart';
import '../page/task_details.dart';
import '../util/format.dart';
import '../util/utils.dart';

class TaskList extends ConsumerWidget {
  final UserSettings settings;
  final List<GlobalKey> _cardKeys = [];
  final pendingRemove = [];
  Timer? pendingRemoveCountdown;

  TaskList(this.settings);

  @override
  Widget build(BuildContext context, watch) {
    final l10n = AppLocalizations.of(context)!;
    var textTheme = Theme.of(context).textTheme;
    var tasksInfo = watch(tasksInfoProvider).state;
    var searchText = watch(searchTextProvider).state;
    var api = watch(dsAPIProvider);

    if (api == null) {
      return SliverFillRemaining(
        child: Center(
          child: Text(''),
        ),
      );
    }
    if (tasksInfo == null) {
      return SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
    }

    var count = tasksInfo.tasks.length;
    var tasks = List<Task>.from(tasksInfo.tasks);
    pendingRemove.forEach((pendingRemove) {
      var found = tasks.firstWhereOrNull((task) => task.id == pendingRemove.id);
      if (found == null) return;

      count -= 1;
      tasks.remove(found);
    });

    if (count == 0) {
      return SliverFillRemaining(child: Center(child: Text(l10n.placeholderText)));
    }

    return SliverList(
        delegate: SliverChildBuilderDelegate((context, idx) {
      if (_cardKeys.length <= idx) _cardKeys.add(GlobalKey());

      var task = tasks[idx];

      if (searchText.trim().isNotEmpty) {
        var sanitizedTitle = task.title!.replaceAll(RegExp(r'[^\w+]'), '').toUpperCase();
        var sanitizedMatcher = searchText.replaceAll(RegExp(r'[^\w+]'), '').toUpperCase();
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
        if (TaskStatus.downloading == task.status) {
          // pause it
          api.task.pause([task.id!]);
          var tasksInfo = context.read(tasksInfoProvider).state;
          tasksInfo!.tasks.where((t) => t.id == task.id).first.status = TaskStatus.paused;
          context.read(tasksInfoProvider).state = tasksInfo;
        } else if (TaskStatus.paused == task.status) {
          // resume it
          api.task.resume([task.id!]);
          var tasksInfo = context.read(tasksInfoProvider).state;
          tasksInfo!.tasks.where((t) => t.id == task.id).first.status = TaskStatus.waiting;
          context.read(tasksInfoProvider).state = tasksInfo;
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
            OpenContainer(
                closedColor: Colors.transparent,
                closedElevation: 0,
                transitionDuration: Duration(milliseconds: 400),
                onClosed: (Map<String, String>? result) {
                  if (result == null) return;
                  if (result['action'] == 'remove') {
                    removeTaskFromModel(context, result['taskId']);
                  }
                },
                closedBuilder: (context, action) {
                  return ListTile(
                    dense: false,
                    leading: statusIcon,
                    contentPadding: EdgeInsets.fromLTRB(5, 5, 5, 5),
                    onTap: action,
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
                            ? '${taskStatusNameLocalized(task.status!, l10n)}'
                            : '$progressText% | ${taskStatusNameLocalized(task.status!, l10n)}' +
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
                  );
                },
                openBuilder: (context, CloseContainerActionCallback<Map<String, String>?> action) {
                  return TaskDetailsPage(task, settings);
                }),
            progressBar,
          ],
        ),
        onDismissed: (direction) {
          removeTaskFromModel(context, task.id);
        },
      );
    }, childCount: count));
  }

  void removeTaskFromModel(BuildContext context, String? taskId) {
    final l10n = AppLocalizations.of(context)!;
    var taskInfo = context.read(tasksInfoProvider).state;
    var found = taskInfo!.tasks.firstWhereOrNull((t) => t.id == taskId);

    if (found != null) {
      pendingRemove.add(found);
      var confirmDuration = Duration(seconds: 4);

      var api = context.read(dsAPIProvider)!;
      pendingRemoveCountdown?.cancel(); // reset timer
      pendingRemoveCountdown = Timer(confirmDuration, () {
        var ids = pendingRemove.map((task) => task.id!).map((e) => e.toString()).toList();
        api.task.delete(ids, false);
        pendingRemove.clear();
      });

      taskInfo.tasks.remove(found);
      taskInfo.total -= 1;
      context.read(tasksInfoProvider).state = taskInfo;

      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          buildSnackBar(
            '${l10n.nTaskRemoved(pendingRemove.length)}',
            duration: confirmDuration,
            showProgressIndicator: false,
            action: SnackBarAction(
              label: l10n.undo,
              onPressed: () {
                pendingRemoveCountdown?.cancel();
                pendingRemoveCountdown = null;
                pendingRemove.clear();
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
