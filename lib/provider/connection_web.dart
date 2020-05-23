import 'dart:convert';
import 'dart:html';

import 'package:synodownloadstation/model/model.dart';
import 'package:synodownloadstation/util/const.dart';

import 'connection.dart';

class WebConnectionProvider extends ConnectionProvider {
  static final String _key = StorageKey.Connections.key;

  @override
  Future<void> add(Connection conn) async {
    List<Connection> conns = await getAll();
    conns.add(conn);
    window.sessionStorage[_key] = encodeJson(conns);
  }

  @override
  Future<Connection> get(int idx) {
    return getAll().then((value) => value[idx]);
  }

  @override
  Future<List<Connection>> getAll() {
    if (window.sessionStorage.containsKey(_key) && window.sessionStorage[_key] != '') {
      return Future.value(decodeJson(window.sessionStorage[_key]));
    }
    return Future.value([]);
  }

  @override
  Future<String> getDefaultConnection() async {
    String ret;

    String value = window.sessionStorage[StorageKey.DefaultConnectionIndex.key];
    try {
      Map<String, dynamic> json = jsonDecode(value);
      ret = json['defaultUri'];
    } catch (e) {
      print(e);
    }

    return ret;
  }

  @override
  Future<Connection> remove(int idx) async {
    List<Connection> conns = await getAll();
    Connection ret = conns.removeAt(idx);
    window.sessionStorage[_key] = encodeJson(conns);
    return ret;
  }

  @override
  Future<void> removeAll() {
    window.sessionStorage[_key] = '[]';
  }

  @override
  Future<List<Connection>> replace(int idx, Connection updated) async {
    List<Connection> lst = await getAll();
    lst.replaceRange(idx, idx + 1, [updated]);
    window.sessionStorage[_key] = encodeJson(lst);
    return getAll();
  }

  @override
  Future<void> setDefaultConnection(String uri) {
    window.sessionStorage[StorageKey.DefaultConnectionIndex.key] = jsonEncode({'defaultUri': uri});
  }
}