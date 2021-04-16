import 'dart:async';

class StreamManager {
  static StreamManager _instant = StreamManager._internal();
  Map<String, StreamController<dynamic>> _streams = {};

  StreamManager._internal();

  factory StreamManager() {
    return _instant;
  }

  void register(String streamName, StreamController controller) {
    _streams[streamName] = controller;
  }

  StreamController<T>? controller<T>(String streamName, {StreamController? defaultController}) {
    if (defaultController != null) {
      return _putIfAbsent(streamName, defaultController) as StreamController<T>?;
    }
    return _streams[streamName] as StreamController<T>?;
  }

  StreamController? unregister(String streamName) {
    return _streams.remove(streamName);
  }

  Stream<T>? stream<T>(String streamName, {StreamController? defaultController}) {
    if (defaultController != null) {
      return _putIfAbsent(streamName, defaultController)!.stream as Stream<T>?;
    }

    return _streams[streamName]?.stream as Stream<T>?;
  }

  StreamController? _putIfAbsent(String streamName, StreamController controller) {
    if (!_streams.containsKey(streamName)) {
      register(streamName, controller);
    }
    return _streams[streamName];
  }
}
