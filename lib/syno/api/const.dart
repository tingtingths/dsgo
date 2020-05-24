const String UNKNOWN = "Unknown";

class Syno {
  static final _name = 'SYNO';

  static _Api get API => _Api(_name);

  static _Ds get DownloadStation => _Ds(_name);
}

class _Api {
  final _name = 'API';
  String _base;

  _Api(this._base);

  String get Info => [_base, _name, 'Info'].join('.');

  String get Auth => [_base, _name, 'Auth'].join('.');
}

class _Ds {
  final _name = 'DownloadStation';
  String _base;

  _Ds(this._base);

  String get Info => [_base, _name, 'Info'].join('.');

  String get Schedule => [_base, _name, 'Schedule'].join('.');

  String get Task => [_base, _name, 'Task'].join('.');

  String get Statistic => [_base, _name, 'Statistic'].join('.');

  String get BTSearch => [_base, _name, 'BTSearch'].join('.');

  _Rss get RSS => _Rss([_base, _name].join('.'));
}

class _Rss {
  final _name = 'RSS';
  String _base;

  _Rss(this._base);

  String get Site => [_base, _name, 'Site'].join('.');

  String get Feed => [_base, _name, 'Feed'].join('.');
}
