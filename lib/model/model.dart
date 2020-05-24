class ConnectionMenuItem {
  var _type = 1;
  dynamic _value;

  static const CONN = 1;
  static const ADD = 2;

  ConnectionMenuItem(this._type, dynamic _value);

  dynamic get value => _value;

  get type => _type;
}

class Connection {
  String friendlyName;
  String proto;
  String user;
  String host;
  int port;
  String sid;
  String password;
  DateTime created;
  DateTime updated;

  Connection.empty();

  Connection.withoutCredential(
      this.friendlyName, this.proto, this.user, this.host, this.port);

  Connection(this.friendlyName, this.proto, this.user, this.host, this.port,
      this.sid, this.password);

  String buildUri() =>
      Uri(scheme: proto, userInfo: user, host: host, port: port).toString();

  Connection.fromJson(Map<String, dynamic> json) {
    friendlyName = (json ?? {})['friendlyName'];
    proto = (json ?? {})['proto'];
    user = (json ?? {})['user'];
    host = (json ?? {})['host'];
    port = (json ?? {})['port'];
    sid = (json ?? {})['sid'];
    password = (json ?? {})['password'];

    int createdTs = (json ?? {})['created'];
    created = createdTs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(createdTs);

    int updatedTs = (json ?? {})['updated'];
    updated = updatedTs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(updatedTs);
  }

  Map<String, dynamic> toJson() => {
        'friendlyName': friendlyName,
        'proto': proto,
        'user': user,
        'host': host,
        'port': port,
        'sid': sid,
        'password': password,
        'created': created?.millisecondsSinceEpoch,
        'updated': updated?.millisecondsSinceEpoch,
      };
}
