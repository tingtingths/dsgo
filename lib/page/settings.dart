import 'package:dsgo/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datasource/user_settings.dart';
import '../util/const.dart';

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
    return Consumer(builder: (context, watch, _) {
      var settings = watch(userSettingsProvider).state;
      return Scaffold(
        appBar: AppBar(
          title: Text('Settings'),
        ),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: ListView(
            children: <Widget>[
              ListTile(
                  title: Text('Data request interval'),
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
                  title: Text('Dark Mode'),
                  leading: Icon(Icons.lightbulb_outline),
                  trailing: Container(
                      width: 100,
                      child: DropdownButton(
                        value: settings.themeMode,
                        items: ThemeMode.values.map((val) {
                          return DropdownMenuItem<ThemeMode>(
                            value: val,
                            child: Text(val.text),
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
