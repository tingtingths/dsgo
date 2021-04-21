import 'package:animations/animations.dart';
import 'package:dsgo/datasource/connection.dart';
import 'package:dsgo/main.dart';
import 'package:dsgo/model/model.dart';
import 'package:dsgo/util/const.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../page/connection.dart';
import '../page/settings.dart';

// ignore: top_level_function_literal_block
final packageInfoProvider = FutureProvider((ref) async {
  return await PackageInfo.fromPlatform();
});

class _AppDrawerHeader extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AppDrawerHeaderState();
}

class _AppDrawerHeaderState extends State<_AppDrawerHeader> {
  PackageInfo? packageInfo;

  @override
  void initState() {
    PackageInfo.fromPlatform().then((packageInfo) {
      setState(() {
        this.packageInfo = packageInfo;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (packageInfo == null) {
      return Text('');
    }
    // draw content
    return Container(
      padding: EdgeInsets.fromLTRB(15, 15, 15, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              STYLED_APP_NAME,
              style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 2.0, fontWeightDelta: 2),
            ),
            subtitle: Text(
              '${versionString(packageInfo!)}',
              style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 0.8),
            ),
          )
        ],
      ),
    );
  }
}

class AppDrawer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, watch) {
    var connection = watch(connectionProvider).state;
    return watch(packageInfoProvider).when(
        data: (packageInfo) {
          var drawerItems = <Widget>[_AppDrawerHeader()];

          if (connection != null) {
            // add current connection
            drawerItems.add(OpenContainer(
              closedColor: Colors.transparent,
              closedElevation: 0,
              closedBuilder: (context, action) {
                return ListTile(
                  leading: Icon(
                    Icons.person,
                  ),
                  title: Text(
                    connection.user ?? connection.uri ?? '',
                    style: TextStyle(),
                  ),
                  onTap: action,
                );
              },
              onClosed: (Connection? updatedConnection) {
                if (updatedConnection == null) return;
                // save connection
                context.read(connectionProvider).state = updatedConnection;
              },
              openBuilder: (context, CloseContainerActionCallback<Connection?> action) {
                return ConnectionEditForm.edit(0, connection);
              },
            ));
          }

          drawerItems.add(OpenContainer(
            closedColor: Colors.transparent,
            closedElevation: 0,
            openColor: Colors.transparent,
            openElevation: 0,
            closedBuilder: (context, action) {
              if (connection == null) {
                return ListTile(leading: Icon(Icons.login), title: Text('Login'), onTap: action);
              } else {
                return ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('Logout'),
                    onTap: () {
                      context.read(connectionDatastoreProvider).removeAll();
                      watch(connectionProvider).state = null;
                    });
              }
            },
            onClosed: (Connection? updatedConnection) {
              if (updatedConnection == null) return;
              // save connection
              context.read(connectionProvider).state = updatedConnection;
            },
            openBuilder: (context, CloseContainerActionCallback<Connection?> action) {
              return ConnectionEditForm();
            },
          ));

          final theme = Theme.of(context);
          final textStyle = theme.textTheme.bodyText2;
          final highlightTextStyle = Theme.of(context).textTheme.bodyText2!.copyWith(color: theme.colorScheme.primary);
          drawerItems.addAll([
            Divider(),
            OpenContainer(
              closedColor: Colors.transparent,
              closedElevation: 0,
              closedBuilder: (context, action) {
                return ListTile(leading: Icon(Icons.settings), title: Text('Settings'), onTap: action);
              },
              openBuilder: (context, action) {
                return SettingsPage();
              },
            ),
            AboutListTile(
              icon: Icon(Icons.info),
              applicationIcon: FlutterLogo(),
              applicationName: STYLED_APP_NAME,
              applicationVersion: '${versionString(packageInfo)}',
              applicationLegalese: '@ 2020 DS Go authors',
              aboutBoxChildren: <Widget>[
                const SizedBox(height: 24),
                RichText(
                    text: TextSpan(children: <TextSpan>[
                  TextSpan(style: textStyle, text: 'Homepage: '),
                  TextSpan(
                      style: highlightTextStyle,
                      text: 'https://github.com/tingtingths/dsgo',
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          launch('https://github.com/tingtingths/dsgo');
                        })
                ])),
                const SizedBox(height: 16),
                Text(
                  'Control your Synology Download Station on the go!',
                  style: textStyle,
                )
              ],
            ),
          ]);

          return Drawer(
            child: SafeArea(
                child: Column(
              children: <Widget>[
                Expanded(
                  child: ListView(
                    children: drawerItems,
                  ),
                )
              ],
            )),
          );
        },
        loading: () => Container(),
        error: (err, stack) => Text('Error: $err'));
  }
}

String versionString(PackageInfo packageInfo) {
  var ret = '${packageInfo.version}';
  if (packageInfo.buildNumber.isNotEmpty) {
    ret += '+${packageInfo.buildNumber}';
  }
  return ret;
}
