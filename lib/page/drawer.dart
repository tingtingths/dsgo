import 'package:animations/animations.dart';
import 'package:dsgo/bloc/syno_api_bloc.dart';
import 'package:dsgo/util/const.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../bloc/connection_bloc.dart';
import '../model/model.dart';
import '../page/connection.dart';
import '../page/settings.dart';

class AppDrawer extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AppDrawerState();
}

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
            title: Text(STYLED_APP_NAME,
              style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 2.0, fontWeightDelta: 2),
            ),
            subtitle: Text('${packageInfo!.version}',
              style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 0.8),
            ),
          )
        ],
      ),
    );
  }
}

class _AppDrawerState extends State<AppDrawer> {
  final l = Logger('_AppDrawerState');
  late DSConnectionBloc connectionBloc;
  late SynoApiBloc apiBloc;
  GlobalKey _settingsBtnKey = GlobalKey();
  PackageInfo? packageInfo;

  @override
  void initState() {
    connectionBloc = BlocProvider.of<DSConnectionBloc>(context);
    apiBloc = BlocProvider.of<SynoApiBloc>(context);
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
      return CircularProgressIndicator();
    }
    return BlocBuilder<DSConnectionBloc, DSConnectionState>(
      builder: (BuildContext context, DSConnectionState state) {
        var activeConnection = state.activeConnection;
        var drawerItems = <Widget>[_AppDrawerHeader()];

        if (activeConnection != null) {
          // add current connection
          drawerItems.add(
              OpenContainer(
                closedColor: Colors.transparent,
                closedElevation: 0,
                closedBuilder: (context, action) {
                  return ListTile(
                    leading: Icon(
                      Icons.person,
                    ),
                    title: Text(
                      activeConnection.user ?? activeConnection.uri ?? '',
                      style: TextStyle(
                      ),
                    ),
                    onTap: action,
                  );
                },
                openBuilder: (context, action) {
                  return ConnectionEditForm.edit(0, activeConnection);
                },
              )
          );
        }

        drawerItems.add(
          OpenContainer(
            closedColor: Colors.transparent,
            closedElevation: 0,
            openColor: Colors.transparent,
            openElevation: 0,
            closedBuilder: (context, action) {
              if (activeConnection == null) {
                return ListTile(
                    leading: Icon(Icons.login),
                    title: Text('Login'),
                    onTap: action
                );
              } else {
                return ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                  onTap: () {
                    connectionBloc.add(DSConnectionEvent.noPayload(DSConnectionAction.removeAll));
                  }
                );
              }
            },
            openBuilder: (context, action) {
              return ConnectionEditForm();
            },
          )
        );

        drawerItems.addAll([
          Divider(),
          OpenContainer(
            closedColor: Colors.transparent,
            closedElevation: 0,
            closedBuilder: (context, action) {
              return ListTile(
                  key: _settingsBtnKey, leading: Icon(Icons.settings), title: Text('Settings'), onTap: action);
            },
            openBuilder: (context, action) {
              return SettingsPage();
            },
          ),
          AboutListTile(
            icon: Icon(Icons.info),
            applicationIcon: FlutterLogo(),
            applicationName: STYLED_APP_NAME,
            applicationVersion: '${packageInfo!.version}-${packageInfo!.buildNumber}',
            applicationLegalese: '@ 2020 Ho Shing Ting',
            aboutBoxChildren: <Widget>[Text('❤ from Hong Kong.')],
          )
        ]);

        print(drawerItems);
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
    );
  }

  Widget _buildConnectionWidget(Connection conn, bool isActive) {
    var bg = Theme.of(context).accentColor.withOpacity(0.2);
    var fg = Theme.of(context).accentColor;
    DSConnectionBloc bloc = BlocProvider.of<DSConnectionBloc>(context);

    var tile = ListTile(
      leading: Icon(
        Icons.person,
        color: isActive ? fg : null,
      ),
      title: Text(
        conn.buildUri(),
        style: TextStyle(
          color: isActive ? fg : null,
        ),
      ),
      onTap: () {
        bloc.add(DSConnectionEvent(DSConnectionAction.select, conn, null));
        apiBloc.apiContext = null;
      },
    );

    if (isActive) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(topRight: Radius.circular(25), bottomRight: Radius.circular(25)),
          color: bg,
        ),
        child: tile,
      );
    }

    return tile;
  }
}
