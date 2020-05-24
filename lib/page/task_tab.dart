import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:synodownloadstation/bloc/syno_api_bloc.dart';
import 'package:synodownloadstation/syno/api/const.dart';
import 'package:synodownloadstation/syno/api/modeled/model.dart';
import 'package:synodownloadstation/util/extension.dart';
import 'package:synodownloadstation/util/format.dart';
import 'package:synodownloadstation/util/utils.dart';

class GeneralTaskInfoTab extends StatefulWidget {
  Task _task;

  GeneralTaskInfoTab(this._task) : assert(_task != null);

  @override
  State<StatefulWidget> createState() => GeneralTaskInfoTabState(_task);
}

class GeneralTaskInfoTabState extends State<GeneralTaskInfoTab> {
  Task _task;
  DateFormat dtFmt = DateFormat.yMd().add_jm();

  GeneralTaskInfoTabState(this._task) : assert(_task != null);

  @override
  void initState() {
    super.initState();

    var apiBloc = BlocProvider.of<SynoApiBloc>(context);
    apiBloc.listen((state) {
      if (state.event.requestType == RequestType.task_info) {
        List<Task> tasks = state.resp.data ?? [];
        List<String> ids = tasks.map((e) => e.id).toList();
        if (ids == null || !ids.contains(_task.id)) {
          Navigator.of(context).pop();
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
  }

  @override
  Widget build(BuildContext context) {
    if (_task == null) return Text('Null task...');

    Widget playPauseBtn = _buildCircleIconBtn(Icon(Icons.play_arrow));
    if (_task.status == TaskStatus.downloading) {
      playPauseBtn = _buildCircleIconBtn(Icon(Icons.pause),
          fillColor: Colors.amber, onPressed: () {
        // TODO : pause the task
      });
    }
    if (_task.status == TaskStatus.paused) {
      playPauseBtn = _buildCircleIconBtn(Icon(Icons.play_arrow),
          fillColor: Colors.green, onPressed: () {
        // TODO : resume the task
      });
    }

    Widget deleteBtn = _buildCircleIconBtn(Icon(Icons.delete),
        fillColor: Colors.red, onPressed: () {
      // TODO : delete the task
    });

    List<Widget> actionBtns = [playPauseBtn, deleteBtn];

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
                onTap: () =>
                    copyToClipboard(_task.additional?.detail?.uri, context),
                title: Text(_task.title ?? UNKNOWN),
                subtitle: Text('Title'),
              ),
              ListTile(
                title: Text(_task.status.name.capitalize() ?? UNKNOWN),
                subtitle: Text('Status'),
              ),
              ListTile(
                onTap: () =>
                    copyToClipboard(_task.additional?.detail?.uri, context),
                title: Text(_task.additional?.detail?.destination ?? UNKNOWN),
                subtitle: Text('Destination'),
              ),
              ListTile(
                title: Text(humanifySize(_task.size)),
                subtitle: Text('Size'),
              ),
              ListTile(
                onTap: () =>
                    copyToClipboard(_task.additional?.detail?.uri, context),
                title: Text(_task.username ?? UNKNOWN),
                subtitle: Text('Owner'),
              ),
              ListTile(
                onTap: () =>
                    copyToClipboard(_task.additional?.detail?.uri, context),
                title: Text(_task.additional?.detail?.uri ?? UNKNOWN),
                subtitle: Text('URI'),
              ),
              ListTile(
                title: Text(_task.additional?.detail?.createTime == null
                    ? UNKNOWN
                    : dtFmt.format(
                        _task.additional?.detail?.createTime ?? UNKNOWN)),
                subtitle: Text('Created Time'),
              ),
              ListTile(
                title: Text(_task.additional?.detail?.completedTime == null
                    ? UNKNOWN
                    : dtFmt.format(
                        _task.additional?.detail?.completedTime ?? UNKNOWN)),
                subtitle: Text('Completed Time'),
              ),
              ListTile(
                title: Text(
                    _task.additional?.detail?.waitingSeconds?.toString() ??
                        UNKNOWN),
                subtitle: Text('Waiting Seconds'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCircleIconBtn(Icon icon,
      {Color fillColor: Colors.grey, double size: 24.0, Function onPressed}) {
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
        onPressed: onPressed,
      ),
    );
  }
}

class TransferInfoTab extends StatefulWidget {
  Task _task;

  TransferInfoTab(this._task) : assert(_task != null);

  @override
  State<StatefulWidget> createState() => TransferInfoTabState(_task);
}

class TransferInfoTabState extends State<TransferInfoTab> {
  Task _task;
  DateFormat dtFmt = DateFormat.yMMMMd().add_jm();

  TransferInfoTabState(this._task) : assert(_task != null);

  @override
  void initState() {
    super.initState();

    var apiBloc = BlocProvider.of<SynoApiBloc>(context);
    apiBloc.listen((state) {
      if (state.event.requestType == RequestType.task_info) {
        List<Task> tasks = state.resp.data ?? [];
        List<String> ids = tasks.map((e) => e.id).toList();
        if (ids == null || !ids.contains(_task.id)) {
          Navigator.of(context).pop();
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
  }

  @override
  Widget build(BuildContext context) {
    if (_task == null) return Text('Null task...');

    int downSize = _task.additional?.transfer?.sizeDownloaded;
    int upSize = _task.additional?.transfer?.sizeUploaded;
    double pct = (upSize ?? 0) / (downSize ?? 0) * 100;
    pct = pct.isFinite ? pct : 0;

    var downSpeed =
        humanifySize(_task.additional?.transfer?.speedDownload ?? 0, p: 0);
    var upSpeed =
        humanifySize(_task.additional?.transfer?.speedUpload ?? 0, p: 0);

    var progress =
        (_task.additional?.transfer?.sizeDownloaded ?? 0) / _task.size;
    progress = progress.isFinite ? progress : 0;

    String remainingTime = '-';
    double remainingSeconds;
    if (_task.status == TaskStatus.downloading) {
      remainingSeconds =
          (_task.size - _task.additional?.transfer?.sizeDownloaded) /
              _task.additional?.transfer?.speedDownload;
      remainingSeconds = remainingSeconds.isFinite ? remainingSeconds : 0;
      remainingTime = humanifySeconds(remainingSeconds?.round(), maxUnits: 2, defaultStr: "-");
    }

    return ListView(
      shrinkWrap: true,
      children: [
        ListTile(
          title: Text('${humanifySize(upSize)}' +
              ' / ${humanifySize(downSize)}' +
              ' (${fmtNum(pct)}%)'),
          subtitle: Text('Transferred (UL / DL)'),
        ),
        ListTile(
          title: Text('${fmtNum(progress * 100)}%'),
          subtitle: Text('Progress'),
        ),
        ListTile(
          title: Text('$upSpeed / $downSpeed'),
          subtitle: Text('Speed (UL / DL)'),
        ),
        ListTile(
          title: Text('${_task.additional?.detail?.totalPeers ?? UNKNOWN}'),
          subtitle: Text('Total Peers'),
        ),
        ListTile(
          title: Text('${_task.additional?.detail?.connectedPeers ?? UNKNOWN}'),
          subtitle: Text('Connected Peers'),
        ),
        ListTile(
          title: Text(
              '${_task.additional?.transfer?.downloadedPieces ?? 0} / ' +
                  '${_task.additional?.detail?.totalPieces ?? UNKNOWN}'),
          subtitle: Text('Downloaded Blocks'),
        ),
        ListTile(
          title: Text(
              '${humanifySeconds(_task.additional?.detail?.seedElapsed, accuracy: 60, defaultStr: "-")}'),
          subtitle: Text('Seeding Duration'),
        ),
        ListTile(
          title: Text(
              '${_task.additional?.detail?.connectedSeeders} / ${_task.additional?.detail?.connectedLeechers}'),
          subtitle: Text('Seeds / Leechers'),
        ),
        ListTile(
          title: Text(_task.additional?.detail?.startedTime == null
              ? UNKNOWN
              : '${dtFmt.format(_task.additional?.detail?.startedTime)}'),
          subtitle: Text('Started Time'),
        ),
        ListTile(
          title: Text(remainingTime),
          subtitle: Text('Time left'),
        ),
      ],
    );
  }
}

class TrackerInfoTab extends StatefulWidget {
  Task _task;

  TrackerInfoTab(this._task) : assert(_task != null);

  @override
  State<StatefulWidget> createState() => TrackerInfoTabState(_task);
}

class TrackerInfoTabState extends State<TrackerInfoTab> {
  Task _task;
  DateFormat dtFmt = DateFormat.yMMMMd().add_jm();

  TrackerInfoTabState(this._task) : assert(_task != null);

  @override
  void initState() {
    super.initState();

    var apiBloc = BlocProvider.of<SynoApiBloc>(context);
    apiBloc.listen((state) {
      if (state.event.requestType == RequestType.task_info) {
        List<Task> tasks = state.resp.data ?? [];
        List<String> ids = tasks.map((e) => e.id).toList();
        if (ids == null || !ids.contains(_task.id)) {
          Navigator.of(context).pop();
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
  }

  @override
  Widget build(BuildContext context) {
    if (_task == null) return Text('Null task...');

    var trackers = _task.additional?.tracker ?? [];
    trackers.sort((x, y) => x.url.compareTo(y.url));

    if (trackers.isEmpty) {
      return Center(
        child: Text(
          'Nothing...',
          style: TextStyle(color: Colors.grey),
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
                    style: TextStyle(
                        color: Theme.of(context).accentColor.withOpacity(1)),
                  ),
                ),
                Column(
                  children: [
                    ListTile(
                      onTap: () => copyToClipboard(tracker.url, context),
                      title: Text(tracker.url),
                      subtitle: Text('Tracker Url'),
                    ),
                    ListTile(
                      title: Text(tracker.status.isEmpty ? UNKNOWN : tracker.status),
                      subtitle: Text('Status'),
                    ),
                    ListTile(
                      title: Text(
                          humanifySeconds(tracker.updateTimer, maxUnits: 2)),
                      subtitle: Text('Next update'),
                    ),
                    ListTile(
                      title: Text(
                          '${tracker.seeds == -1 ? 0 : tracker.seeds} / ${tracker.peers == -1 ? 0 : tracker.peers}'),
                      subtitle: Text('Seeds / Peers'),
                    )
                  ],
                ),
              ],
            ));
      },
    );
  }
}

class PeerInfoTab extends StatefulWidget {
  Task _task;

  PeerInfoTab(this._task) : assert(_task != null);

  @override
  State<StatefulWidget> createState() => PeerInfoTabState(_task);
}

class PeerInfoTabState extends State<PeerInfoTab> {
  Task _task;
  DateFormat dtFmt = DateFormat.yMMMMd().add_jm();

  PeerInfoTabState(this._task) : assert(_task != null);

  @override
  void initState() {
    super.initState();

    var apiBloc = BlocProvider.of<SynoApiBloc>(context);
    apiBloc.listen((state) {
      if (state.event.requestType == RequestType.task_info) {
        List<Task> tasks = state.resp.data ?? [];
        List<String> ids = tasks.map((e) => e.id).toList();
        if (ids == null || !ids.contains(_task.id)) {
          Navigator.of(context).pop();
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
  }

  @override
  Widget build(BuildContext context) {
    if (_task == null) return Text('Null task...');

    var peer = _task.additional?.peer ?? [];
    peer.sort((x, y) => x.address.compareTo(y.address));

    if (peer.isEmpty) {
      return Center(
        child: Text(
          'Nothing...',
          style: TextStyle(color: Colors.grey),
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
                    style: TextStyle(
                        color: Theme.of(context).accentColor.withOpacity(1)),
                  ),
                ),
                Column(
                  children: [
                    ListTile(
                      onTap: () => copyToClipboard(p.address, context),
                      title: Text(p.address),
                      subtitle: Text('Peer IP Address'),
                    ),
                    ListTile(
                      onTap: () => copyToClipboard(p.agent, context),
                      title: Text(p.agent),
                      subtitle: Text('Agent'),
                    ),
                    ListTile(
                      title: Text('${fmtNum(p.progress)}% ' +
                          '| ${humanifySize(p.speedUpload, p: 0)} ' +
                          '/ ${humanifySize(p.speedDownload, p: 0)}'),
                      subtitle: Text('Progress | Speed (UL / DL)'),
                    )
                  ],
                ),
              ],
            ));
      },
    );
  }
}

class FileInfoTab extends StatefulWidget {
  Task _task;

  FileInfoTab(this._task) : assert(_task != null);

  @override
  State<StatefulWidget> createState() => FileInfoTabState(_task);
}

class FileInfoTabState extends State<FileInfoTab> {
  Task _task;
  DateFormat dtFmt = DateFormat.yMMMMd().add_jm();

  FileInfoTabState(this._task) : assert(_task != null);

  @override
  void initState() {
    super.initState();

    var apiBloc = BlocProvider.of<SynoApiBloc>(context);
    apiBloc.listen((state) {
      if (state.event.requestType == RequestType.task_info) {
        List<Task> tasks = state.resp.data ?? [];
        List<String> ids = tasks.map((e) => e.id).toList();
        if (ids == null || !ids.contains(_task.id)) {
          Navigator.of(context).pop();
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
  }

  @override
  Widget build(BuildContext context) {
    if (_task == null) return Text('Null task...');

    var files = _task.additional?.file ?? [];
    files.sort((x, y) => x.filename.compareTo(y.filename));

    if (files.isEmpty) {
      return Center(
        child: Text(
          'Nothing...',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      addAutomaticKeepAlives: true,
      shrinkWrap: true,
      itemCount: files.length,
      itemBuilder: (context, idx) {
        var f = files[idx];

        var progress = f.sizeDownloaded / f.size;
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
                    style: TextStyle(
                        color: Theme.of(context).accentColor.withOpacity(1)),
                  ),
                ),
                Column(
                  children: [
                    ListTile(
                      onTap: () => copyToClipboard(f.filename, context),
                      title: Text(f.filename),
                      subtitle: Text('Filename'),
                    ),
                    ListTile(
                      title: Text('${fmtNum(progress, p: 1)}% | ' +
                          '${humanifySize(f.sizeDownloaded)} ' +
                          '/ ${humanifySize(f.size)}'),
                      subtitle: Text('Downloaded'),
                    ),
                    ListTile(
                      title: Text('${f.priority.capitalize()}'),
                      subtitle: Text('Priority'),
                    ),
                  ],
                ),
              ],
            ));
      },
    );
  }
}
