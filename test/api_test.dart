import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:synodownloadstation/syno/api/auth.dart';
import 'package:synodownloadstation/syno/api/context.dart';
import 'package:synodownloadstation/syno/api/downloadstation.dart';
import 'package:synodownloadstation/syno/api/query.dart';
import 'package:test/test.dart';

void main() {
  test('Test Syno Api', () async {
    var jsonEncoder = JsonEncoder.withIndent('  ');
    var jsonDecoder = JsonDecoder();
    var cntx = APIContext('itdog.me', port: 8443);

    var queryApi = QueryAPI(cntx);
    var resp = await queryApi.apiInfo();
    Map obj = jsonDecode(resp.data);

    var authApi = AuthAPI(cntx);
    var authOk =
        await cntx.authApp('DownloadStation', 'ds_api', 'JQ9GYtUN96sV6EkP');
    var dsApi = DownloadStationAPI(cntx);

    await dsApi.infoGetInfo();
    resp = await dsApi.taskList(additional: ['detail']);
    obj = jsonDecoder.convert(resp.data) ?? {};
    Map data = obj['data'] ?? {};
    List tasks = data['tasks'] ?? [];
    if (tasks.isNotEmpty) {
      Map task = tasks[0];
      await dsApi.taskGetInfo([task['id']]);
    }

    // add task
    //var r = await dsApi.taskCreate(file: File('D:/test.torrent'));
    var r = await dsApi.taskCreate(
        url:
            'magnet:?xt=urn:btih:f95c371d5609d15f6615139be84edbb5b94a79bc&dn=archlinux-2020.05.01-x86_64.iso&tr=udp://tracker.archlinux.org:6969&tr=http://tracker.archlinux.org:6969/announce');

    authApi.logout('DownloadStation');
  });
}
