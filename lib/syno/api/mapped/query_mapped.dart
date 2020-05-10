import 'dart:convert';

import 'package:synodownloadstation/syno/api/context.dart';
import 'package:synodownloadstation/syno/api/mapped/model.dart';
import 'package:synodownloadstation/syno/api/query.dart';

class QueryAPI extends QueryAPIRaw {
  QueryAPI(APIContext cntx) : super(cntx);

  Future<APIResponse<Map<String, APIInfo>>> apiInfo(
      {int version: 1, String query: 'all'}) async {
    return super.apiInfoRaw(version: version).then((resp) {
      return APIResponse<Map<String, APIInfo>>.fromJson(jsonDecode(resp.data), (data) {
        Map<String, APIInfo> result = {};
        data.forEach((key, value) {
          result[key] = APIInfo.empty().fromJson(value);
        });
        return result;
      });
    });
  }
}
