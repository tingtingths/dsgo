import 'package:flutter/material.dart';

const String STYLED_APP_NAME = 'DS Go';
const int REQUEST_INTERVAL_DEFAULT = 5000;
const int REQUEST_INTERVAL_MIN = 500;

enum StorageKey { Connections, DefaultConnectionIndex, UserSettings }

extension StorageKeyMembers on StorageKey {
  String get key =>
      const {
        StorageKey.Connections: 'STORE_KEY_CONNECTIONS',
        StorageKey.DefaultConnectionIndex: 'STORE_KEY_DEF_CONNECTION_IDX',
        StorageKey.UserSettings: 'STORE_KEY_USER_SETTINGS',
      }[this] ??
      '';
}

enum StreamKey { ActiveConnectionChange, ConnectionsChange }

extension StreamKeyMembers on StreamKey {
  String get key =>
      const {
        StreamKey.ActiveConnectionChange: 'STREAM_ACTIVE_CONNECTION_CHANGE',
        StreamKey.ConnectionsChange: 'STREAM_CONNECTIONS_CHANGE',
      }[this] ??
      '';
}

extension ThemeModeMembers on ThemeMode {
  String get text =>
      const {
        ThemeMode.light: 'Light',
        ThemeMode.dark: 'Dark',
        ThemeMode.system: 'System',
      }[this] ??
      '';
}
