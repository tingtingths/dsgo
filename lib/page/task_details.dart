import 'dart:async';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:dsgo/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:synoapi/synoapi.dart';

import '../model/model.dart';
import '../util/extension.dart';
import '../util/format.dart';
import '../util/utils.dart';

final DateFormat _dtFmt = DateFormat.yMd().add_jm();

class TaskDetailsPage extends ConsumerStatefulWidget {
  final Task task;
  final UserSettings settings;

  TaskDetailsPage(this.task, this.settings);

  @override
  ConsumerState<TaskDetailsPage> createState() => TaskDetailsPageState(task, settings);
}

class TaskDetailsPageState extends ConsumerState<TaskDetailsPage> with TickerProviderStateMixin {
  Task _task;
  late List<Tab> tabs;
  TabController? tabController;
  bool _fetching = false;
  List<StreamSubscription> _subs = [];
  UserSettings settings;
  late final StateProvider<Task> taskProvider;

  TaskDetailsPageState(this._task, this.settings);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _subs.forEach((e) => e.cancel());
    super.dispose();
  }

  @override
  void initState() {
    tabs = <Tab>[
      Tab(icon: Icon(Icons.info)), // general info
      Tab(icon: Icon(Icons.import_export)), // transfer
      Tab(icon: Icon(Icons.dns)), // trackers
      Tab(icon: Icon(Icons.people)), // peers
      Tab(icon: Icon(Icons.folder)), // files
    ];

    taskProvider = StateProvider<Task>((ref) => _task);

    _subs.add(Stream.periodic(Duration(milliseconds: settings.apiRequestFrequency)).listen((event) {
      if (!_fetching) {
        var api = ref.read(dsAPIProvider)!;
        var task = ref.read(taskProvider.state).state;
        api.task.getInfo([task.id!]).then((resp) {
          _fetching = false;
          if (!resp.success) return;
          List<Task> tasks = resp.data ?? [];
          List<String?> ids = tasks.map((e) => e.id).toList();

          if (!ids.contains(_task.id)) {
            if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
            return;
          }

          Task? task = tasks.firstWhereOrNull((t) => t.id == _task.id);
          if (task == null) {
            if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
            return;
          } else {
            ref.read(taskProvider.state).state = task;
          }
        }, onError: (err, stack) {
          l.warning('task.getInfo failed', err, stack);
          _fetching = false;
        });
      }
    }));

    tabController = TabController(
      vsync: this,
      length: tabs.length,
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_task.title!),
        bottom: TabBar(isScrollable: false, tabs: tabs, controller: tabController),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          GeneralTaskInfoTab(taskProvider),
          TransferInfoTab(taskProvider),
          TrackerInfoTab(taskProvider),
          PeerInfoTab(taskProvider),
          FileInfoTab(taskProvider),
        ],
      ),
    );
  }
}

class GeneralTaskInfoTab extends ConsumerWidget {
  late final StateProvider<Task> taskProvider;

  GeneralTaskInfoTab(this.taskProvider);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    var task = ref.watch(taskProvider.state).state;
    var api = ref.read(dsAPIProvider)!;
    Widget playPauseBtn = _buildCircleIconBtn(Icon(Icons.play_arrow));

    if (task.status == TaskStatus.downloading) {
      playPauseBtn = _buildCircleIconBtn(Icon(Icons.pause), fillColor: Colors.amber, onPressed: () {
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(buildSnackBar(l10n.pausing));
        api.task.pause([task.id!]).then((resp) {
          ref.read(taskProvider.state).state..status = TaskStatus.paused;
        });
      });
    }
    if (task.status == TaskStatus.paused) {
      playPauseBtn = _buildCircleIconBtn(Icon(Icons.play_arrow), fillColor: Colors.green, onPressed: () {
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(buildSnackBar(l10n.resuming));
        api.task.resume([task.id!]).then((resp) {
          ref.read(taskProvider.state).state..status = TaskStatus.downloading;
        });
      });
    }

    List<Widget> actionBtns = [
      playPauseBtn,
      _buildCircleIconBtn(Icon(Icons.delete), fillColor: Colors.red, onPressed: () {
        Navigator.of(context).pop({'action': 'remove', 'taskId': task.id!});
      })
    ];

    return Column(
      children: [
        // action buttons
        Padding(
          padding: EdgeInsets.fromLTRB(0, 15, 0, 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: actionBtns,
          ),
        ),
        Divider(
          height: 0,
        ),
        Expanded(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                onTap: () => copyToClipboard(task.title, context),
                title: Text(task.title ?? UNKNOWN),
                subtitle: Text(l10n.taskDetailsTitleSubtitle),
              ),
              ListTile(
                title: Text(taskStatusNameLocalized(task.status!, l10n)),
                subtitle: Text(l10n.taskDetailsStatusSubtitle),
              ),
              ListTile(
                onTap: () => copyToClipboard(task.additional?.detail?.destination, context),
                title: Text(task.additional?.detail?.destination ?? UNKNOWN),
                subtitle: Text(l10n.taskDetailsDestinationSubtitle),
              ),
              ListTile(
                title: Text(humanifySize(task.size)),
                subtitle: Text(l10n.taskDetailsSizeSubtitle),
              ),
              ListTile(
                onTap: () => copyToClipboard(task.username, context),
                title: Text(task.username ?? UNKNOWN),
                subtitle: Text(l10n.taskDetailsOwnerSubtitle),
              ),
              ListTile(
                onTap: () => copyToClipboard(task.additional?.detail?.uri, context),
                title: Text(task.additional?.detail?.uri ?? UNKNOWN),
                subtitle: Text(l10n.taskDetailsURLSubtitle),
              ),
              ListTile(
                title: Text(task.additional?.detail?.createTime == null
                    ? UNKNOWN
                    : _dtFmt.format(task.additional?.detail?.createTime ?? UNKNOWN as DateTime)),
                subtitle: Text(l10n.taskDetailsCreatedTimeSubtitle),
              ),
              ListTile(
                title: Text(task.additional?.detail?.completedTime == null
                    ? UNKNOWN
                    : _dtFmt.format(task.additional?.detail?.completedTime ?? UNKNOWN as DateTime)),
                subtitle: Text(l10n.taskDetailsCompletedTimeSubtitle),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCircleIconBtn(Icon icon, {Color fillColor: Colors.grey, double size: 24.0, Function? onPressed}) {
    if (onPressed == null) {
      fillColor = Colors.grey.withOpacity(0.6);
    }

    return Ink(
      decoration: ShapeDecoration(
        color: fillColor,
        shape: CircleBorder(),
      ),
      child: IconButton(
        color: Colors.white,
        disabledColor: Colors.white,
        icon: icon,
        iconSize: size,
        onPressed: onPressed as void Function()?,
      ),
    );
  }
}

class TransferInfoTab extends ConsumerWidget {
  final StateProvider<Task> taskProvider;

  TransferInfoTab(this.taskProvider);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    var task = ref.watch(taskProvider.state).state;
    int? downSize = task.additional?.transfer?.sizeDownloaded;
    int? upSize = task.additional?.transfer?.sizeUploaded;
    double pct = (upSize ?? 0) / (downSize ?? 0) * 100;
    pct = pct.isFinite ? pct : 0;

    var downSpeed = humanifySize(task.additional?.transfer?.speedDownload ?? 0, p: 0);
    var upSpeed = humanifySize(task.additional?.transfer?.speedUpload ?? 0, p: 0);

    var progress = (task.additional?.transfer?.sizeDownloaded ?? 0) / task.size!;
    progress = progress.isFinite ? progress : 0;

    String remainingTime = '-';
    double remainingSeconds;
    if (task.status == TaskStatus.downloading) {
      remainingSeconds = (task.size! - (task.additional?.transfer?.sizeDownloaded ?? 0)) /
          (task.additional?.transfer?.speedDownload ?? 0);
      remainingSeconds = remainingSeconds.isFinite ? remainingSeconds : 0;
      remainingTime = humanifySeconds(remainingSeconds.round(), maxUnits: 2, defaultStr: "-");
    }

    return ListView(
      shrinkWrap: true,
      children: [
        ListTile(
          title: Text('${humanifySize(upSize)}' + ' / ${humanifySize(downSize)}' + ' (${fmtNum(pct)}%)'),
          subtitle: Text(l10n.taskDetailsTransferredSubtitle),
        ),
        ListTile(
          title: Text('${fmtNum(progress * 100)}%'),
          subtitle: Text(l10n.taskDetailsProgressSubtitle),
        ),
        ListTile(
          title: Text('$upSpeed / $downSpeed'),
          subtitle: Text(l10n.taskDetailsSpeedSubtitle),
        ),
        ListTile(
          title: Text('${task.additional?.detail?.totalPeers ?? UNKNOWN}'),
          subtitle: Text(l10n.taskDetailsTotalPeersSubtitle),
        ),
        ListTile(
          title: Text('${task.additional?.detail?.connectedPeers ?? UNKNOWN}'),
          subtitle: Text(l10n.taskDetailsConnectedPeersSubtitle),
        ),
        ListTile(
          title: Text('${task.additional?.transfer?.downloadedPieces ?? 0} / ' +
              '${task.additional?.detail?.totalPieces ?? UNKNOWN}'),
          subtitle: Text(l10n.taskDetailsDownloadedBlocksSubtitle),
        ),
        ListTile(
          title: Text('${humanifySeconds(task.additional?.detail?.seedElapsed, accuracy: 60, defaultStr: "-")}'),
          subtitle: Text(l10n.taskDetailsSeedingDurationSubtitle),
        ),
        ListTile(
          title: Text('${task.additional?.detail?.connectedSeeders} / ${task.additional?.detail?.connectedLeechers}'),
          subtitle: Text(l10n.taskDetailsSeedsAndLeechersSubtitle),
        ),
        ListTile(
          title: Text(task.additional?.detail?.startedTime == null
              ? UNKNOWN
              : '${_dtFmt.format(task.additional!.detail!.startedTime!)}'),
          subtitle: Text(l10n.taskDetailsCreatedTimeSubtitle),
        ),
        ListTile(
          title: Text(remainingTime),
          subtitle: Text(l10n.taskDetailsTimeLeftSubtitle),
        ),
      ],
    );
  }
}

class TrackerInfoTab extends ConsumerWidget {
  final StateProvider<Task> taskProvider;

  TrackerInfoTab(this.taskProvider);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    var task = ref.watch(taskProvider.state).state;
    var trackers = task.additional?.tracker ?? [];
    trackers.sort((x, y) => x.url!.compareTo(y.url!));

    if (trackers.isEmpty) {
      return Center(
        child: Text(
          l10n.placeholderText,
        ),
      );
    }

    return ListView.builder(
      addAutomaticKeepAlives: true,
      shrinkWrap: true,
      itemCount: trackers.length,
      itemBuilder: (context, idx) {
        var tracker = trackers[idx];

        return Card(
            elevation: 3,
            child: Stack(
              alignment: AlignmentDirectional.topEnd,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(0, 5, 5, 0),
                  child: Text(
                    '#${idx + 1}/${trackers.length}',
                    style: TextStyle(color: Theme.of(context).colorScheme.secondary.withOpacity(1)),
                  ),
                ),
                Column(
                  children: [
                    ListTile(
                      onTap: () => copyToClipboard(tracker.url, context),
                      title: Text(tracker.url!),
                      subtitle: Text(l10n.taskDetailsTrackerUrl),
                    ),
                    ListTile(
                      title: Text(tracker.status!.isEmpty ? UNKNOWN : tracker.status!),
                      subtitle: Text(l10n.taskDetailsTrackerStatus),
                    ),
                    ListTile(
                      title: Text(humanifySeconds(tracker.updateTimer, maxUnits: 2)),
                      subtitle: Text(l10n.taskDetailsTrackerNextUpdate),
                    ),
                    ListTile(
                      title: Text(
                          '${tracker.seeds == -1 ? 0 : tracker.seeds} / ${tracker.peers == -1 ? 0 : tracker.peers}'),
                      subtitle: Text(l10n.taskDetailsTrackerSeedsAndPeers),
                    )
                  ],
                ),
              ],
            ));
      },
    );
  }
}

class PeerInfoTab extends ConsumerWidget {
  final StateProvider<Task> taskProvider;

  PeerInfoTab(this.taskProvider);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    var task = ref.watch(taskProvider.state).state;
    var peer = task.additional?.peer ?? [];
    peer.sort((x, y) => x.address!.compareTo(y.address!));

    if (peer.isEmpty) {
      return Center(
        child: Text(
          l10n.placeholderText,
        ),
      );
    }

    return ListView.builder(
      addAutomaticKeepAlives: true,
      shrinkWrap: true,
      itemCount: peer.length,
      itemBuilder: (context, idx) {
        var p = peer[idx];

        return Card(
            elevation: 3,
            child: Stack(
              alignment: AlignmentDirectional.topEnd,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(0, 5, 5, 0),
                  child: Text(
                    '#${idx + 1}/${peer.length}',
                    style: TextStyle(color: Theme.of(context).colorScheme.secondary.withOpacity(1)),
                  ),
                ),
                Column(
                  children: [
                    ListTile(
                      onTap: () => copyToClipboard(p.address, context),
                      title: Text(p.address!),
                      subtitle: Text(l10n.taskDetailsPeerIPAddress),
                    ),
                    ListTile(
                      onTap: () => copyToClipboard(p.agent, context),
                      title: Text(p.agent!),
                      subtitle: Text(l10n.taskDetailsPeerAgent),
                    ),
                    ListTile(
                      title: Text('${fmtNum(p.progress!)}% ' +
                          '| ${humanifySize(p.speedUpload, p: 0)} ' +
                          '/ ${humanifySize(p.speedDownload, p: 0)}'),
                      subtitle: Text(l10n.taskDetailsPeerProgressAndSpeed),
                    )
                  ],
                ),
              ],
            ));
      },
    );
  }
}

class FileInfoTab extends ConsumerWidget {
  final StateProvider<Task> taskProvider;

  FileInfoTab(this.taskProvider);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    var task = ref.watch(taskProvider.state).state;
    var files = task.additional?.file ?? [];
    files.sort((x, y) => x.filename!.compareTo(y.filename!));

    if (files.isEmpty) {
      return Center(
        child: Text(
          l10n.placeholderText,
        ),
      );
    }

    return ListView.builder(
      addAutomaticKeepAlives: true,
      shrinkWrap: true,
      itemCount: files.length,
      itemBuilder: (context, idx) {
        var f = files[idx];

        var progress = f.sizeDownloaded! / f.size!;
        progress = progress.isFinite ? progress * 100 : 0;

        return Card(
            elevation: 3,
            child: Stack(
              alignment: AlignmentDirectional.topEnd,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(0, 5, 5, 0),
                  child: Text(
                    '#${idx + 1}/${files.length}',
                    style: TextStyle(color: Theme.of(context).colorScheme.secondary.withOpacity(1)),
                  ),
                ),
                Column(
                  children: [
                    ListTile(
                      onTap: () => copyToClipboard(f.filename, context),
                      title: Text(f.filename!),
                      subtitle: Text(l10n.taskDetailsFilename),
                    ),
                    ListTile(
                      title: Text('${fmtNum(progress, p: 1)}% | ' +
                          '${humanifySize(f.sizeDownloaded)} ' +
                          '/ ${humanifySize(f.size)}'),
                      subtitle: Text(l10n.taskDetailsFileDownloaded),
                    ),
                    ListTile(
                      title: Text('${f.priority!.capitalize()}'),
                      subtitle: Text(l10n.taskDetailsFilePriority),
                    ),
                  ],
                ),
              ],
            ));
      },
    );
  }
}
