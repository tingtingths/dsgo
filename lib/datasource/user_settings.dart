import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:localstorage/localstorage.dart';

import '../event/streams.dart';
import '../model/model.dart';
import '../util/const.dart';

final userSettingsDatastoreProvider =
    Provider((ref) => kIsWeb ? WebUserSettingsDatasource() : MobileUserSettingsDatasource());

abstract class UserSettingsDatasource {
  static const String STREAM_NAME = 'STREAM_USER_SETTINGS';
  StreamManager _streamManager = StreamManager();

  Future<UserSettings> get();

  UserSettingsDatasource() {
    _streamManager.register(STREAM_NAME, StreamController<UserSettings>());
  }

  Future<void> set(UserSettings? settings) async {
    _streamManager.controller(STREAM_NAME)!.add(settings);
  }

  String encodeJson(UserSettings settings) {
    return jsonEncode(settings.toJson());
  }

  UserSettings decodeJson(String json) {
    return UserSettings.fromJson(jsonDecode(json));
  }

  Stream<UserSettings>? onSet() {
    return _streamManager.stream(STREAM_NAME);
  }
}

class WebUserSettingsDatasource extends UserSettingsDatasource {
  static WebUserSettingsDatasource _instance = WebUserSettingsDatasource._internal();
  final LocalStorage _storage = new LocalStorage('_dsgo');

  factory WebUserSettingsDatasource() {
    return _instance;
  }

  WebUserSettingsDatasource._internal();

  @override
  Future<UserSettings> get() async {
    return _storage.ready.then((ready) {
      var json = _storage.getItem(StorageKey.UserSettings.key);
      UserSettings settings = UserSettings();
      if (json == null) return settings;
      try {
        settings = decodeJson(json);
      } catch (e) {
        // ignored
      }
      return settings;
    });
  }

  @override
  Future<void> set(UserSettings? settings) async {
    super.set(settings);
    if (settings == null) {
      await _storage.setItem(StorageKey.UserSettings.key, '{}');
      return;
    }
    var json = encodeJson(settings);
    await _storage.setItem(StorageKey.UserSettings.key, json);
  }
}

class MobileUserSettingsDatasource extends UserSettingsDatasource {
  static MobileUserSettingsDatasource _instance = MobileUserSettingsDatasource._internal();
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  factory MobileUserSettingsDatasource() {
    return _instance;
  }

  MobileUserSettingsDatasource._internal();

  @override
  Future<UserSettings> get() async {
    var json = await (_storage.read(key: StorageKey.UserSettings.key));
    UserSettings settings = UserSettings(); // default
    if (json == null) return settings;
    try {
      settings = decodeJson(json);
    } catch (e) {
      // ignored
    }
    return settings;
  }

  @override
  Future<void> set(UserSettings? settings) async {
    super.set(settings);
    if (settings == null) {
      await _storage.write(key: StorageKey.UserSettings.key, value: '{}');
      return;
    }
    var json = encodeJson(settings);
    await _storage.write(key: StorageKey.UserSettings.key, value: json);
  }
}
