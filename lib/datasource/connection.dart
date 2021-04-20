import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:localstorage/localstorage.dart';
import 'package:logging/logging.dart';
import 'package:tuple/tuple.dart';

import '../model/model.dart';
import '../util/const.dart';

final connectionDatastoreProvider =
    Provider((ref) => kIsWeb ? WebConnectionDatasource() : MobileConnectionDatasource());

abstract class ConnectionDatasource {
  ConnectionDatasource();

  Future<String?> getDefaultConnectionUri();

  Future<Connection?> getDefaultConnection() async {
    String? uri = await getDefaultConnectionUri();
    var connections = await getAll();

    return _findByUri(uri, connections)?.item2;
  }

  Future<void> setDefaultConnection(String uri);

  Future<List<Connection>> getAll();

  Future<void> add(Connection? conn);

  Future<Connection?> remove(int idx);

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

  String encodeJson(List<Connection?> connections) {
    List<dynamic> lst = [];
    connections.forEach((e) {
      lst.add(e!.toJson());
    });
    return jsonEncode(lst);
  }

  Tuple2<int, Connection>? _findByUri(String? uri, List<Connection> connections) {
    var idx = connections.indexWhere((e) => uri == e.buildUri());
    if (idx == -1) return null;
    var conn = connections[idx];
    return Tuple2(idx, conn);
  }
}

class WebConnectionDatasource extends ConnectionDatasource {
  final l = Logger('WebConnectionProvider');
  static final String _key = StorageKey.Connections.key;
  final LocalStorage _storage = new LocalStorage('_dsgo');

  @override
  Future<void> add(Connection? conn) async {
    List<Connection?> conns = await getAll();
    conns.add(conn);
    _set(encodeJson(conns));
  }

  @override
  Future<Connection> get(int idx) {
    return getAll().then((value) => value[idx]);
  }

  @override
  Future<List<Connection>> getAll() {
    return _storage.ready.then((ready) {
      var json = _storage.getItem(_key) as String;
      return decodeJson(json);
    });
  }

  @override
  Future<String?> getDefaultConnectionUri() async {
    return _storage.ready.then((ready) {
      String? value = _storage.getItem(StorageKey.DefaultConnectionIndex.key);
      if (value == null) return null;
      try {
        Map<String, dynamic> json = jsonDecode(value);
        return json['defaultUri'];
      } catch (e) {
        l.severe('getDefaultConnectionUri(); failed.', e);
      }
    });
  }

  @override
  Future<Connection?> remove(int idx) async {
    List<Connection?> conns = await getAll();
    Connection? ret = conns.removeAt(idx);
    _set(encodeJson(conns));
    return ret;
  }

  @override
  Future<void> removeAll() async {
    _set('[]');
  }

  @override
  Future<List<Connection>> replace(int idx, Connection updated) async {
    List<Connection> lst = await getAll();
    lst.replaceRange(idx, idx + 1, [updated]);
    _set(encodeJson(lst));
    return getAll();
  }

  @override
  Future<void> setDefaultConnection(String uri) async {
    _storage.ready.then((ready) {
      _storage.setItem(StorageKey.DefaultConnectionIndex.key, jsonEncode({'defaultUri': uri}));
    });
  }

  Future<void> _set(String? json) async {
    return _storage.ready.then((ready) {
      _storage.setItem(_key, json);
    });
  }
}

class MobileConnectionDatasource extends ConnectionDatasource {
  final l = Logger('MobileConnectionProvider');
  static MobileConnectionDatasource _instance = MobileConnectionDatasource._internal();
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  static final String _key = StorageKey.Connections.key;

  factory MobileConnectionDatasource() {
    return _instance;
  }

  MobileConnectionDatasource._internal();

  @override
  Future<String?> getDefaultConnectionUri() async {
    String? ret;

    List<Connection?> connections = await getAll();
    if (connections.length == 1) {
      return connections[0]!.buildUri();
    }

    String? value = await (_storage.read(key: StorageKey.DefaultConnectionIndex.key));
    if (value == null) return ret;
    try {
      Map<String, dynamic> json = jsonDecode(value);
      ret = json['defaultUri'];
    } catch (e) {
      l.severe('getDefaultConnectionUri(); failed', e);
    }

    return ret;
  }

  @override
  Future<void> setDefaultConnection(String? uri) async {
    await _storage.write(key: StorageKey.DefaultConnectionIndex.key, value: jsonEncode({'defaultUri': uri}));
  }

  @override
  Future<List<Connection>> getAll() async {
    String? value = await (_storage.read(key: _key));
    if (value == null) return [];
    return decodeJson(value);
  }

  @override
  Future<void> add(Connection? conn) async {
    List<Connection?> connections = await getAll();
    connections.add(conn);
    await _storage.write(key: _key, value: encodeJson(connections));
  }

  @override
  Future<Connection?> remove(int idx) async {
    List<Connection?> connections = await getAll();
    Connection? ret = connections.removeAt(idx);
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
