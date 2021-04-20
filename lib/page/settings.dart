import 'package:flutter/foundation.dart';

import '../model/model.dart';
import '../datasource/user_settings.dart';
import '../util/const.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  late UserSettingsDatasource settingsDatasource;
  UserSettings? settings;

  @override
  void initState() {
    if (kIsWeb) {
      settingsDatasource = WebUserSettingsDatasource();
    } else {
      settingsDatasource = MobileUserSettingsDatasource();
    }
    settingsDatasource.get().then((value) {
      setState(() {
        settings = value;
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (settings == null) {
      return CircularProgressIndicator();
    }

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
                    initialValue: settings!.apiRequestFrequency!.toRadixString(10),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        settings!.apiRequestFrequency = int.parse(value);
                      });
                      settingsDatasource.set(settings);
                    },
                  ),
                )),
            ListTile(
                title: Text('Dark Mode'),
                leading: Icon(Icons.lightbulb_outline),
                trailing: Container(
                    width: 100,
                    child: DropdownButton(
                      value: settings!.themeMode,
                      items: ThemeMode.values.map((val) {
                        return DropdownMenuItem<ThemeMode>(
                          value: val,
                          child: Text(val.text),
                        );
                      }).toList(),
                      onChanged: (dynamic val) {
                        setState(() {
                          settings!.themeMode = val;
                        });
                        settingsDatasource.set(settings);
                      },
                    ))),
          ],
        ),
      ),
    );
  }
}