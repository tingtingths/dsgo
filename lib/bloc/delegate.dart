import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

import '../bloc/connection_bloc.dart';
import '../bloc/syno_api_bloc.dart';
import '../bloc/ui_evt_bloc.dart';

class BlocLogDelegate extends BlocObserver {
  final l = Logger('BlocLogDelegate');

  @override
  void onTransition(Bloc bloc, Transition transition) {
    var currState = transition.currentState;
    var nextState = transition.nextState;
    String state = currState.toString();
    String from = '$currState', to = '$nextState';

    if (currState is DSConnectionState) {
      from =
          'active=${currState.activeConnection}, connections=[${currState.connections.length}]';
      to =
          'active=${nextState.activeConnection}, connections=[${nextState.connections.length}]';
    }
    if (currState is UiEventState) {
      from =
          'initiator=${currState.initiator}, event=${currState.event}';
      to =
          'initiator=${nextState.initiator}, event=${nextState.event}';
    }
    if (currState is SynoApiState) {
      from = 'request_type=${currState.event?.requestType}';
      to = 'request_type=${nextState.event?.requestType}';
    }
    //l.fine('onTransition(); $state [$from] => [$to]');
    super.onTransition(bloc, transition);
  }
}
