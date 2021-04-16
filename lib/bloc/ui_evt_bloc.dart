import 'package:flutter_bloc/flutter_bloc.dart';

enum UiEvent {
  add_task,
  task_fetching,
  tasks_fetched,
  tasks_filter_change,
  close_slide_panel,
  post_frame,
}

class UiEventState {
  dynamic initiator;
  UiEvent event;
  List<dynamic> payload = [];

  UiEventState(this.initiator, this.event, this.payload);

  UiEventState.noPayload(this.initiator, this.event);

  UiEventState.empty();
}

class UiEventBloc extends Bloc<UiEventState, UiEventState> {
  UiEventBloc() : super(UiEventState.empty());

  @override
  Stream<UiEventState> mapEventToState(UiEventState event) async* {
    yield event;
  }
}
