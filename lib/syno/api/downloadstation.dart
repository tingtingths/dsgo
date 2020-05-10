import 'dart:io';

import 'package:dio/dio.dart';
import 'package:synodownloadstation/syno/api/context.dart';

import 'const.dart';

class DownloadStationAPI {
  final session = 'DownloadStation';
  final endpoint = '/webapi/DownloadStation';
  final endpointInfo = '/info.cgi';
  final endpointSchedule = '/schedule.cgi';
  final endpointTask = '/task.cgi';
  final endpointStat = '/statistic.cgi';
  APIContext _cntx;

  DownloadStationAPI(APIContext cntx) {
    _cntx = cntx;
  }

  Future<Response<String>> infoGetInfo({int version: 1}) async {
    final param = {
      'api': Syno.DownloadStation.Info,
      'version': version.toString(),
      'method': 'getinfo',
      '_sid': _cntx.appSid[session]
    };

    final Uri uri = _cntx.buildUri(endpoint + endpointInfo, param);
    return _cntx.c.getUri(uri);
  }

  Future<Response<String>> infoGetConfig({int version: 1}) async {
    final param = {
      'api': Syno.DownloadStation.Info,
      'version': version.toString(),
      'method': 'getconfig',
      '_sid': _cntx.appSid[session]
    };

    final Uri uri = _cntx.buildUri(endpoint + endpointInfo, param);
    return _cntx.c.getUri(uri);
  }

  Future<Response<String>> infoSetServerConfig(Map<String, String> config,
      {int version: 1}) async {
    final param = {
      'api': Syno.DownloadStation.Info,
      'version': version.toString(),
      'method': 'setserverconfig',
      '_sid': _cntx.appSid[session]
    };
    param.addAll(config);
    param.removeWhere((key, value) => value == null);

    final Uri uri = _cntx.buildUri(endpoint + endpointInfo, param);
    return _cntx.c.getUri(uri);
  }

  Future<Response<String>> scheduleGetConfig({int version: 1}) async {
    final param = {
      'api': Syno.DownloadStation.Schedule,
      'version': version.toString(),
      'method': 'getconfig',
      '_sid': _cntx.appSid[session]
    };

    final Uri uri = _cntx.buildUri(endpoint + endpointSchedule, param);
    return _cntx.c.getUri(uri);
  }

  Future<Response<String>> scheduleSetConfig(bool enabled, bool emuleEnabled,
      {int version: 1}) async {
    final param = {
      'enabled': enabled.toString(),
      'emule_enabled': emuleEnabled.toString(),
      'api': Syno.DownloadStation.Schedule,
      'version': version.toString(),
      'method': 'setconfig',
      '_sid': _cntx.appSid[session]
    };

    final Uri uri = _cntx.buildUri(endpoint + endpointSchedule, param);
    return _cntx.c.getUri(uri);
  }

  Future<Response<String>> taskList(
      {int version: 1,
      int offset: 0,
      int limit: -1,
      List<String> additional: const [
        'detail',
        'transfer',
        'file',
        'tracker',
        'peer'
      ]}) async {
    final param = {
      'offset': offset.toString(),
      'limit': limit.toString(),
      'additional': additional?.join(","),
      // detail, transfer, file, tracker, peer
      'api': Syno.DownloadStation.Task,
      'version': version.toString(),
      'method': 'list',
      '_sid': _cntx.appSid[session]
    };

    final Uri uri = _cntx.buildUri(endpoint + endpointTask, param);
    return _cntx.c.getUri(uri);
  }

  Future<Response<String>> taskGetInfo(List<String> ids,
      {int version: 1,
      List<String> additional: const [
        'detail',
        'transfer',
        'file',
        'tracker',
        'peer'
      ]}) async {
    final param = {
      'id': ids.join(","),
      'additional': additional?.join(","),
      // detail, transfer, file, tracker, peer
      'api': Syno.DownloadStation.Task,
      'version': version.toString(),
      'method': 'getinfo',
      '_sid': _cntx.appSid[session]
    };

    final Uri uri = _cntx.buildUri(endpoint + endpointTask, param);

    return _cntx.c.getUri(uri);
  }

  Future<Response<String>> taskCreate(
      {int version: 3,
      List<String> uris,
      File file,
      String username,
      String passwd,
      String unzipPasswd,
      String destination}) async {
    final param = {
      'uri': uris?.join(","),
      'username': username,
      'password': passwd,
      'unzip_password': unzipPasswd,
      'destination': destination,
      'api': Syno.DownloadStation.Task,
      'version': version.toString(),
      'method': 'create',
      '_sid': _cntx.appSid[session]
    };
    param.removeWhere((key, value) => value == null);

    final Uri uri = _cntx.buildUri(endpoint + endpointTask, null);

    dynamic data = FormData.fromMap(param);
    if (file != null && !file.existsSync()) {
      throw Exception('File not found');
    }

    var options;
    if (file != null) {
      data.files.add(MapEntry('file', await MultipartFile.fromFile(file.path)));
    } else {
      // if not using file, send as x-www-form-urlencoded
      data = param;
      options = Options(contentType: Headers.formUrlEncodedContentType);
    }

    return _cntx.c.postUri(uri, data: data, options: options);
  }

  Future<Response<String>> taskDelete(List<String> ids, bool forceComplete,
      {int version: 1}) async {
    final param = {
      'id': ids.join(","),
      'force_complete': forceComplete.toString(),
      'api': Syno.DownloadStation.Task,
      'version': version.toString(),
      'method': 'delete',
      '_sid': _cntx.appSid[session]
    };

    final Uri uri = _cntx.buildUri(endpoint + endpointTask, param);
    return _cntx.c.getUri(uri);
  }

  Future<Response<String>> taskPause(List<String> ids, {int version: 1}) async {
    final param = {
      'id': ids.join(","),
      'api': Syno.DownloadStation.Task,
      'version': version.toString(),
      'method': 'pause',
      '_sid': _cntx.appSid[session]
    };

    final Uri uri = _cntx.buildUri(endpoint + endpointTask, param);
    return _cntx.c.getUri(uri);
  }

  Future<Response<String>> taskResume(List<String> ids,
      {int version: 1}) async {
    final param = {
      'id': ids.join(","),
      'api': Syno.DownloadStation.Task,
      'version': version.toString(),
      'method': 'resume',
      '_sid': _cntx.appSid[session]
    };

    final Uri uri = _cntx.buildUri(endpoint + endpointTask, param);
    return _cntx.c.getUri(uri);
  }

  Future<Response<String>> taskEdit(List<String> ids, {String destination, int version: 1}) async {
    final param = {
      'id': ids.join(","),
      'destination': destination,
      'api': Syno.DownloadStation.Task,
      'version': version.toString(),
      'method': 'edit',
      '_sid': _cntx.appSid[session]
    };
    param.removeWhere((key, value) => value == null);

    final Uri uri = _cntx.buildUri(endpoint + endpointTask, param);
    return _cntx.c.getUri(uri);
  }

  Future<Response<String>> statGetInfo({int version: 1}) async {
    final param = {
      'api': Syno.DownloadStation.Statistic,
      'version': version.toString(),
      'method': 'getinfo',
      '_sid': _cntx.appSid[session]
    };

    final Uri uri = _cntx.buildUri(endpoint + endpointTask, param);
    return _cntx.c.getUri(uri);
  }
}
