import '../model/model.dart';
import '../provider/connection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tuple/tuple.dart';

enum DSConnectionAction { add, remove, removeAll, edit, select }

class DSConnectionEvent {
  DSConnectionAction action;
  Connection connection;

  DSConnectionEvent(this.action, this.connection);
}

class DSConnectionState {
  Connection activeConnection;
  List<Connection> connections = [];

  DSConnectionState(this.activeConnection, this.connections);
}

class DSConnectionBloc extends Bloc<DSConnectionEvent, DSConnectionState> {
  ConnectionProvider _provider;
  List<Connection> _connections = [];
  Connection _active;
  DSConnectionState currentState;

  DSConnectionBloc(DSConnectionState initialState) : super(initialState);

  void dispose() {}

  @override
  DSConnectionState get initialState {
    if (kIsWeb) {
      //_provider = WebConnectionProvider();
    } else {
      _provider = MobileConnectionProvider();
    }

    _provider.getAll().then((connections) async {
      _connections = connections;
      return await _provider.getDefaultConnection();
    }).then((defaultConn) {
      _active = defaultConn;
      this.add(DSConnectionEvent(null, null));
    });

    return DSConnectionState(_active, _connections);
  }

  @override
  Stream<DSConnectionState> mapEventToState(DSConnectionEvent evt) async* {
    // new connection
    if (evt.action == DSConnectionAction.add) {
      if (!_hasConnection(evt.connection)) {
        await _provider.add(evt.connection);
        _connections = await _provider.getAll();
      }
    }

    // remove connection
    if (evt.action == DSConnectionAction.remove) {
      if (_hasConnection(evt.connection)) {
        var idx = _connections.indexWhere((e) => evt.connection.buildUri() == e.buildUri());
        await _provider.remove(idx);
        _connections = await _provider.getAll();
      }
    }

    // remove all connections
    if (evt.action == DSConnectionAction.removeAll) {
      await _provider.removeAll();
      _connections = [];
    }

    // edit connection
    if (evt.action == DSConnectionAction.edit) {
      var found = _find(evt.connection);
      if (found.item1 != -1) {
        _connections = await _provider.replace(found.item1, evt.connection);
      }
    }

    // select connection
    if (evt.action == DSConnectionAction.select) {
      if (_hasConnection(evt.connection)) {
        await _provider.setDefaultConnection(evt.connection.buildUri());
        _active = evt.connection;
      }
    }

    if (_connections.length == 1) _active = _connections[0];
    if (_connections.isEmpty) _active = null;
    currentState = DSConnectionState(_active, _connections);
    yield currentState;
  }

  bool _hasConnection(Connection target) => _find(target).item1 != -1;

  Tuple2<int, Connection> _find(Connection target) {
    var uri = target.buildUri();
    return Tuple2(_connections.indexWhere((e) => uri == e.buildUri()),
        _connections?.firstWhere((e) => uri == e.buildUri(), orElse: () => null));
  }

  Tuple2<int, Connection> _findByUri(String uri) {
    return Tuple2(_connections.indexWhere((e) => uri == e.buildUri()),
        _connections?.firstWhere((e) => uri == e.buildUri(), orElse: () => null));
  }
}
