import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:synodownloadstation/model/model.dart';
import 'package:synodownloadstation/provider/connection.dart';
import 'package:synodownloadstation/syno/api/context.dart';
import 'package:synodownloadstation/syno/api/modeled/downloadstation.dart';
import 'package:synodownloadstation/syno/api/modeled/model.dart';

enum RequestType { task_list, task_info }

extension RequestTypeMember on RequestType {
  String get name => const {
        RequestType.task_info: 'REQ_TYPE_TASK_INFO',
        RequestType.task_list: 'REQ_TYPE_TASK_LIST',
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
      _connection = value;
      _initContext();
    });

    return SynoApiState(null, null);
  }

  @override
  Stream<SynoApiState> mapEventToState(SynoApiEvent event) async* {
    APIResponse resp;

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
