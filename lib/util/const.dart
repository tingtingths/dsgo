enum StorageKey { Connections, DefaultConnectionIndex }

extension StorageKeyMembers on StorageKey {
  String get key => const {
        StorageKey.Connections: 'STORE_KEY_CONNECTIONS',
        StorageKey.DefaultConnectionIndex: 'STORE_KEY_DEF_CONNECTION_IDX',
      }[this];
}

enum StreamKey { ActiveConnectionChange, ConnectionsChange }

extension StreamKeyMembers on StreamKey {
  String get key => const {
        StreamKey.ActiveConnectionChange: 'STREAM_ACTIVE_CONNECTION_CHANGE',
        StreamKey.ConnectionsChange: 'STREAM_CONNECTIONS_CHANGE',
      }[this];
}
