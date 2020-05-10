import 'package:dio/dio.dart';
import 'package:synodownloadstation/syno/api/context.dart';

import 'const.dart';

class QueryAPIRaw {
  final endpoint = '/webapi/query.cgi';
  APIContext _cntx;

  QueryAPIRaw(APIContext cntx) {
    _cntx = cntx;
  }

  Future<Response<String>> apiInfoRaw(
      {int version: 1, String query: 'all'}) async {
    final param = {
      'api': Syno.API.Info,
      'version': version.toString(),
      'query': query,
      'method': 'query'
    };
    param.removeWhere((key, value) => value == null);

    final Uri uri = _cntx.buildUri(endpoint, param);
    return _cntx.c.getUri(uri);
  }
}
