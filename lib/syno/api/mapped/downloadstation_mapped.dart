import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:synodownloadstation/syno/api/context.dart';
import 'package:synodownloadstation/syno/api/downloadstation.dart';
import 'package:synodownloadstation/syno/api/mapped/model.dart';

class DownloadStationAPI extends DownloadStationAPIRaw {
  DownloadStationAPI(APIContext cntx) : super(cntx);

  Future<Map<String, dynamic>> infoGetInfo({int version: 1}) async {
    Future<Response<String>> future = super.infoGetInfoRaw(version: version);
    return future.then((resp) {
      return jsonDecode(resp.data);
    });
  }

  Future<APIResponse<ListTaskInfo>> taskList(
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
    return super
        .taskListRaw(
            version: version,
            offset: offset,
            limit: limit,
            additional: additional)
        .then((resp) {
      return APIResponse<ListTaskInfo>.fromJson(
          jsonDecode(resp.data), (data) {
            return ListTaskInfo.empty().fromJson(data);
      });
    });
  }
}
