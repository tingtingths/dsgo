import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:synodownloadstation/bloc/connection_bloc.dart';
import 'package:synodownloadstation/bloc/ui_evt_bloc.dart';

class BlocLogDelegate extends BlocDelegate {
  @override
  void onTransition(Bloc bloc, Transition transition) {
    var currState = transition.currentState;
    var nextState = transition.nextState;
    String from = '$currState', to = '$nextState';

    if (currState is ConnectionState) {
      from =
          'active=${currState.activeConnection}, connections=[${currState.connections.length}]';
      to =
          'active=${nextState.activeConnection}, connections=[${nextState.connections.length}]';
    }
    if (currState is UiEventState) {
      from = 'initiator=${currState.initiator}, event=${currState.event}';
      to = 'initiator=${nextState.initiator}, event=${nextState.event}';
    }

    print('from => $to');
    super.onTransition(bloc, transition);
  }
}
