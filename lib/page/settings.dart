import 'package:dsgo/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datasource/user_settings.dart';
import '../util/const.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer(builder: (context, watch, _) {
      var settings = watch(userSettingsProvider).state;
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
                    width: 50,
                    child: TextFormField(
                      initialValue: settings.apiRequestFrequency.toRadixString(10),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        settings.apiRequestFrequency = int.parse(value);
                        context.read(userSettingsDatastoreProvider).set(settings);
                        context.read(userSettingsProvider).state = settings;
                      },
                    ),
                  )),
              ListTile(
                  title: Text(l10n.theme),
                  leading: Icon(Icons.lightbulb_outline),
                  trailing: Container(
                      width: 100,
                      child: DropdownButton(
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
                          context.read(userSettingsDatastoreProvider).set(settings);
                          context.read(userSettingsProvider).state = settings;
                        },
                      ))),
            ],
          ),
        ),
      );
    });
  }
}
