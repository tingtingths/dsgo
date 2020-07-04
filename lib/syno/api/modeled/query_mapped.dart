import 'dart:convert';

import 'package:dsgo/syno/api/context.dart';
import 'package:dsgo/syno/api/modeled/model.dart';
import 'package:dsgo/syno/api/query.dart';

class QueryAPI extends QueryAPIRaw {
  QueryAPI(APIContext cntx) : super(cntx);

  Future<APIResponse<Map<String, APIInfoQuery>>> apiInfo({int version, String query: 'all'}) async {
    return super.apiInfoRaw(version: version).then((resp) {
      return APIResponse<Map<String, APIInfoQuery>>.fromJson(jsonDecode(resp.data), (data) {
        Map<String, APIInfoQuery> result = {};
        data.forEach((key, value) {
          result[key] = APIInfoQuery.fromJson(value);
        });
        return result;
      });
    });
  }
}
