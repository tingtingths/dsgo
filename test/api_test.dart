import 'dart:convert';

import 'package:synodownloadstation/syno/api/auth.dart';
import 'package:synodownloadstation/syno/api/const.dart';
import 'package:synodownloadstation/syno/api/context.dart';
import 'package:synodownloadstation/syno/api/downloadstation.dart';
import 'package:synodownloadstation/syno/api/modeled/downloadstation.dart';
import 'package:synodownloadstation/syno/api/modeled/model.dart';
import 'package:synodownloadstation/syno/api/modeled/query_mapped.dart';
import 'package:synodownloadstation/syno/api/query.dart';
import 'package:synodownloadstation/util/format.dart';
import 'package:test/test.dart';

import '../lib/confidential.dart';

void main() {
  test('Test format', () {
    print(humanifySize(952000000000));
    print(humanifySize(952360000000));
    print(humanifySize(9523600000000));
    print(humanifySize(952360000000));
    print(humanifySize(95236000000));
    print(humanifySize(9523600000));
    print(humanifySize(952360000));
    print(humanifySize(95236000));
    print(humanifySize(9523600));
    print(humanifySize(952360));
    print(humanifySize(95236));
    print(humanifySize(9523));
    print(humanifySize(952));
    print(humanifySize(95));
    print(humanifySize(9));
    print(humanifySize(0));

    print('------------------------------');
    print(humanifySeconds(469386, accuracy: 60));
    print(humanifySeconds(460000));
    print(humanifySeconds(46000));
    print(humanifySeconds(4600));
    print(humanifySeconds(460));
    print(humanifySeconds(46));
    print(humanifySeconds(4));
    print(humanifySeconds(1));
    print(humanifySeconds(0));
  });

  test('Test API name constant', () {
    expect(Syno.DownloadStation.Info, 'SYNO.DownloadStation.Info');
    expect(Syno.DownloadStation.Schedule, 'SYNO.DownloadStation.Schedule');
    expect(Syno.DownloadStation.Task, 'SYNO.DownloadStation.Task');
    expect(Syno.DownloadStation.Statistic, 'SYNO.DownloadStation.Statistic');
    expect(Syno.DownloadStation.RSS.Site, 'SYNO.DownloadStation.RSS.Site');
    expect(Syno.DownloadStation.RSS.Feed, 'SYNO.DownloadStation.RSS.Feed');
    expect(Syno.DownloadStation.BTSearch, 'SYNO.DownloadStation.BTSearch');
    expect(Syno.API.Info, 'SYNO.API.Info');
    expect(Syno.API.Auth, 'SYNO.API.Auth');
  });

  test('Test Json typing', () async {
    var cntx = APIContext('itdog.me', port: 8443);

    var queryApi = QueryAPI(cntx);
    APIResponse<Map<String, APIInfoQuery>> info = await queryApi.apiInfo();
    if (info.success) {
      info.data.forEach((key, value) {
        print(
            '$key => min=${value.minVersion},max=${value.maxVersion},path=${value.path}');
      });
    }

    var authApi = AuthAPIRaw(cntx);
    var authOk = await cntx.authApp('DownloadStation', user, passwd);
    var dsApi = DownloadStationAPI(cntx);

    if (false) {
      await dsApi.taskCreateRaw(uris: [
        'magnet:?xt=urn:btih:f95c371d5609d15f6615139be84edbb5b94a79bc&dn=archlinux-2020.05.01-x86_64.iso&tr=udp://tracker.archlinux.org:6969&tr=http://tracker.archlinux.org:6969/announce'
      ]);
    }

    APIResponse<ListTaskInfo> taskResp = await dsApi.taskList();
    if (taskResp.success) {
      var info = taskResp.data;
      print('total=${info.total}');
      info.tasks.forEach((e) {
        print('id=${e.id},type=${e.type},title=${e.title}');
        print(
            '\tST=${e.status},DL=${e.additional.transfer.speedDownload},PRG=${(100 * e.additional.transfer.sizeDownloaded / e.size).toStringAsFixed(1)}%');
      });
    }

    APIResponse<DownloadStationStatisticGetInfo> stats =
        await dsApi.statGetInfo();
    if (stats.success) {
      print('Total download speed=${stats.data.speedDownload}');
      print('Total upload speed=${stats.data.speedUpload}');
    }
  });

  test('Test Syno Api', () async {
    var jsonEncoder = JsonEncoder.withIndent('  ');
    var jsonDecoder = JsonDecoder();
    var cntx = APIContext('itdog.me', port: 8443);

    var queryApi = QueryAPIRaw(cntx);
    var resp = await queryApi.apiInfoRaw();
    Map obj = jsonDecode(resp.data);

    var authApi = AuthAPIRaw(cntx);
    var authOk = await cntx.authApp('DownloadStation', user, passwd);
    var dsApi = DownloadStationAPIRaw(cntx);

    await dsApi.infoGetInfoRaw();
    resp = await dsApi.taskListRaw(additional: ['detail']);
    obj = jsonDecoder.convert(resp.data) ?? {};
    Map data = obj['data'] ?? {};
    List tasks = data['tasks'] ?? [];
    if (tasks.isNotEmpty) {
      Map task = tasks[0];
      await dsApi.taskGetInfoRaw([task['id']]);
    }

    // add task
    //var r = await dsApi.taskCreate(file: File('D:/test.torrent'));
    var r = await dsApi.taskCreateRaw(uris: [
      'magnet:?xt=urn:btih:f95c371d5609d15f6615139be84edbb5b94a79bc&dn=archlinux-2020.05.01-x86_64.iso&tr=udp://tracker.archlinux.org:6969&tr=http://tracker.archlinux.org:6969/announce'
    ]);

    authApi.logout('DownloadStation');
  });
}
