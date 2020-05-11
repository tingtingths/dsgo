import 'dart:convert';
import 'dart:io';

import 'package:synodownloadstation/syno/api/context.dart';
import 'package:synodownloadstation/syno/api/downloadstation.dart';
import 'package:synodownloadstation/syno/api/modeled/model.dart';
import 'package:synodownloadstation/syno/api/const.dart';

class DownloadStationAPI extends DownloadStationAPIRaw {
  APIContext _cntx;

  DownloadStationAPI(APIContext cntx) : super(cntx) {
    _cntx = cntx;
  }

  Future<APIResponse<DownloadStationInfoGetInfo>> infoGetInfo(
      {int version}) async {
    return super.infoGetInfoRaw(version: version).then((resp) {
      return APIResponse.fromJson(jsonDecode(resp.data),
          (json) => DownloadStationInfoGetInfo.fromJson(json));
    });
  }

  Future<APIResponse<DownloadStationInfoGetConfig>> infoGetConfig(
      {int version}) async {
    return super.infoGetConfigRaw(version: version).then((resp) {
      return APIResponse.fromJson(jsonDecode(resp.data),
          (json) => DownloadStationInfoGetConfig.fromJson(json));
    });
  }

  Future<APIResponse<void>> infoSetServerConfig(Map<String, String> config,
      {int version}) async {
    return super.infoSetServerConfigRaw(config, version: version).then((resp) {
      return APIResponse.fromJson(jsonDecode(resp.data), (json) {});
    });
  }

  Future<APIResponse<DownloadStationScheduleGetConfig>> scheduleGetConfig(
      {int version}) async {
    return super.scheduleGetConfigRaw(version: version).then((resp) {
      return APIResponse.fromJson(jsonDecode(resp.data),
          (json) => DownloadStationScheduleGetConfig.fromJson(json));
    });
  }

  Future<APIResponse<void>> scheduleSetConfig(bool enabled, bool emuleEnabled,
      {int version}) async {
    return super
        .scheduleSetConfigRaw(enabled, emuleEnabled, version: version)
        .then((resp) {
      return APIResponse.fromJson(jsonDecode(resp.data), (json) {});
    });
  }

  Future<APIResponse<ListTaskInfo>> taskList(
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
    return super
        .taskListRaw(
            version: version,
            offset: offset,
            limit: limit,
            additional: additional)
        .then((resp) {
      return APIResponse<ListTaskInfo>.fromJson(jsonDecode(resp.data), (data) {
        return ListTaskInfo.fromJson(data);
      });
    });
  }

  Future<APIResponse<List<Task>>> taskGetInfo(List<String> ids,
      {int version,
      List<String> additional: const [
        'detail',
        'transfer',
        'file',
        'tracker',
        'peer'
      ]}) async {
    return super
        .taskGetInfoRaw(ids, version: version, additional: additional)
        .then((resp) {
      return APIResponse.fromJson(jsonDecode(resp.data), (json) {
        if (json.containsKey('tasks')) {
          List<dynamic> tasks = (json ?? {})['tasks'];
          return tasks.map((e) => Task.fromJson(e)).toList();
        }
        return [];
      });
    });
  }

  Future<APIResponse<void>> taskCreate(
      {int version,
      List<String> uris,
      File file,
      String username,
      String passwd,
      String unzipPasswd,
      String destination}) async {
    return super
        .taskCreateRaw(
            version: version,
            uris: uris,
            file: file,
            username: username,
            passwd: passwd,
            unzipPasswd: unzipPasswd,
            destination: destination)
        .then((resp) {
      return APIResponse.fromJson(jsonDecode(resp.data), (json) {});
    });
  }

  Future<APIResponse<DownloadStationTaskDelete>> taskDelete(
      List<String> ids, bool forceComplete,
      {int version}) async {
    return super
        .taskDeleteRaw(ids, forceComplete, version: version)
        .then((resp) {
      return APIResponse.fromJson(jsonDecode(resp.data),
          (json) => DownloadStationTaskDelete.fromJson(json));
    });
  }

  Future<APIResponse<DownloadStationTaskPause>> taskPause(List<String> ids,
      {int version}) async {
    return super.taskPauseRaw(ids, version: version).then((resp) {
      return APIResponse.fromJson(jsonDecode(resp.data),
          (json) => DownloadStationTaskPause.fromJson(json));
    });
  }

  Future<APIResponse<DownloadStationTaskResume>> taskResume(List<String> ids,
      {int version}) async {
    return super.taskResumeRaw(ids, version: version).then((resp) {
      return APIResponse.fromJson(jsonDecode(resp.data),
          (json) => DownloadStationTaskResume.fromJson(json));
    });
  }

  Future<APIResponse<DownloadStationTaskEdit>> taskEdit(List<String> ids,
      {String destination, int version}) async {
    return super
        .taskEditRaw(ids, destination: destination, version: version)
        .then((resp) {
      return APIResponse.fromJson(jsonDecode(resp.data),
          (json) => DownloadStationTaskEdit.fromJson(json));
    });
  }

  Future<APIResponse<DownloadStationStatisticGetInfo>> statGetInfo(
      {int version}) async {
    return super.statGetInfoRaw(version: version).then((resp) {
      return APIResponse.fromJson(jsonDecode(resp.data),
          (json) => DownloadStationStatisticGetInfo.fromJson(json));
    });
  }
}
