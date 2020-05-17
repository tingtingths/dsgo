import 'package:flutter_bloc/flutter_bloc.dart';

class UiEventState {
  dynamic initiator;
  String name;
  List<dynamic> payload = [];

  UiEventState(this.initiator, this.name, this.payload);

  UiEventState.noPayload(this.initiator, this.name);

  UiEventState.empty();
}

class UiEventBloc extends Bloc<UiEventState, UiEventState> {
  @override
  UiEventState get initialState => UiEventState.empty();

  @override
  Stream<UiEventState> mapEventToState(UiEventState event) async* {
    yield event;
  }
}
