import 'package:logging/logging.dart';

import '../model/model.dart';
import '../provider/connection.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tuple/tuple.dart';

enum DSConnectionAction { refresh, add, remove, removeAll, edit, select }

class DSConnectionEvent {
  DSConnectionAction action;
  Connection? connection;

  DSConnectionEvent(this.action, this.connection);
}

class DSConnectionState {
  Connection? activeConnection;
  List<Connection?> connections = [];

  DSConnectionState(this.activeConnection, this.connections);
}

class DSConnectionBloc extends Bloc<DSConnectionEvent, DSConnectionState> {
  final l = Logger('DSConnectionBloc');
  late ConnectionProvider _provider;

  DSConnectionBloc(): super(DSConnectionBloc.initialState) {
    if (kIsWeb) {
      _provider = WebConnectionProvider();
    } else {
      _provider = MobileConnectionProvider();
    }
    this.add(DSConnectionEvent(DSConnectionAction.refresh, null));
  }

  void dispose() {}

  static DSConnectionState get initialState {
    return DSConnectionState(null, []);
  }

  @override
  Stream<DSConnectionState> mapEventToState(DSConnectionEvent evt) async* {
    Connection? active;
    List<Connection?> connections = [];

    if (evt.action == DSConnectionAction.refresh) {
      connections = await _provider.getAll();
      active = await _provider.getDefaultConnection();
      if (active == null && connections.length == 1)
        active = connections[0];
      l.info('mapEventToState(); evt.action=${evt.action}, found ${connections.length} connections.');
    }

    // new connection
    if (evt.action == DSConnectionAction.add) {
      if (!_hasConnection(evt.connection!, connections)) {
        await _provider.add(evt.connection);
        connections = await _provider.getAll();
      }
    }

    // remove connection
    if (evt.action == DSConnectionAction.remove) {
      if (_hasConnection(evt.connection!, connections)) {
        var idx = connections.indexWhere((e) => evt.connection!.buildUri() == e!.buildUri());
        await _provider.remove(idx);
        connections = await _provider.getAll();
      }
    }

    // remove all connections
    if (evt.action == DSConnectionAction.removeAll) {
      await _provider.removeAll();
      connections = [];
    }

    // edit connection
    if (evt.action == DSConnectionAction.edit) {
      var found = _find(evt.connection!, connections);
      if (found.item1 != -1) {
        connections = await _provider.replace(found.item1, evt.connection);
      }
    }

    // select connection
    if (evt.action == DSConnectionAction.select) {
      if (_hasConnection(evt.connection!, connections)) {
        await _provider.setDefaultConnection(evt.connection!.buildUri());
        active = evt.connection;
      }
    }

    if (connections.length == 1) active = connections[0];
    if (connections.isEmpty) active = null;
    yield DSConnectionState(active, connections);
  }

  bool _hasConnection(Connection target, List<Connection?> connections) =>
      _find(target, connections).item1 != -1;

  Tuple2<int, Connection?> _find(Connection target, List<Connection?> connections) {
    var uri = target.buildUri();
    return Tuple2(connections.indexWhere((e) => uri == e!.buildUri()),
        connections.firstWhere((e) => uri == e!.buildUri(), orElse: () => null));
  }

  Tuple2<int, Connection?> _findByUri(String uri, List<Connection> connections) {
    return Tuple2(connections.indexWhere((e) => uri == e.buildUri()),
        connections.firstWhereOrNull((e) => uri == e.buildUri()));
  }
}
