import 'package:logging/logging.dart';

import '../model/model.dart';
import '../datasource/connection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tuple/tuple.dart';

enum DSConnectionAction { refresh, add, remove, removeAll, edit, select }

class DSConnectionEvent {
  DSConnectionAction action;
  int? idx;
  Connection? connection;

  DSConnectionEvent(this.action, this.connection, this.idx);

  DSConnectionEvent.noPayload(this.action);
}

class DSConnectionState {
  Connection? activeConnection;
  List<Connection?> connections = [];

  DSConnectionState(this.activeConnection, this.connections);
}

class DSConnectionBloc extends Bloc<DSConnectionEvent, DSConnectionState> {
  final l = Logger('DSConnectionBloc');
  late ConnectionDatasource _datasource;

  DSConnectionBloc(): super(DSConnectionBloc.initialState) {
    if (kIsWeb) {
      _datasource = WebConnectionDatasource();
    } else {
      _datasource = MobileConnectionDatasource();
    }
    this.add(DSConnectionEvent.noPayload(DSConnectionAction.refresh));
  }

  void dispose() {}

  static DSConnectionState get initialState {
    return DSConnectionState(null, []);
  }

  @override
  Stream<DSConnectionState> mapEventToState(DSConnectionEvent evt) async* {
    Connection? active = await _datasource.getDefaultConnection();
    List<Connection> connections = await _datasource.getAll();

    if (evt.action == DSConnectionAction.refresh) {
      if (active == null && connections.length == 1)
        active = connections[0];
      l.info('mapEventToState(); evt.action=${evt.action}, found ${connections.length} connections.');
    }

    // new connection
    if (evt.action == DSConnectionAction.add) {
      if (!_hasConnection(evt.connection!, connections)) {
        await _datasource.add(evt.connection);
        connections = await _datasource.getAll();
      }
    }

    // remove connection
    if (evt.action == DSConnectionAction.remove) {
      if (_hasConnection(evt.connection!, connections)) {
        var idx = connections.indexWhere((e) => evt.connection!.buildUri() == e.buildUri());
        await _datasource.remove(idx);
        connections = await _datasource.getAll();
      }
    }

    // remove all connections
    if (evt.action == DSConnectionAction.removeAll) {
      await _datasource.removeAll();
      connections = [];
    }

    // edit connection
    if (evt.action == DSConnectionAction.edit) {
      var idx = evt.idx;
      if (idx != null && connections.length > idx && evt.connection != null) {
        connections = await _datasource.replace(idx, evt.connection!);
      }
    }

    // select connection
    if (evt.action == DSConnectionAction.select) {
      if (_hasConnection(evt.connection!, connections)) {
        await _datasource.setDefaultConnection(evt.connection!.buildUri());
        active = evt.connection;
      }
    }

    if (connections.length == 1) active = connections[0];
    if (connections.isEmpty) active = null;
    yield DSConnectionState(active, connections);
  }

  bool _hasConnection(Connection target, List<Connection> connections) =>
      _find(target, connections) != null;

  Tuple2<int, Connection>? _find(Connection target, List<Connection> connections) {
    var uri = target.buildUri();
    var idx = connections.indexWhere((e) => uri == e.buildUri());
    if (idx == -1) return null;
    return Tuple2(idx, connections[idx]);
  }
}
