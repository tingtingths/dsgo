import 'package:dsgo/main.dart';
import 'package:dsgo/util/const.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../datasource/user_settings.dart';

class SettingsPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<SettingsPage> createState() => SettingsPageState();
}

class SettingsPageState extends ConsumerState<SettingsPage> {
  final l = Logger("SettingsPageState");
  final requestIntervalFieldController = TextEditingController();
  final requestIntervalFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    requestIntervalFocusNode.addListener(() {
      if (!requestIntervalFocusNode.hasFocus) {
        // lost focus, check value
        var value;
        try {
          value = int.parse(requestIntervalFieldController.text);
        } catch (ignored) {}
        if (value == null || value < REQUEST_INTERVAL_MIN) {
          requestIntervalFieldController.text = REQUEST_INTERVAL_MIN.toRadixString(10);
          value = REQUEST_INTERVAL_MIN;
        }
        var settings = ref.read(userSettingsProvider.state).state;
        settings.apiRequestFrequency = value;
        ref.read(userSettingsDatastoreProvider).set(settings);
        ref.read(userSettingsProvider.state).state = settings;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer(builder: (context, watch, _) {
      var settings = ref.watch(userSettingsProvider.state).state;
      if (requestIntervalFieldController.text.isEmpty)
        requestIntervalFieldController.text = settings.apiRequestFrequency.toRadixString(10);
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.settings),
        ),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: ListView(
            children: <Widget>[
              ListTile(
                  title: Text(l10n.settingsRequestInterval),
                  leading: Icon(Icons.repeat),
                  trailing: Container(
                    width: 80,
                    child: TextFormField(
                      focusNode: requestIntervalFocusNode,
                      controller: requestIntervalFieldController,
                      keyboardType: TextInputType.number,
                    ),
                  )),
              ListTile(
                title: Text(l10n.theme),
                leading: Icon(Icons.lightbulb_outline),
                trailing: DropdownButton(
                  value: settings.themeMode,
                  items: ThemeMode.values.map((val) {
                    return DropdownMenuItem<ThemeMode>(
                      value: val,
                      child: Text({
                        ThemeMode.system: l10n.settingsThemeSystem,
                        ThemeMode.dark: l10n.settingsThemeDark,
                        ThemeMode.light: l10n.settingsThemeLight,
                      }[val]!),
                    );
                  }).toList(),
                  onChanged: (dynamic val) {
                    settings.themeMode = val;
                    ref.read(userSettingsDatastoreProvider).set(settings);
                    ref.read(userSettingsProvider.state).state = settings.clone();
                  },
                ),
              ),
              ListTile(
                  title: Text(l10n.displayLanguage),
                  leading: Icon(Icons.translate),
                  trailing: DropdownButton(
                    value: settings.locale?.toString() ?? 'system',
                    items: [
                      DropdownMenuItem(value: 'system', child: Text(l10n.settingsDisplayLangSystem)),
                      DropdownMenuItem(value: Locale('en').toString(), child: Text(l10n.settingsDisplayLangEN)),
                      DropdownMenuItem(
                          value: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant').toString(),
                          child: Text(l10n.settingsDisplayLangZhHant))
                    ],
                    onChanged: (dynamic val) {
                      settings.locale = {
                        'System': null,
                        Locale('en').toString(): Locale('en'),
                        Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant').toString():
                            Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
                      }[val];
                      ref.read(userSettingsDatastoreProvider).set(settings);
                      ref.read(userSettingsProvider.state).state = settings.clone();
                    },
                  )),
            ],
          ),
        ),
      );
    });
  }
}
