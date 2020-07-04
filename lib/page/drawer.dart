import 'package:dsgo/bloc/connection_bloc.dart';
import 'package:dsgo/model/model.dart';
import 'package:dsgo/page/account.dart';
import 'package:dsgo/page/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:morpheus/morpheus.dart';
import 'package:package_info/package_info.dart';

class MyDrawer extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MyDrawerState();
}

class _MyDrawerHeader extends StatefulWidget {
  Function(bool) _btnCallback;

  _MyDrawerHeader(this._btnCallback);

  @override
  State<StatefulWidget> createState() => _MyDrawerHeaderState(_btnCallback);
}

class _MyDrawerHeaderState extends State<_MyDrawerHeader> {
  bool _expandConnection = false;
  Function(bool) _btnCallback;
  Connection _connection;
  PackageInfo packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
  );

  _MyDrawerHeaderState(this._btnCallback);

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
    return Container(
      padding: EdgeInsets.fromLTRB(15, 15, 15, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Text(
            packageInfo.appName,
            style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 1.5),
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: BlocBuilder<DSConnectionBloc, DSConnectionState>(
                  builder: (cntx, state) {
                    var text = 'Add an account...';
                    if (state.activeConnection != null) {
                      text = state.activeConnection.friendlyName;
                      text = text == null ? state.activeConnection.buildUri() : text;
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

class _MyDrawerState extends State<MyDrawer> {
  bool _inited = false;
  bool expandConnection = false;
  bool accountUpdated = false;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  var _list = <Widget>[];
  var _connectionListItemIdx = [];
  var _connectionCntrListItemIdx = [];
  DSConnectionBloc bloc;
  GlobalKey _addAcBtnKey = GlobalKey();
  GlobalKey _settingsBtnKey = GlobalKey();
  PackageInfo packageInfo;

  @override
  Future<void> initState() {
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
        var connections = state.connections ?? [];

        int itmIdx = 0;
        if (!_inited) {
          _inited = true;
          _list.addAll([
            _MyDrawerHeader((expand) {
              setState(() {
                expandConnection = expand;
              });
            }),
          ]);
          itmIdx += _list.length - 1;
          _list.addAll([
            Divider(),
            ListTile(
              leading: Icon(Icons.all_inclusive),
              title: Text('All'),
              onTap: () {
                print('tap: All');
              },
            ),
            ListTile(
              leading: Icon(Icons.file_download),
              title: Text('Downloading'),
              onTap: () {
                print('tap: Downloading');
              },
            ),
            Divider(),
            ListTile(
              key: _settingsBtnKey,
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.push(
                    context,
                    MorpheusPageRoute(
                      parentKey: _settingsBtnKey,
                      builder: (context) {
                        return SettingsPage();
                      },
                    ));
              },
            ),
            AboutListTile(
              icon: Icon(Icons.info),
              applicationIcon: FlutterLogo(),
              applicationName: packageInfo.appName,
              applicationVersion: '${packageInfo.version}-${packageInfo.buildNumber}',
              applicationLegalese: '@ 2020 Ho Shing Ting',
              aboutBoxChildren: <Widget>[Text('❤ from Hong Kong.')],
            )
          ]);
        } else {
          _listKey.currentState.setState(() {
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
              var isActive = activeConnection?.buildUri() == c.buildUri();
              _insertItem(++itmIdx, _buildConnectionWidget(c, isActive));
              _connectionListItemIdx.add(itmIdx);
            });
          } else {
            // replace
            connections.forEach((c) {
              var isActive = activeConnection?.buildUri() == c.buildUri();
              _list[++itmIdx] = _buildConnectionWidget(c, isActive);
            });
          }

          // add control button if not already add
          if (_connectionCntrListItemIdx.isEmpty) {
            // add connection btn
            _insertItem(
                ++itmIdx,
                ListTile(
                  key: _addAcBtnKey,
                  leading: Icon(Icons.person_add),
                  title: Text('Add Account'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MorpheusPageRoute(
                          parentKey: _addAcBtnKey,
                          builder: (context) {
                            return BlocProvider.value(
                              value: BlocProvider.of<DSConnectionBloc>(context),
                              child: AccountForm(),
                            );
                          },
                        ));
                  },
                ));
            _connectionCntrListItemIdx.add(itmIdx);

            // DEBUG : remove all
            _insertItem(
                ++itmIdx,
                ListTile(
                  leading: Icon(Icons.person_add),
                  title: Text('DEBUG Remove all'),
                  onTap: () {
                    bloc.add(DSConnectionEvent(DSConnectionAction.removeAll, null));
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
              ),
              Text(
                '@ 2020 Ho Shing Ting',
                style: TextStyle(color: Theme.of(context).textTheme.subtitle2.color.withAlpha(100)),
              )
            ],
          )),
        );
      },
    );
  }

  _insertItem(int idx, Widget widget) {
    _list.insert(idx, widget);
    _listKey.currentState.insertItem(idx, duration: Duration(milliseconds: 150));
  }

  _removeItem(int idx) {
    if (_list.length < idx + 1) return;
    var widget = _list.removeAt(idx);
    _listKey.currentState.removeItem(idx, (cntx, anim) {
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
        bloc.add(DSConnectionEvent(DSConnectionAction.select, conn));
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
