import 'dart:async';
import 'dart:io';

import 'package:dsgo/model/model.dart';
import 'package:dsgo/provider/connection.dart';
import 'package:dsgo/syno/api/context.dart';
import 'package:dsgo/syno/api/modeled/downloadstation.dart';
import 'package:dsgo/syno/api/modeled/model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum RequestType {
  task_list,
  task_info,
  add_task,
  remove_task,
  pause_task,
  resume_task,
  statistic_info
}

extension RequestTypeMember on RequestType {
  String get name => const {
        RequestType.task_info: 'REQ_TYPE_TASK_INFO',
        RequestType.task_list: 'REQ_TYPE_TASK_LIST',
        RequestType.add_task: 'REQ_TYPE_ADD_TASK',
        RequestType.remove_task: 'REQ_TYPE_REMOVE_TASK',
        RequestType.pause_task: 'REQ_TYPE_PAUSE_TASK',
        RequestType.resume_task: 'REQ_TYPE_RESUME_TASK',
      }[this];
}

class SynoApiEvent {
  RequestType _requestType;
  Map<String, dynamic> _params = {};

  SynoApiEvent(this._requestType);

  SynoApiEvent.params(this._requestType, this._params);

  Map<String, dynamic> get params => _params;

  RequestType get requestType => _requestType;
}

class SynoApiState {
  SynoApiEvent _event;
  APIResponse<dynamic> _resp;

  SynoApiState(this._event, this._resp);

  APIResponse<dynamic> get resp => _resp;

  SynoApiEvent get event => _event;
}

class SynoApiBloc extends Bloc<SynoApiEvent, SynoApiState> {
  ConnectionProvider _provider;
  Connection _connection;
  APIContext _apiCntx;
  DownloadStationAPI _dsApi;

  dispose() {}

  @override
  SynoApiState get initialState {
    if (kIsWeb) {
      //_provider = WebConnectionProvider();
    } else {
      _provider = MobileConnectionProvider();
    }
    _provider.getDefaultConnection().then((value) {
      if (value != null) {
        this.connection = value;
      }
    });

    return SynoApiState(null, null);
  }

  @override
  Stream<SynoApiState> mapEventToState(SynoApiEvent event) async* {
    APIResponse resp;

    if (_dsApi == null) {
      yield SynoApiState(event, resp);
      return;
    }

    if (event.requestType == RequestType.task_list) {
      int offset = 0;
      int limit = -1;
      var additional = ['transfer'];

      if (event._params.containsKey('offset')) {
        offset = event._params['offset'];
      }
      if (event._params.containsKey('limit')) {
        limit = event._params['limit'];
      }
      if (event._params.containsKey('additional')) {
        additional = event._params['additional'];
      }

      resp = await _dsApi.taskList(
          offset: offset, limit: limit, additional: additional);
    }

    if (event.requestType == RequestType.task_info &&
        event._params.containsKey('ids')) {
      var additional = event._params['additional'] ??
          ['detail', 'transfer', 'file', 'tracker', 'peer'];

      resp = await _dsApi.taskGetInfo(event._params['ids'],
          additional: additional);
    }

    if (event.requestType == RequestType.add_task) {
      var uris = event._params['uris'] as List<String>;
      var files = event._params['torrent_files'] as List<File>;

      List<Future<APIResponse<void>>> tasks = [];
      if (uris != null && uris.isNotEmpty) {
        tasks.add(_dsApi.taskCreate(
          uris: uris,
        ));
      }
      if (files != null && files.isNotEmpty) {
        files.forEach((f) {
          if (f is File) {
            tasks.add(_dsApi.taskCreate(file: f));
          }
        });
      }
      List<APIResponse<void>> resps = await Future.wait(tasks);
      APIResponse failed =
          resps.firstWhere((r) => !r.success, orElse: () => null);
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
          resp = await _dsApi.taskDelete(ids, false);

        if (event.requestType == RequestType.resume_task)
          resp = await _dsApi.taskResume(ids);

        if (event.requestType == RequestType.pause_task)
          resp = await _dsApi.taskPause(ids);
      }
    }

    if (event.requestType == RequestType.statistic_info) {
      resp = await _dsApi.statGetInfo();
    }

    yield SynoApiState(event, resp);
  }

  Connection get connection => _connection;

  set connection(Connection value) {
    _connection = value;
    _initContext();
  }

  _initContext() {
    _apiCntx = APIContext(_connection.host,
        proto: _connection.proto, port: _connection.port);
    _apiCntx.authApp('DownloadStation', _connection.user, _connection.password);
    _dsApi = DownloadStationAPI(_apiCntx);
  }
}
