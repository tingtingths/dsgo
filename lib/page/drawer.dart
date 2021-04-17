import 'package:animations/animations.dart';
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
  Function(bool) _btnCallback;

  _AppDrawerHeader(this._btnCallback);

  @override
  State<StatefulWidget> createState() => _AppDrawerHeaderState(_btnCallback);
}

class _AppDrawerHeaderState extends State<_AppDrawerHeader> {
  bool _expandConnection = false;
  Function(bool) _btnCallback;
  PackageInfo? packageInfo;

  _AppDrawerHeaderState(this._btnCallback);

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
          Text(
            packageInfo!.appName,
            style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 1.5),
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: BlocBuilder<DSConnectionBloc, DSConnectionState>(
                  builder: (cntx, state) {
                    String? text = 'Add a connection...';
                    if (state.activeConnection != null) {
                      text = state.activeConnection!.friendlyName;
                      text = text == null ? state.activeConnection!.buildUri() : text;
                    }

                    return Text(
                      text,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                    );
                  },
                ),
              ),
              IconButton(
                icon: _expandConnection ? Icon(Icons.arrow_drop_up) : Icon(Icons.arrow_drop_down),
                onPressed: () {
                  setState(() {
                    _expandConnection = !_expandConnection;
                  });
                  _btnCallback(_expandConnection);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppDrawerState extends State<AppDrawer> {
  final l = Logger('_AppDrawerState');
  bool _inited = false;
  bool expandConnection = false;
  bool connectionUpdated = false;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  var _list = <Widget>[];
  var _connectionListItemIdx = [];
  var _connectionCntrListItemIdx = [];
  late DSConnectionBloc bloc;
  GlobalKey _addAcBtnKey = GlobalKey();
  GlobalKey _settingsBtnKey = GlobalKey();
  GlobalKey _manageConnectionsBtnKey = GlobalKey();
  PackageInfo? packageInfo;

  @override
  void initState() {
    bloc = BlocProvider.of<DSConnectionBloc>(context);
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
        var connections = state.connections;

        int itmIdx = 0;
        if (!_inited) {
          _inited = true;
          _list.addAll([
            _AppDrawerHeader((expand) {
              setState(() {
                expandConnection = expand;
              });
            }),
          ]);
          itmIdx += _list.length - 1;
          _list.addAll([
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
              applicationName: packageInfo!.appName,
              applicationVersion: '${packageInfo!.version}-${packageInfo!.buildNumber}',
              applicationLegalese: '@ 2020 Ho Shing Ting',
              aboutBoxChildren: <Widget>[Text('❤ from Hong Kong.')],
            )
          ]);
        } else {
          _listKey.currentState!.setState(() {
            expandConnection = expandConnection;
          });
        }

        if (expandConnection) {
          if (_connectionListItemIdx.length != connections.length) {
            // remove existing
            _connectionListItemIdx.sort((x, y) => (y - x));
            _connectionListItemIdx.forEach((i) {
              _removeItem(i);
            });
            _connectionListItemIdx = [];
            connections.forEach((c) {
              var isActive = activeConnection?.buildUri() == c!.buildUri();
              _insertItem(++itmIdx, _buildConnectionWidget(c, isActive));
              _connectionListItemIdx.add(itmIdx);
            });
          } else {
            // replace
            connections.forEach((c) {
              var isActive = activeConnection?.buildUri() == c!.buildUri();
              _list[++itmIdx] = _buildConnectionWidget(c, isActive);
            });
          }

          // add control button if not already add
          if (_connectionCntrListItemIdx.isEmpty) {
            // DEBUG : remove all
            _insertItem(
                ++itmIdx,
                ListTile(
                  leading: Icon(Icons.person_add),
                  title: Text('DEBUG Remove all'),
                  onTap: () {
                    bloc.add(DSConnectionEvent.noPayload(DSConnectionAction.removeAll));
                  },
                ));

            _insertItem(
                ++itmIdx,
                ListTile(
                  key: _manageConnectionsBtnKey,
                  leading: Icon(Icons.people),
                  title: Text('Manage Connections'),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) {
                        return ManageConnectionsPage();
                      },
                    ));
                  },
                ));
            _connectionCntrListItemIdx.add(itmIdx);
          }
        } else {
          _connectionCntrListItemIdx.sort((x, y) => (y - x));
          _connectionCntrListItemIdx.forEach((i) => _removeItem(i));
          _connectionCntrListItemIdx = [];

          _connectionListItemIdx.sort((x, y) => (y - x));
          _connectionListItemIdx.forEach((i) => _removeItem(i));
          _connectionListItemIdx = [];
        }

        return Drawer(
          child: SafeArea(
              child: Column(
            children: <Widget>[
              Expanded(
                child: AnimatedList(
                  key: _listKey,
                  initialItemCount: _list.length,
                  itemBuilder: (cntx, idx, anim) {
                    return _listItemBuilder(cntx, _list[idx], anim);
                  },
                ),
              )
            ],
          )),
        );
      },
    );
  }

  _insertItem(int idx, Widget widget) {
    _list.insert(idx, widget);
    _listKey.currentState!.insertItem(idx, duration: Duration(milliseconds: 150));
  }

  _removeItem(int idx) {
    if (_list.length < idx + 1) return;
    var widget = _list.removeAt(idx);
    _listKey.currentState!.removeItem(idx, (cntx, anim) {
      return _listItemBuilder(cntx, widget, anim);
    }, duration: Duration(milliseconds: 150));
  }

  Widget _listItemBuilder(BuildContext context, Widget widget, Animation<double> animation) {
    return SizeTransition(
      axis: Axis.vertical,
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: widget,
      ),
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
