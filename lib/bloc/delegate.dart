import 'package:dsgo/bloc/connection_bloc.dart';
import 'package:dsgo/bloc/syno_api_bloc.dart';
import 'package:dsgo/bloc/ui_evt_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BlocLogDelegate extends BlocDelegate {
  @override
  void onTransition(Bloc bloc, Transition transition) {
    var currState = transition.currentState;
    var nextState = transition.nextState;
    String from = '$currState', to = '$nextState';

    if (currState is ConnectionState) {
      from =
          'ConnectionState | active=${currState.activeConnection}, connections=[${currState.connections.length}]';
      to =
          'ConnectionState | active=${nextState.activeConnection}, connections=[${nextState.connections.length}]';
    }
    if (currState is UiEventState) {
      from =
          'UiEventState | initiator=${currState.initiator}, event=${currState.event}';
      to =
          'UiEventState | initiator=${nextState.initiator}, event=${nextState.event}';
    }
    if (currState is SynoApiState) {
      from = 'SynoApiState | request_type=${currState.event?.requestType}';
      to = 'SynoApiState | request_type=${nextState.event?.requestType}';
    }
    print('from => $to');
    super.onTransition(bloc, transition);
  }
}
