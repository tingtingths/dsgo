import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:synodownloadstation/syno/api/auth.dart';
import 'package:synodownloadstation/syno/api/modeled/model.dart';
import 'package:synodownloadstation/syno/api/modeled/query_mapped.dart';

class CustomInterceptors extends InterceptorsWrapper {
  @override
  Future onRequest(RequestOptions options) {
    print("> ${options?.method} ${options?.path}");
    return super.onRequest(options);
  }

  @override
  Future onResponse(Response response) {
    print("< ${response?.statusCode} ${response?.data}");
    return super.onResponse(response);
  }

  @override
  Future onError(DioError err) {
    print("ERROR[${err?.response?.statusCode}] => PATH: ${err?.request?.path}");
    return super.onError(err);
  }
}

class APIContext {
  String _proto;
  String _authority;
  String _endpoint;
  Dio _client;
  Map<String, String> _appSid = {};
  Map<String, APIInfoQuery> _apiInfo = {};

  APIContext(String host,
      {String proto: 'https', int port: 443, String endpoint: ''}) {
    _proto = proto;
    _authority = '$host:$port';
    _endpoint = endpoint;
    //_client = Dio()..interceptors.add(CustomInterceptors());
    _client = Dio();
  }

  Uri buildUri(String path, Map<String, String> queryParams) {
    if (_proto == 'http') {
      return Uri.http(_authority, _endpoint + path, queryParams);
    } else if (_proto == 'https') {
      return Uri.https(_authority, _endpoint + path, queryParams);
    } else {
      throw Exception('Unsupported proto \'$proto\'');
    }
  }

  Future<bool> authApp(String app, String account, String passwd) async {
    var resp =
        await AuthAPIRaw(this).login(account, passwd, app, format: 'sid');
    var respObj = jsonDecode(resp.data);
    if (respObj['success']) {
      _appSid[app] = respObj['data']['sid'];

      APIResponse<Map<String, APIInfoQuery>> apiInfo =
          await QueryAPI(this).apiInfo();
      if (!apiInfo.success) {
        throw Exception('Failed to query api info. error: ' +
            apiInfo.error.entries.map((e) => '${e.key}=${e.value}').join(','));
      }
      _apiInfo = apiInfo.data;

      return true;
    }
    return false;
  }

  String get endpoint => _endpoint;

  String get authority => _authority;

  String get proto => _proto;

  Map<String, String> get appSid => _appSid;

  Dio get c => _client;

  Map<String, APIInfoQuery> get apiInfo => _apiInfo;

  int maxApiVersion(String apiName, {int defaultVersion}) =>
      _apiInfo[apiName] == null ? defaultVersion : _apiInfo[apiName].maxVersion;

  int minApiVersion(String apiName, {int defaultVersion}) =>
      _apiInfo[apiName] == null ? defaultVersion : _apiInfo[apiName].minVersion;
}
