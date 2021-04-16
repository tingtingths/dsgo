import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:synoapi/synoapi.dart';

enum RequestType {
  task_list,
  task_info,
  add_task,
  remove_task,
  pause_task, resume_task,
  statistic_info
}

extension RequestTypeMember on RequestType {
  String? get name => const {
        RequestType.task_info: 'REQ_TYPE_TASK_INFO',
        RequestType.task_list: 'REQ_TYPE_TASK_LIST',
        RequestType.add_task: 'REQ_TYPE_ADD_TASK',
        RequestType.remove_task: 'REQ_TYPE_REMOVE_TASK',
        RequestType.pause_task: 'REQ_TYPE_PAUSE_TASK',
        RequestType.resume_task: 'REQ_TYPE_RESUME_TASK',
      }[this];
}

class SynoApiEvent {
  RequestType? _requestType;
  Map<String, dynamic> _params = {};
  Function(SynoApiState)? _onCompleted;

  SynoApiEvent(this._requestType);

  SynoApiEvent.params(this._requestType, this._params);

  // request type specific constructors
  SynoApiEvent.taskList({int? offset, int? limit, List<String>? additional}) {
    _requestType = RequestType.task_list;
    _params['offset'] = offset;
    _params['limit'] = limit;
    _params['additional'] = additional;
  }

  SynoApiEvent.taskInfo(List<String> ids,
      {List<String>? additional, Function(SynoApiState)? onCompleted}) {
    _requestType = RequestType.task_info;
    _params['ids'] = ids;
    _params['additional'] = additional;
    _onCompleted = onCompleted;
  }

  SynoApiEvent.addTask(
      {List<String>? uris,
      List<File>? torrentFiles,
      Function(SynoApiState)? onCompleted}) {
    _requestType = RequestType.add_task;
    _params['uris'] = uris;
    _params['torrent_files'] = torrentFiles;
    _onCompleted = onCompleted;
  }

  SynoApiEvent.removeTask(List<String> ids,
      {Function(SynoApiState)? onCompleted}) {
    _requestType = RequestType.remove_task;
    _params['ids'] = ids;
    _onCompleted = onCompleted;
  }

  SynoApiEvent.pauseTask(List<String?> ids,
      {Function(SynoApiState)? onCompleted}) {
    _requestType = RequestType.pause_task;
    _params['ids'] = ids;
    _onCompleted = onCompleted;
  }

  SynoApiEvent.resumeTask(List<String?> ids,
      {Function(SynoApiState)? onCompleted}) {
    _requestType = RequestType.resume_task;
    _params['ids'] = ids;
    _onCompleted = onCompleted;
  }

  SynoApiEvent.statisticInfo({Function(SynoApiState)? onCompleted}) {
    _requestType = RequestType.statistic_info;
    _onCompleted = onCompleted;
  }

  Map<String, dynamic> get params => _params;

  RequestType? get requestType => _requestType;
}

class SynoApiState {
  SynoApiEvent? _event;
  APIResponse<dynamic>? _resp;

  SynoApiState(this._event, this._resp);

  SynoApiState.empty();

  APIResponse<dynamic>? get resp => _resp;

  SynoApiEvent? get event => _event;
}

class SynoApiBloc extends Bloc<SynoApiEvent, SynoApiState> {
  final l = Logger('SynoApiBloc');
  APIContext? context;
  DownloadStationAPI? _dsApi;

  SynoApiBloc() : super(SynoApiState.empty());

  dispose() {}

  @override
  Stream<SynoApiState> mapEventToState(SynoApiEvent event) async* {
    l.fine('mapEventToState(); requestType=${event.requestType}');
    APIResponse? resp;

    if (_dsApi == null) {
      l.warning('mapEventToState(); api is not ready');
      yield SynoApiState(event, resp);
      return;
    }

    if (event.requestType == RequestType.task_list) {
      int? offset = 0;
      int? limit = -1;
      List<String>? additional = ['transfer'];

      if (event._params.containsKey('offset')) {
        offset = event._params['offset'];
      }
      if (event._params.containsKey('limit')) {
        limit = event._params['limit'];
      }
      if (event._params.containsKey('additional')) {
        additional = event._params['additional'];
      }

      resp = await _dsApi!.task
          .list(offset: offset!, limit: limit!, additional: additional!);
    }

    if (event.requestType == RequestType.task_info &&
        event._params.containsKey('ids')) {
      var additional = event._params['additional'] ??
          ['detail', 'transfer', 'file', 'tracker', 'peer'];

      resp = await _dsApi!.task
          .getInfo(event._params['ids'], additional: additional);
    }

    if (event.requestType == RequestType.add_task) {
      var uris = event._params['uris'] as List<String>?;
      var files = event._params['torrent_files'] as List<File>?;

      List<Future<APIResponse<void>>> tasks = [];
      if (uris != null && uris.isNotEmpty) {
        tasks.add(_dsApi!.task.create(
          uris: uris,
        ));
      }
      if (files != null && files.isNotEmpty) {
        files.forEach((f) {
          if (f is File) {
            tasks.add(_dsApi!.task.create(file: f));
          }
        });
      }
      List<APIResponse<void>> resps = await Future.wait(tasks);
      APIResponse? failed = resps.firstWhereOrNull((r) => !r.success);
      bool success = failed == null;
      resp = APIResponse(success, null, null);
    }

    if ([
      RequestType.remove_task,
      RequestType.pause_task,
      RequestType.resume_task
    ].contains(event.requestType)) {
      List<String> ids = event._params['ids'] ?? [];

      if (ids.isNotEmpty) {
        if (event.requestType == RequestType.remove_task)
          resp = await _dsApi!.task.delete(ids, false);

        if (event.requestType == RequestType.resume_task)
          resp = await _dsApi!.task.resume(ids);

        if (event.requestType == RequestType.pause_task)
          resp = await _dsApi!.task.pause(ids);
      }
    }

    if (event.requestType == RequestType.statistic_info) {
      resp = await _dsApi!.statistic.getInfo();
    }

    var state = SynoApiState(event, resp);
    if (event._onCompleted != null) {
      event._onCompleted!(state);
    }

    yield state;
  }

  set apiContext(APIContext? value) {
    l.info('setApiContext(); $value');
    context = value;
    if (context != null)
      _dsApi = DownloadStationAPI(context!);
  }

  bool isReady() {
    return _dsApi != null;
  }
}
