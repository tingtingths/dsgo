import 'dart:async';
import 'dart:convert';

import 'package:dsgo/event/streams.dart';
import 'package:dsgo/model/model.dart';
import 'package:dsgo/util/const.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class UserSettingsProvider {
  static const String STREAM_NAME = 'STREAM_USER_SETTINGS';
  StreamManager _streamManager = StreamManager();

  Future<UserSettings> get();

  UserSettingsProvider() {
    _streamManager.register(STREAM_NAME, StreamController<UserSettings>());
  }

  Future<void> set(UserSettings settings) {
    _streamManager.controller(STREAM_NAME).add(settings);
  }

  String encodeJson(UserSettings settings) {
    return jsonEncode(settings.toJson());
  }

  UserSettings decodeJson(String json) {
    return UserSettings.fromJson(jsonDecode(json));
  }

  Stream<UserSettings> onSet() {
    return _streamManager.stream(STREAM_NAME);
  }
}

class MobileUserSettingsProvider extends UserSettingsProvider {
  static MobileUserSettingsProvider _instance = MobileUserSettingsProvider._internal();
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  factory MobileUserSettingsProvider() {
    return _instance;
  }

  MobileUserSettingsProvider._internal();

  @override
  Future<UserSettings> get() async {
    var json = await _storage.read(key: StorageKey.UserSettings.key);
    UserSettings settings = UserSettings(); // default
    try {
      settings = decodeJson(json);
    } catch (e) {
      // ignored
    }
    return settings;
  }

  @override
  Future<void> set(UserSettings settings) async {
    super.set(settings);
    var json = encodeJson(settings);
    await _storage.write(key: StorageKey.UserSettings.key, value: json);
  }
}
