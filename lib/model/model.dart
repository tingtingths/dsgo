import 'package:dsgo/util/const.dart';
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
  String? user;
  String? uri;
  String? sid;
  String? password;
  DateTime? created;
  DateTime? updated;

  Connection.empty();

  Connection.withoutCredential(this.friendlyName, this.uri, this.user);

  Connection(this.friendlyName, this.uri, this.user, this.sid, this.password);

  String buildUri() {
    var parsed = Uri.tryParse(uri ?? '');
    if (parsed != null) {
      return Uri(scheme: parsed.scheme, userInfo: user, host: parsed.host, port: parsed.port, path: parsed.path)
          .toString();
    } else {
      return '';
    }
  }

  Connection.fromJson(Map<String, dynamic>? json) {
    friendlyName = mapGet(json, 'friendlyName');
    friendlyName = mapGet(json, 'friendlyName');
    uri = mapGet(json, 'uri');
    user = mapGet(json, 'user');
    sid = mapGet(json, 'sid');
    password = mapGet(json, 'password');

    int? createdTs = mapGet(json, 'created');
    created = createdTs == null ? null : DateTime.fromMillisecondsSinceEpoch(createdTs);

    int? updatedTs = mapGet(json, 'updated');
    updated = updatedTs == null ? null : DateTime.fromMillisecondsSinceEpoch(updatedTs);
  }

  Map<String, dynamic> toJson() => {
        'friendlyName': friendlyName,
        'uri': uri,
        'user': user,
        'sid': sid,
        'password': password,
        'created': created?.millisecondsSinceEpoch,
        'updated': updated?.millisecondsSinceEpoch,
      };
}

class UserSettings {
  int apiRequestFrequency = REQUEST_INTERVAL_DEFAULT; // ms
  ThemeMode themeMode = ThemeMode.system;
  Locale? locale;

  UserSettings({int? apiRequestFrequency, ThemeMode? themeMode, Locale? locale}) {
    if (apiRequestFrequency != null) this.apiRequestFrequency = apiRequestFrequency;
    if (themeMode != null) this.themeMode = themeMode;
    if (locale != null) this.locale = locale;
  }

  UserSettings.fromJson(Map<String, dynamic>? json) {
    apiRequestFrequency = mapGet(json, 'apiRequestFrequency');
    var themeModeStr = mapGet(json, 'themeMode');
    themeMode = ThemeMode.values.firstWhere((e) => e.toString() == themeModeStr);
    var langCode = mapGet(mapGet(json, 'locale'), 'languageCode');
    var scriptCode = mapGet(mapGet(json, 'locale'), 'scriptCode');
    var countryCode = mapGet(mapGet(json, 'locale'), 'countryCode');
    if (langCode != null || scriptCode != null || countryCode != null) {
      locale = Locale.fromSubtags(languageCode: langCode, scriptCode: scriptCode, countryCode: countryCode);
    } else {
      locale = null;
    }
  }

  Map<String, dynamic> toJson() => {
        'apiRequestFrequency': apiRequestFrequency,
        'themeMode': themeMode.toString(),
        'locale': {
          'languageCode': locale?.languageCode,
          'scriptCode': locale?.scriptCode,
          'countryCode': locale?.countryCode,
        }
      };

  UserSettings clone() =>
      UserSettings(apiRequestFrequency: this.apiRequestFrequency, themeMode: this.themeMode, locale: this.locale);
}
