import 'dart:async';
import 'dart:convert';

import '../model/model.dart';
import '../util/const.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tuple/tuple.dart';

abstract class ConnectionProvider {
  ConnectionProvider();

  Future<String> getDefaultConnectionUri();

  Future<Connection> getDefaultConnection() async {
    String uri = await getDefaultConnectionUri();
    var connections = await getAll();

    return _findByUri(uri, connections).item2;
  }

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

  Tuple2<int, Connection> _findByUri(String uri, List<Connection> connections) {
    return Tuple2(connections.indexWhere((e) => uri == e.buildUri()),
        connections?.firstWhere((e) => uri == e.buildUri(), orElse: () => null));
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
  Future<String> getDefaultConnectionUri() async {
    String ret;

    List<Connection> connections = await getAll();
    if (connections != null && connections.length == 1) {
      return connections[0].buildUri();
    }

    String value = await _storage.read(key: StorageKey.DefaultConnectionIndex.key);
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
    await _storage.write(key: StorageKey.DefaultConnectionIndex.key, value: jsonEncode({'defaultUri': uri}));
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
