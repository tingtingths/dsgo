import 'package:dio/dio.dart';

import 'const.dart';
import 'context.dart';

class AuthAPIRaw {
  final endpoint = '/webapi/auth.cgi';
  APIContext _cntx;

  AuthAPIRaw(APIContext cntx) {
    _cntx = cntx;
  }

  Future<Response<String>> login(String account, String passwd, String session,
      {int version: 2, String format: 'sid', String otpCode}) async {
    final param = {
      'account': account,
      'passwd': passwd,
      'session': session,
      'format': format,
      'otp_code': otpCode,
      'version': version.toString(),
      'api': Syno.API.Auth,
      'method': 'login'
    };
    param.removeWhere((key, value) => value == null);

    var uri = _cntx.buildUri(endpoint, param);
    return await _cntx.c.getUri(uri);
  }

  logout(String session) async {
    final param = {
      'api': Syno.API.Auth,
      'version': '1',
      'method': 'logout',
      'session': session,
      '_sid': _cntx.appSid[session]
    };

    if (!_cntx.appSid.containsKey(session)) {
      return;
    }

    var uri = _cntx.buildUri(endpoint, param);
    await _cntx.c.getUri(uri);
    _cntx.appSid.remove(session);
  }
}
