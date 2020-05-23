import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:synodownloadstation/model/model.dart';
import 'package:synodownloadstation/util/const.dart';

abstract class ConnectionProvider {
  ConnectionProvider();

  Future<String> getDefaultConnection();

  Future<void> setDefaultConnection(String uri);

  Future<List<Connection>> getAll();

  Future<void> add(Connection conn);

  Future<Connection> remove(int idx);

  Future<void> removeAll();

  Future<List<Connection>> replace(int idx, Connection updated);

  Future<Connection> get(int idx);

  List<Connection> decodeJson(String json) {
    List<Connection> ret = [];
    try {
      List<dynamic> jsonArr = jsonDecode(json);
      jsonArr.forEach((json) {
        ret.add(Connection.fromJson(json));
      });
    } catch (e) {}
    return ret;
  }

  String encodeJson(List<Connection> connections) {
    List<dynamic> lst = [];
    connections.forEach((e) {
      lst.add(e.toJson());
    });
    return jsonEncode(lst);
  }
}

class MobileConnectionProvider extends ConnectionProvider {
  static MobileConnectionProvider _instance = MobileConnectionProvider._internal();
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  static final String _key = StorageKey.Connections.key;

  factory MobileConnectionProvider() {
    return _instance;
  }

  MobileConnectionProvider._internal();

  @override
  Future<String> getDefaultConnection() async {
    String ret;

    String value =
        await _storage.read(key: StorageKey.DefaultConnectionIndex.key);
    try {
      Map<String, dynamic> json = jsonDecode(value);
      ret = json['defaultUri'];
    } catch (e) {
      print(e);
    }

    return ret;
  }

  @override
  Future<void> setDefaultConnection(String uri) async {
    await _storage.write(
        key: StorageKey.DefaultConnectionIndex.key,
        value: jsonEncode({'defaultUri': uri}));
  }

  @override
  Future<List<Connection>> getAll() async {
    String value = await _storage.read(key: _key);
    return decodeJson(value);
  }

  @override
  Future<void> add(Connection conn) async {
    List<Connection> connections = await getAll();
    connections.add(conn);
    await _storage.write(key: _key, value: encodeJson(connections));
  }

  @override
  Future<Connection> remove(int idx) async {
    List<Connection> connections = await getAll();
    Connection ret = connections.removeAt(idx);
    await _storage.write(key: _key, value: encodeJson(connections));
    return ret;
  }

  @override
  Future<void> removeAll() async {
    await setDefaultConnection(null);
    await _storage.write(key: _key, value: encodeJson([]));
  }

  @override
  Future<List<Connection>> replace(int idx, Connection updated) async {
    List<Connection> lst = await getAll();
    lst.replaceRange(idx, idx + 1, [updated]);
    await _storage.write(key: _key, value: encodeJson(lst));
    return getAll();
  }

  @override
  Future<Connection> get(int idx) async {
    return await getAll().then((value) => value[idx]);
  }
}