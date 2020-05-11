class APIResponse<T> {
  bool _success;
  T _data;
  Map<String, dynamic> _error;

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

class APIInfoQuery {
  String _key;
  String _path;
  int _minVersion;
  int _maxVersion;

  int get maxVersion => _maxVersion;

  int get minVersion => _minVersion;

  String get path => _path;

  String get key => _key;

  APIInfoQuery.fromJson(Map<String, dynamic> json) {
    _key = (json ?? {})['key'];
    _path = (json ?? {})['path'];
    _minVersion = (json ?? {})['minVersion'];
    _maxVersion = (json ?? {})['maxVersion'];
  }
}

class DownloadStationInfoGetInfo {
  int _version;
  String _versionString;
  bool _isManager;

  int get version => _version;

  String get versionString => _versionString;

  bool get isManager => _isManager;

  DownloadStationInfoGetInfo.fromJson(Map<String, dynamic> json) {
    _version = (json ?? {})['version'];
    _versionString = (json ?? {})['version_string'];
    _isManager = (json ?? {})['is_manager'];
  }
}

class DownloadStationInfoGetConfig {
  int _btMaxDownload;
  int _btMaxUpload;
  int _emuleMaxDownload;
  int _emuleMaxUpload;
  int _nzbMaxDownload;
  int _httpMaxDownload;
  int _ftpMaxDownload;
  bool _emuleEnabled;
  bool _unzipServiceEnabled;
  String _defaultDestination;
  String _emuleDefaultDestination;

  DownloadStationInfoGetConfig.fromJson(Map<String, dynamic> json) {
    _btMaxDownload = (json ?? {})['bt_max_download'];
    _btMaxUpload = (json ?? {})['bt_max_upload'];
    _emuleMaxDownload = (json ?? {})['emule_max_download'];
    _emuleMaxUpload = (json ?? {})['emule_max_upload'];
    _nzbMaxDownload = (json ?? {})['nzb_max_download'];
    _httpMaxDownload = (json ?? {})['http_max_download'];
    _ftpMaxDownload = (json ?? {})['ftp_max_download'];
    _emuleEnabled = (json ?? {})['emule_enabled'];
    _unzipServiceEnabled = (json ?? {})['unzip_service_enabled'];
    _defaultDestination = (json ?? {})['default_destination'];
    _emuleDefaultDestination = (json ?? {})['emule_default_destination'];
  }

  int get btMaxDownload => _btMaxDownload;

  int get btMaxUpload => _btMaxUpload;

  int get emuleMaxDownload => _emuleMaxDownload;

  int get emuleMaxUpload => _emuleMaxUpload;

  int get nzbMaxDownload => _nzbMaxDownload;

  int get httpMaxDownload => _httpMaxDownload;

  int get ftpMaxDownload => _ftpMaxDownload;

  bool get emuleEnabled => _emuleEnabled;

  bool get unzipServiceEnabled => _unzipServiceEnabled;

  String get defaultDestination => _defaultDestination;

  String get emuleDefaultDestination => _emuleDefaultDestination;
}

class DownloadStationScheduleGetConfig {
  bool _enabled;
  bool _emuleEnabled;

  DownloadStationScheduleGetConfig.fromJson(Map<String, dynamic> json) {
    _enabled = (json ?? {})['enabled'];
    _emuleEnabled = (json ?? {})['emule_enabled'];
  }

  bool get emuleEnabled => _emuleEnabled;

  bool get enabled => _enabled;
}

class DownloadStationStatisticGetInfo {
  int _speedDownload;
  int _speedUpload;
  int _emuleSpeedDownload;
  int _emuleSpeedUpload;

  DownloadStationStatisticGetInfo.fromJson(Map<String, dynamic> json) {
    _speedDownload = (json ?? {})['speed_download'];
    _speedUpload = (json ?? {})['speed_upload'];
    _emuleSpeedDownload = (json ?? {})['emule_speed_download'];
    _emuleSpeedUpload = (json ?? {})['emule_speed_upload'];
  }

  int get emuleSpeedUpload => _emuleSpeedUpload;

  int get emuleSpeedDownload => _emuleSpeedDownload;

  int get speedUpload => _speedUpload;

  int get speedDownload => _speedDownload;
}

class _DownloadStationTaskActionResponse {
  String _id;
  int _error;

  _DownloadStationTaskActionResponse.fromJson(Map<String, dynamic> json) {
    _id = (json ?? {})['id'];
    _error = (json ?? {})['error'];
  }

  int get error => _error;

  String get id => _id;
}

class DownloadStationTaskDelete extends _DownloadStationTaskActionResponse {
  DownloadStationTaskDelete.fromJson(Map<String, dynamic> json)
      : super.fromJson(json);
}

class DownloadStationTaskPause extends _DownloadStationTaskActionResponse {
  DownloadStationTaskPause.fromJson(Map<String, dynamic> json)
      : super.fromJson(json);
}

class DownloadStationTaskResume extends _DownloadStationTaskActionResponse {
  DownloadStationTaskResume.fromJson(Map<String, dynamic> json)
      : super.fromJson(json);
}

class DownloadStationTaskEdit extends _DownloadStationTaskActionResponse {
  DownloadStationTaskEdit.fromJson(Map<String, dynamic> json)
      : super.fromJson(json);
}

class ListTaskInfo {
  int _total;
  int _offset;
  List<Task> _tasks;

  int get total => _total;

  int get offset => _offset;

  List<Task> get tasks => _tasks;

  ListTaskInfo.fromJson(Map<String, dynamic> json) {
    _total = (json ?? {})['total'];
    _offset = (json ?? {})['offset'];
    if (json.containsKey('tasks')) {
      _tasks = [];
      List<dynamic> tasks = (json ?? {})['tasks'];
      _tasks.addAll(tasks.map((e) => Task.fromJson(e)).toList());
    }
  }
}

class Task {
  String _id;
  String _type;
  String _username;
  String _title;
  int _size;
  String _status;
  StatusExtra _statusExtra;
  Additional _additional;

  String get id => _id;

  String get type => _type;

  String get username => _username;

  String get title => _title;

  int get size => _size;

  String get status => _status;

  StatusExtra get statusExtra => _statusExtra;

  Additional get additional => _additional;

  Task.fromJson(Map<String, dynamic> json) {
    _id = (json ?? {})['id'];
    _type = (json ?? {})['type'];
    _username = (json ?? {})['username'];
    _title = (json ?? {})['title'];
    _size = (json ?? {})['size'];
    _status = (json ?? {})['status'];
    _statusExtra = StatusExtra.fromJson((json ?? {})['status_extra']);
    _additional = Additional.fromJson((json ?? {})['additional']);
  }
}

class Additional {
  TaskDetail _detail;
  TaskTransfer _transfer;
  List<TaskFile> _file;
  List<TaskTracker> _tracker;
  List<TaskPeer> _peer;

  Additional.fromJson(Map<String, dynamic> json) {
    _detail = TaskDetail.fromJson((json ?? {})['detail']);
    _transfer = TaskTransfer.fromJson((json ?? {})['transfer']);
    _file = ((json ?? {}).containsKey('file') ? json['file'] as List : [])
        .map((e) => TaskFile.fromJson(e))
        .toList();
    _tracker =
        ((json ?? {}).containsKey('tracker') ? json['tracker'] as List : [])
            .map((e) => TaskTracker.fromJson(e))
            .toList();
    _peer = ((json ?? {}).containsKey('peer') ? json['peer'] as List : [])
        .map((e) => TaskPeer.fromJson(e))
        .toList();
  }

  List<TaskPeer> get peer => _peer;

  List<TaskTracker> get tracker => _tracker;

  List<TaskFile> get file => _file;

  TaskTransfer get transfer => _transfer;

  TaskDetail get detail => _detail;
}

class StatusExtra {
  String _errorDetail;
  int _unzipProgress;

  StatusExtra.fromJson(Map<String, dynamic> json) {
    _errorDetail = (json ?? {})['error_detail'];
    _errorDetail = (json ?? {})['error_detail'];
    _unzipProgress = (json ?? {})['unzip_progress'];
  }
}

class TaskDetail {
  String _destination;
  String _uri;
  DateTime _createTime;
  String _priority;
  int _totalPeers;
  int _connectedSeeders;
  int _connectedLeechers;

  TaskDetail.fromJson(Map<String, dynamic> json) {
    _destination = (json ?? {})['destination'];
    _uri = (json ?? {})['uri'];
    try {
      String createTimeStr = (json ?? {})['create_time'];
      _createTime =
          DateTime.fromMillisecondsSinceEpoch(int.parse(createTimeStr) * 1000);
    } catch (ignored) {}
    _priority = (json ?? {})['priority'];
    _totalPeers = (json ?? {})['total_peers'];
    _connectedSeeders = (json ?? {})['connected_seeders'];
    _connectedLeechers = (json ?? {})['connected_leechers'];
  }

  int get connectedLeechers => _connectedLeechers;

  int get connectedSeeders => _connectedSeeders;

  int get totalPeers => _totalPeers;

  String get priority => _priority;

  DateTime get createTime => _createTime;

  String get uri => _uri;

  String get destination => _destination;
}

class TaskTransfer {
  int _downloadedPieces;
  int _sizeDownloaded;
  int _sizeUploaded;
  int _speedDownload;
  int _speedUpload;

  TaskTransfer.fromJson(Map<String, dynamic> json) {
    _downloadedPieces = (json ?? {})['downloaded_pieces'];
    _sizeDownloaded = (json ?? {})['size_downloaded'];
    _sizeUploaded = (json ?? {})['size_uploaded'];
    _speedDownload = (json ?? {})['speed_download'];
    _speedUpload = (json ?? {})['speed_upload'];
  }

  int get speedUpload => _speedUpload;

  int get speedDownload => _speedDownload;

  int get sizeUploaded => _sizeUploaded;

  int get sizeDownloaded => _sizeDownloaded;

  int get downloadedPieces => _downloadedPieces;
}

class TaskFile {
  String _filename;
  int _size;
  int _sizeDownloaded;
  String _priority;
  bool _wanted;

  TaskFile.fromJson(Map<String, dynamic> json) {
    _filename = (json ?? {})['filename'];
    _size = (json ?? {})['size'];
    _sizeDownloaded = (json ?? {})['size_downloaded'];
    _priority = (json ?? {})['priority'];
    _wanted = (json ?? {})['wanted'];
  }

  String get priority => _priority;

  int get sizeDownloaded => _sizeDownloaded;

  int get size => _size;

  String get filename => _filename;

  bool get wanted => _wanted;
}

class TaskTracker {
  String _url;
  String _status;
  int _updateTimer;
  int _seeds;
  int _peers;

  TaskTracker.fromJson(Map<String, dynamic> json) {
    _url = (json ?? {})['url'];
    _status = (json ?? {})['status'];
    _updateTimer = (json ?? {})['update_timer'];
    _seeds = (json ?? {})['seeds'];
    _peers = (json ?? {})['peers'];
  }

  int get peers => _peers;

  int get seeds => _seeds;

  int get updateTimer => _updateTimer;

  String get status => _status;

  String get url => _url;
}

class TaskPeer {
  String _address;
  String _agent;
  num _progress;
  int _speedDownload;
  int _speedUpload;

  TaskPeer.fromJson(Map<String, dynamic> json) {
    _address = (json ?? {})['address'];
    _agent = (json ?? {})['agent'];
    _progress = (json ?? {})['progress'];
    _speedDownload = (json ?? {})['speed_download'];
    _speedUpload = (json ?? {})['speed_upload'];
  }

  int get speedUpload => _speedUpload;

  int get speedDownload => _speedDownload;

  num get progress => _progress;

  String get agent => _agent;

  String get address => _address;
}
