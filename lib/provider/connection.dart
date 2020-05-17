import 'dart:convert';
import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:synodownloadstation/model/model.dart';
import 'package:synodownloadstation/util/const.dart';

class ConnectionProvider {
  static ConnectionProvider _instance = ConnectionProvider._internal();
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  static final String _key = StorageKey.Connections.key;

  factory ConnectionProvider() {
    return _instance;
  }

  ConnectionProvider._internal();

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

  Future<void> setDefaultConnection(String uri) async {
    await _storage.write(
        key: StorageKey.DefaultConnectionIndex.key,
        value: jsonEncode({'defaultUri': uri}));
  }

  Future<List<Connection>> getAll() async {
    List<Connection> ret = [];

    String value = await _storage.read(key: _key);
    try {
      List<dynamic> jsonArr = jsonDecode(value);
      jsonArr.forEach((json) {
        ret.add(Connection.fromJson(json));
      });
    } catch (e) {}

    return ret;
  }

  Future<void> add(Connection conn) async {
    List<Connection> connections = await getAll();
    connections.add(conn);
    await _storage.write(key: _key, value: _encodeJson(connections));
  }

  Future<Connection> remove(int idx) async {
    List<Connection> connections = await getAll();
    Connection ret = connections.removeAt(idx);
    await _storage.write(key: _key, value: _encodeJson(connections));
    return ret;
  }

  Future<void> removeAll() async {
    await setDefaultConnection(null);
    await _storage.write(key: _key, value: _encodeJson([]));
  }

  Future<List<Connection>> replace(int idx, Connection updated) async {
    List<Connection> lst = await getAll();
    lst.replaceRange(idx, idx + 1, [updated]);
    await _storage.write(key: _key, value: _encodeJson(lst));
    return getAll();
  }

  Future<Connection> get(int idx) async {
    return await getAll().then((value) => value[idx]);
  }

  String _encodeJson(List<Connection> connections) {
    List<dynamic> lst = [];
    connections.forEach((e) {
      lst.add(e.toJson());
    });
    return jsonEncode(lst);
  }
}
