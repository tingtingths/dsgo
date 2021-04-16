import 'package:dsgo/util/utils.dart';
import 'package:flutter/material.dart';

class ConnectionMenuItem {
  var _type = 1;
  dynamic _value;

  static const CONN = 1;
  static const ADD = 2;

  ConnectionMenuItem(this._type, dynamic _value);

  dynamic get value => _value;

  get type => _type;
}

class Connection {
  String? friendlyName;
  String? proto;
  String? user;
  String? host;
  int? port;
  String? sid;
  String? password;
  DateTime? created;
  DateTime? updated;

  Connection.empty();

  Connection.withoutCredential(this.friendlyName, this.proto, this.user, this.host, this.port);

  Connection(this.friendlyName, this.proto, this.user, this.host, this.port, this.sid, this.password);

  String buildUri() => Uri(scheme: proto, userInfo: user, host: host, port: port).toString();

  Connection.fromJson(Map<String, dynamic>? json) {
    friendlyName = mapGet(json, 'friendlyName');
    friendlyName = mapGet(json, 'friendlyName');
    proto = mapGet(json, 'proto');
    user = mapGet(json, 'user');
    host = mapGet(json, 'host');
    port = mapGet(json, 'port');
    sid = mapGet(json, 'sid');
    password = mapGet(json, 'password');

    int? createdTs = mapGet(json, 'created');
    created = createdTs == null ? null : DateTime.fromMillisecondsSinceEpoch(createdTs);

    int? updatedTs = mapGet(json, 'updated');
    updated = updatedTs == null ? null : DateTime.fromMillisecondsSinceEpoch(updatedTs);
  }

  Map<String, dynamic> toJson() => {
        'friendlyName': friendlyName,
        'proto': proto,
        'user': user,
        'host': host,
        'port': port,
        'sid': sid,
        'password': password,
        'created': created?.millisecondsSinceEpoch,
        'updated': updated?.millisecondsSinceEpoch,
      };
}

class UserSettings {
  int? apiRequestFrequency = 5000; // ms
  ThemeMode? themeMode = ThemeMode.system;

  UserSettings({int? apiRequestFrequency, ThemeMode? themeMode}) {
    if (apiRequestFrequency != null) this.apiRequestFrequency = apiRequestFrequency;
    if (themeMode != null) this.themeMode = themeMode;
  }

  UserSettings.fromJson(Map<String, dynamic>? json) {
    apiRequestFrequency = mapGet(json, 'apiRequestFrequency');
    var themeModeStr = mapGet(json, 'themeMode');
    themeMode = ThemeMode.values.firstWhere((e) => e.toString() == themeModeStr);
  }

  Map<String, dynamic> toJson() => {'apiRequestFrequency': apiRequestFrequency, 'themeMode': themeMode.toString()};
}
