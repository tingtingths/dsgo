import 'package:animations/animations.dart';
import '../bloc/connection_bloc.dart';
import '../bloc/syno_api_bloc.dart';
import '../model/model.dart';
import '../provider/connection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AccountForm extends StatefulWidget {
  int _idx;
  Connection _connection;

  AccountForm.edit(int idx, Connection connection) {
    _idx = idx;
    _connection = connection;
  }

  AccountForm();

  @override
  State<StatefulWidget> createState() => _AccountFormState(_idx, _connection);
}

class _AccountFormState extends State<AccountForm> {
  final _formKey = GlobalKey<FormState>();
  int _idx;
  Connection _connection;
  MobileConnectionProvider _connectionProvider = MobileConnectionProvider();
  DSConnectionBloc connectionBloc;
  SynoApiBloc apiBloc;
  Map<String, FocusNode> fieldFocus = {};

  _AccountFormState(this._idx, this._connection);

  @override
  void initState() {
    connectionBloc = BlocProvider.of<DSConnectionBloc>(context);
    apiBloc = BlocProvider.of<SynoApiBloc>(context);

    fieldFocus = {
      'port': FocusNode(),
      'user': FocusNode(),
      'password': FocusNode(),
    };
  }

  @override
  void dispose() {
    fieldFocus.values.forEach((e) => e.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_connection == null) {
      _connection = Connection.empty();
      _connection.proto = 'https';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_idx == null ? 'Add Account' : 'Edit Account'),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DropdownButtonFormField(
                  decoration: InputDecoration(labelText: 'Protocol'),
                  onChanged: (proto) {
                    _connection.proto = proto;
                    setState(() {});
                  },
                  items: <DropdownMenuItem>[
                    DropdownMenuItem(
                      value: 'https',
                      child: Text('HTTPS'),
                    ),
                    DropdownMenuItem(
                      value: 'http',
                      child: Text('HTTP'),
                    ),
                  ],
                  value: _connection.proto,
                ),
                TextFormField(
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  autofocus: true,
                  autocorrect: false,
                  autovalidate: false,
                  decoration: InputDecoration(
                    labelText: 'Host',
                    hintText: 'Server address',
                  ),
                  initialValue: _connection?.host,
                  onSaved: (host) {
                    _connection.host = host.trim();
                  },
                  onFieldSubmitted: (host) {
                    fieldFocus['port'].requestFocus();
                  },
                  validator: (value) {
                    if (value.trim().isEmpty) {
                      return 'Cannot be empty';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  focusNode: fieldFocus['port'],
                  autocorrect: false,
                  autovalidate: false,
                  decoration: InputDecoration(
                    labelText: 'Port',
                  ),
                  initialValue: _connection?.port?.toString() ?? '',
                  onSaved: (port) {
                    try {
                      _connection.port = int.parse(port.trim());
                    } catch (e) {
                      _connection.port = null;
                    }
                    setState(() {});
                  },
                  onFieldSubmitted: (port) {
                    fieldFocus['user'].requestFocus();
                  },
                  validator: (port) {
                    if (port.trim().isEmpty) {
                      return 'Cannot be empty';
                    }
                    try {
                      int.parse(port.trim());
                    } catch (e) {
                      return 'Invalid input';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  textInputAction: TextInputAction.next,
                  focusNode: fieldFocus['user'],
                  autocorrect: false,
                  autovalidate: false,
                  decoration: InputDecoration(
                    labelText: 'Username',
                  ),
                  initialValue: _connection?.user?.toString() ?? '',
                  onSaved: (user) {
                    _connection.user = user.trim();
                    setState(() {});
                  },
                  onFieldSubmitted: (user) {
                    fieldFocus['password'].requestFocus();
                  },
                  validator: (user) {
                    if (user.trim().isEmpty) {
                      return 'Cannot be empty';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  textInputAction: TextInputAction.done,
                  focusNode: fieldFocus['password'],
                  decoration: InputDecoration(
                    labelText: 'Password',
                  ),
                  obscureText: true,
                  initialValue: _connection?.password?.toString() ?? '',
                  onSaved: (password) {
                    _connection.password = password;
                    setState(() {});
                  },
                ),
                Divider(
                  color: Color.fromARGB(0, 0, 0, 0),
                ),
                RaisedButton(
                  child: Text('Save'),
                  onPressed: () {
                    if (!_formKey.currentState.validate()) {
                      return;
                    }
                    _formKey.currentState.save();

                    apiBloc.connection = _connection;
                    if (_idx != null && _idx >= 0) {
                      connectionBloc.add(DSConnectionEvent(DSConnectionAction.edit, _connection));
                    } else {
                      connectionBloc.add(DSConnectionEvent(DSConnectionAction.add, _connection));
                    }
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ManageAccountPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => ManageAccountPageState();
}

class ManageAccountPageState extends State<ManageAccountPage> {
  GlobalKey _fabKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
      bloc: BlocProvider.of<DSConnectionBloc>(context),
      builder: (context, DSConnectionState state) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Manage Accounts'),
          ),
          floatingActionButton: OpenContainer(
            closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            closedBuilder: (context, openContainerCallback) {
              return FloatingActionButton(
                child: Icon(
                  Icons.add,
                  size: 32,
                ),
                onPressed: openContainerCallback,
              );
            },
            openBuilder: (context, closeContainerCallback) {
              return AccountForm();
            },
          ),
          body: ListView.separated(
              itemCount: state.connections.length,
              separatorBuilder: (context, index) {
                return Divider(
                  indent: 15,
                  endIndent: 15,
                );
              },
              itemBuilder: (context, index) {
                Connection conn = state.connections[index];
                return OpenContainer(
                  closedColor: Theme.of(context).scaffoldBackgroundColor,
                  closedBuilder: (context, openContainerCallback) {
                    return ListTile(
                      title: Text(conn.buildUri()),
                      subtitle: conn.buildUri() == state.activeConnection?.buildUri()
                          ? Text(
                              'Active',
                              style: TextStyle(color: Theme.of(context).accentColor),
                            )
                          : null,
                      onTap: openContainerCallback,
                    );
                  },
                  openBuilder: (context, closeContainerCallback) {
                    return AccountForm.edit(index, conn);
                  },
                );
              }),
        );
      },
    );
  }
}
