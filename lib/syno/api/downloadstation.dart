import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dsgo/syno/api/context.dart';

import 'const.dart';

class DownloadStationAPIRaw {
  final session = 'DownloadStation';
  final endpoint = '/webapi/DownloadStation';
  final endpointInfo = '/info.cgi';
  final endpointSchedule = '/schedule.cgi';
  final endpointTask = '/task.cgi';
  final endpointStat = '/statistic.cgi';
  APIContext _cntx;

  DownloadStationAPIRaw(APIContext cntx) {
    _cntx = cntx;
  }

  Future<Response<String>> infoGetInfoRaw({int version}) async {
    final param = {
      'api': Syno.DownloadStation.Info,
      'version': version == null
          ? _cntx.maxApiVersion(Syno.DownloadStation.Info).toString()
          : version.toString(),
      'method': 'getinfo',
      '_sid': _cntx.appSid[session]
    };

    final Uri uri = _cntx.buildUri(endpoint + endpointInfo, param);
    return _cntx.c.getUri(uri);
  }

  Future<Response<String>> infoGetConfigRaw({int version}) async {
    final param = {
      'api': Syno.DownloadStation.Info,
      'version': version == null
          ? _cntx.maxApiVersion(Syno.DownloadStation.Info).toString()
          : version.toString(),
      'method': 'getconfig',
      '_sid': _cntx.appSid[session]
    };

    final Uri uri = _cntx.buildUri(endpoint + endpointInfo, param);
    return _cntx.c.getUri(uri);
  }

  Future<Response<String>> infoSetServerConfigRaw(Map<String, String> config,
      {int version}) async {
    final param = {
      'api': Syno.DownloadStation.Info,
      'version': version == null
          ? _cntx.maxApiVersion(Syno.DownloadStation.Info).toString()
          : version.toString(),
      'method': 'setserverconfig',
      '_sid': _cntx.appSid[session]
    };
    param.addAll(config);
    param.removeWhere((key, value) => value == null);

    final Uri uri = _cntx.buildUri(endpoint + endpointInfo, param);
    return _cntx.c.getUri(uri);
  }

  Future<Response<String>> scheduleGetConfigRaw({int version}) async {
    final param = {
      'api': Syno.DownloadStation.Schedule,
      'version': version == null
          ? _cntx.maxApiVersion(Syno.DownloadStation.Schedule).toString()
          : version.toString(),
      'method': 'getconfig',
      '_sid': _cntx.appSid[session]
    };

    final Uri uri = _cntx.buildUri(endpoint + endpointSchedule, param);
    return _cntx.c.getUri(uri);
  }

  Future<Response<String>> scheduleSetConfigRaw(bool enabled, bool emuleEnabled,
      {int version}) async {
    final param = {
      'enabled': enabled.toString(),
      'emule_enabled': emuleEnabled.toString(),
      'api': Syno.DownloadStation.Schedule,
      'version': version == null
          ? _cntx.maxApiVersion(Syno.DownloadStation.Schedule).toString()
          : version.toString(),
      'method': 'setconfig',
      '_sid': _cntx.appSid[session]
    };

    final Uri uri = _cntx.buildUri(endpoint + endpointSchedule, param);
    return _cntx.c.getUri(uri);
  }

  Future<Response<String>> taskListRaw(
      {int version,
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
      'version': version == null
          ? _cntx.maxApiVersion(Syno.DownloadStation.Task).toString()
          : version.toString(),
      'method': 'list',
      '_sid': _cntx.appSid[session]
    };

    final Uri uri = _cntx.buildUri(endpoint + endpointTask, param);
    return _cntx.c.getUri(uri);
  }

  Future<Response<String>> taskGetInfoRaw(List<String> ids,
      {int version,
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
      'version': version == null
          ? _cntx.maxApiVersion(Syno.DownloadStation.Task).toString()
          : version.toString(),
      'method': 'getinfo',
      '_sid': _cntx.appSid[session]
    };

    final Uri uri = _cntx.buildUri(endpoint + endpointTask, param);

    return _cntx.c.getUri(uri);
  }

  Future<Response<String>> taskCreateRaw(
      {int version,
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
      'version': version == null
          ? _cntx.maxApiVersion(Syno.DownloadStation.Task).toString()
          : version.toString(),
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

  Future<Response<String>> taskDeleteRaw(List<String> ids, bool forceComplete,
      {int version}) async {
    final param = {
      'id': ids.join(","),
      'force_complete': forceComplete.toString(),
      'api': Syno.DownloadStation.Task,
      'version': version == null
          ? _cntx.maxApiVersion(Syno.DownloadStation.Task).toString()
          : version.toString(),
      'method': 'delete',
      '_sid': _cntx.appSid[session]
    };

    final Uri uri = _cntx.buildUri(endpoint + endpointTask, param);
    return _cntx.c.getUri(uri);
  }

  Future<Response<String>> taskPauseRaw(List<String> ids, {int version}) async {
    final param = {
      'id': ids.join(","),
      'api': Syno.DownloadStation.Task,
      'version': version == null
          ? _cntx.maxApiVersion(Syno.DownloadStation.Task).toString()
          : version.toString(),
      'method': 'pause',
      '_sid': _cntx.appSid[session]
    };

    final Uri uri = _cntx.buildUri(endpoint + endpointTask, param);
    return _cntx.c.getUri(uri);
  }

  Future<Response<String>> taskResumeRaw(List<String> ids,
      {int version}) async {
    final param = {
      'id': ids.join(","),
      'api': Syno.DownloadStation.Task,
      'version': version == null
          ? _cntx.maxApiVersion(Syno.DownloadStation.Task).toString()
          : version.toString(),
      'method': 'resume',
      '_sid': _cntx.appSid[session]
    };

    final Uri uri = _cntx.buildUri(endpoint + endpointTask, param);
    return _cntx.c.getUri(uri);
  }

  Future<Response<String>> taskEditRaw(List<String> ids,
      {String destination, int version}) async {
    final param = {
      'id': ids.join(","),
      'destination': destination,
      'api': Syno.DownloadStation.Task,
      'version': version == null
          ? _cntx.maxApiVersion(Syno.DownloadStation.Task).toString()
          : version.toString(),
      'method': 'edit',
      '_sid': _cntx.appSid[session]
    };
    param.removeWhere((key, value) => value == null);

    final Uri uri = _cntx.buildUri(endpoint + endpointTask, param);
    return _cntx.c.getUri(uri);
  }

  Future<Response<String>> statGetInfoRaw({int version}) async {
    final param = {
      'api': Syno.DownloadStation.Statistic,
      'version': version == null
          ? _cntx.maxApiVersion(Syno.DownloadStation.Statistic).toString()
          : version.toString(),
      'method': 'getinfo',
      '_sid': _cntx.appSid[session]
    };

    final Uri uri = _cntx.buildUri(endpoint + endpointStat, param);
    return _cntx.c.getUri(uri);
  }
}
