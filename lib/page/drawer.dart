import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:morpheus/morpheus.dart';
import 'package:synodownloadstation/bloc/connection_bloc.dart' as cBloc;
import 'package:synodownloadstation/bloc/syno_api_bloc.dart';
import 'package:synodownloadstation/model/model.dart';
import 'package:synodownloadstation/page/account.dart';

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

  _MyDrawerHeaderState(this._btnCallback);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(15, 15, 15, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Text(
            'Download Station',
            style:
                DefaultTextStyle.of(context).style.apply(fontSizeFactor: 1.5),
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: BlocBuilder<cBloc.ConnectionBloc, cBloc.ConnectionState>(
                  builder: (cntx, state) {
                    var text = 'Add an account...';
                    if (state.activeConnection != null) {
                      text = state.activeConnection.friendlyName;
                      text = text == null
                          ? state.activeConnection.buildUri()
                          : text;
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
                icon: _expandConnection
                    ? Icon(Icons.arrow_drop_up)
                    : Icon(Icons.arrow_drop_down),
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
  cBloc.ConnectionBloc bloc;
  GlobalKey _addAcBtnKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    bloc = BlocProvider.of<cBloc.ConnectionBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<cBloc.ConnectionBloc, cBloc.ConnectionState>(
      builder: (BuildContext context, cBloc.ConnectionState state) {
        var activeConnection = state.activeConnection;
        var connections = state.connections ?? [];

        int itmidx = 0;
        if (!_inited) {
          _inited = true;
          _list.addAll([
            _MyDrawerHeader((expand) {
              setState(() {
                expandConnection = expand;
              });
            }),
          ]);
          itmidx += _list.length - 1;
          _list.addAll([Divider(), ..._buildFilterList()]);
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
              _insertItem(++itmidx, _buildConnectionWidget(c, isActive));
              _connectionListItemIdx.add(itmidx);
            });
          } else {
            // replace
            connections.forEach((c) {
              var isActive = activeConnection?.buildUri() == c.buildUri();
              _list[++itmidx] = _buildConnectionWidget(c, isActive);
            });
          }

          // add control button if not already add
          if (_connectionCntrListItemIdx.isEmpty) {
            // add connection btn
            _insertItem(
                ++itmidx,
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
                              value: BlocProvider.of<cBloc.ConnectionBloc>(
                                  context),
                              child: AccountForm.create(),
                            );
                          },
                        ));
                  },
                ));
            _connectionCntrListItemIdx.add(itmidx);

            // DEBUG : remove all
            _insertItem(
                ++itmidx,
                ListTile(
                  leading: Icon(Icons.person_add),
                  title: Text('DEBUG Remove all'),
                  onTap: () {
                    bloc.add(
                        cBloc.ConnectionEvent(cBloc.Action.removeAll, null));
                  },
                ));
            _connectionCntrListItemIdx.add(itmidx);
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
            child: AnimatedList(
          key: _listKey,
          initialItemCount: _list.length,
          itemBuilder: (cntx, idx, anim) {
            return _listItemBuilder(cntx, _list[idx], anim);
          },
        ));
      },
    );
  }

  _insertItem(int idx, Widget widget) {
    _list.insert(idx, widget);
    _listKey.currentState
        .insertItem(idx, duration: Duration(milliseconds: 150));
  }

  _removeItem(int idx) {
    if (_list.length < idx + 1) return;
    var widget = _list.removeAt(idx);
    _listKey.currentState.removeItem(idx, (cntx, anim) {
      return _listItemBuilder(cntx, widget, anim);
    }, duration: Duration(milliseconds: 150));
  }

  List<Widget> _buildFilterList() {
    return <Widget>[
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
      )
    ];
  }

  Widget _listItemBuilder(
      BuildContext context, Widget widget, Animation<double> animation) {
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
    var fg = Theme.of(context).primaryColor;
    cBloc.ConnectionBloc bloc = BlocProvider.of<cBloc.ConnectionBloc>(context);
    SynoApiBloc apiBloc = BlocProvider.of<SynoApiBloc>(context);

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
        bloc.add(cBloc.ConnectionEvent(cBloc.Action.select, conn));
      },
    );

    if (isActive) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              topRight: Radius.circular(25), bottomRight: Radius.circular(25)),
          color: bg,
        ),
        child: tile,
      );
    }

    return tile;
  }
}
