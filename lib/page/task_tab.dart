import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:synodownloadstation/bloc/ui_evt_bloc.dart';
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
    UiEventBloc uiBloc = BlocProvider.of<UiEventBloc>(context);
    uiBloc.listen((state) {
      if (state.event == UiEvent.tasks_fetched) {
        DateTime fetchedDt = state.payload[0];
        ListTaskInfo info = state.payload[1];
        Task found = info.tasks
            .firstWhere((task) => task.id == _task?.id, orElse: () => null);
        if (found == null) {
          Navigator.of(context).pop();
        }

        if (mounted) {
          setState(() {
            _task = found;
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
                title: Text(_task.title),
                subtitle: Text('Title'),
              ),
              ListTile(
                title: Text(_task.status.name.capitalize()),
                subtitle: Text('Status'),
              ),
              ListTile(
                onTap: () =>
                    copyToClipboard(_task.additional?.detail?.uri, context),
                title: Text(_task.additional?.detail?.destination),
                subtitle: Text('Destination'),
              ),
              ListTile(
                title: Text(humanifySize(_task.size)),
                subtitle: Text('Size'),
              ),
              ListTile(
                onTap: () =>
                    copyToClipboard(_task.additional?.detail?.uri, context),
                title: Text(_task.username),
                subtitle: Text('Owner'),
              ),
              ListTile(
                onTap: () =>
                    copyToClipboard(_task.additional?.detail?.uri, context),
                title: Text(_task.additional?.detail?.uri),
                subtitle: Text('URI'),
              ),
              ListTile(
                title: Text(_task.additional?.detail?.createTime == null
                    ? 'Unknown'
                    : dtFmt.format(_task.additional?.detail?.createTime)),
                subtitle: Text('Created Time'),
              ),
              ListTile(
                title: Text(_task.additional?.detail?.completedTime == null
                    ? 'Unknown'
                    : dtFmt.format(_task.additional?.detail?.completedTime)),
                subtitle: Text('Completed Time'),
              ),
              ListTile(
                title: Text(
                    _task.additional?.detail?.waitingSeconds?.toString() ??
                        'Unknown'),
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
  DateFormat dtFmt = DateFormat.yMd().add_jm();

  TransferInfoTabState(this._task) : assert(_task != null);

  @override
  void initState() {
    super.initState();

    UiEventBloc uiBloc = BlocProvider.of<UiEventBloc>(context);
    uiBloc.listen((state) {
      if (state.event == UiEvent.tasks_fetched) {
        DateTime fetchedDt = state.payload[0];
        ListTaskInfo info = state.payload[1];
        Task found = info.tasks
            .firstWhere((task) => task.id == _task?.id, orElse: () => null);
        if (found == null) {
          Navigator.of(context).pop();
        }

        if (mounted) {
          setState(() {
            _task = found;
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
        humanifySize(_task.additional?.transfer?.speedDownload ?? 0, p: 0) +
            '/s';
    var upSpeed =
        humanifySize(_task.additional?.transfer?.speedUpload ?? 0, p: 0) + '/s';

    var progress =
        (_task.additional?.transfer?.sizeDownloaded ?? 0) / _task.size;
    progress = progress.isFinite ? progress : 0;

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
          title: Text('${_task.additional?.detail?.totalPeers ?? "Unknown"}'),
          subtitle: Text('Total Peers'),
        ),
        ListTile(
          title:
              Text('${_task.additional?.detail?.connectedPeers ?? "Unknown"}'),
          subtitle: Text('Connected Peers'),
        ),
        ListTile(
          title: Text('${_task.additional?.transfer?.downloadedPieces ?? 0} / ' +
              '${_task.additional?.detail?.totalPieces ?? "Unknown"}'),
          subtitle: Text('Downloaded Blocks'),
        ),
        ListTile(
          title: Text('${humanifySeconds(_task.additional?.detail?.seedElapsed, accuracy: 60)}'),
          subtitle: Text('Seeding Duration'),
        )
      ],
    );
  }
}
