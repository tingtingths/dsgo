abstract class JsonSerializable<T> {
  T fromJson(Map<String, dynamic> json);
}

class APIResponse<T> {
  bool _success;
  T _data;
  Map<String, dynamic> _error;

  APIResponse.empty();
  APIResponse(this._success, this._data, this._error);

  Map<String, dynamic> get error => _error;

  T get data => _data;

  bool get success => _success;

  APIResponse.fromJson(
      Map<String, dynamic> json, T create(Map<String, dynamic> data)) {
    _success = (json ?? {})['success'];
    _error = (json ?? {})['error'];

    if (json.containsKey('data')) {
      _data = create((json ?? {})['data']);
    }
  }
}

class APIInfo implements JsonSerializable<APIInfo> {
  String _key;
  String _path;
  int _minVersion;
  int _maxVersion;

  APIInfo.empty();
  APIInfo(this._key, this._path, this._minVersion, this._maxVersion);

  int get maxVersion => _maxVersion;

  int get minVersion => _minVersion;

  String get path => _path;

  String get key => _key;

  @override
  APIInfo fromJson(Map<String, dynamic> json) {
    _key = (json ?? {})['key'];
    _path = (json ?? {})['path'];
    _minVersion = (json ?? {})['minVersion'];
    _maxVersion = (json ?? {})['maxVersion'];

    return this;
  }
}

class ListTaskInfo implements JsonSerializable<ListTaskInfo> {
  int _total;
  int _offset;
  List<Task> _tasks;

  ListTaskInfo.empty();
  ListTaskInfo(this._total, this._offset, this._tasks);

  int get total => _total;

  int get offset => _offset;

  List<Task> get tasks => _tasks;

  @override
  ListTaskInfo fromJson(Map<String, dynamic> json) {
    _total = (json ?? {})['total'];
    _offset = (json ?? {})['offset'];
    if (json.containsKey('tasks')) {
      _tasks = [];
      List<dynamic> tasks = (json ?? {})['tasks'];
      _tasks.addAll(tasks.map((e) => Task.empty().fromJson(e)).toList());
    }

    return this;
  }
}

class Task implements JsonSerializable<Task> {
  String _id;
  String _type;
  String _username;
  String _title;
  int _size;
  String _status;
  StatusExtra _statusExtra;
  Additional _additional;

  Task.empty();

  Task(this._id, this._type, this._username, this._title, this._size,
      this._status, this._statusExtra, this._additional);

  String get id => _id;

  String get type => _type;

  String get username => _username;

  String get title => _title;

  int get size => _size;

  String get status => _status;

  StatusExtra get statusExtra => _statusExtra;

  Additional get additional => _additional;

  @override
  Task fromJson(Map<String, dynamic> json) {
    _id = (json ?? {})['id'];
    _type = (json ?? {})['type'];
    _username = (json ?? {})['username'];
    _title = (json ?? {})['title'];
    _size = (json ?? {})['size'];
    _status = (json ?? {})['status'];
    _statusExtra = StatusExtra.empty().fromJson((json ?? {})['status_extra']);

    return this;
  }
}

class Additional {}

class StatusExtra implements JsonSerializable<StatusExtra> {
  String _errorDetail;
  int _unzipProgress;

  StatusExtra.empty();
  StatusExtra(this._errorDetail, this._unzipProgress);

  @override
  StatusExtra fromJson(Map<String, dynamic> json) {
    _errorDetail = (json ?? {})['error_detail'];
    _errorDetail =  (json ?? {})['error_detail'];
    _unzipProgress = (json ?? {})['unzip_progress'];

    return this;
  }
}
