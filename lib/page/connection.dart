import 'package:animations/animations.dart';
import 'package:dsgo/util/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:synoapi/synoapi.dart';

import '../bloc/connection_bloc.dart';
import '../bloc/syno_api_bloc.dart';
import '../model/model.dart';

class ConnectionEditForm extends StatefulWidget {
  int? _idx;
  Connection? _connection;

  ConnectionEditForm.edit(int idx, Connection? connection) {
    _idx = idx;
    _connection = connection;
  }

  ConnectionEditForm();

  @override
  State<StatefulWidget> createState() => _ConnectionEditFormState(_idx, _connection);
}

class _ConnectionEditFormState extends State<ConnectionEditForm> {
  final _formKey = GlobalKey<FormState>();
  int? _idx;
  Connection? _connection;
  late DSConnectionBloc connectionBloc;
  late SynoApiBloc apiBloc;
  Map<String, FocusNode> fieldFocus = {};

  // UI State
  bool isTestingConnection = false;

  _ConnectionEditFormState(this._idx, this._connection);

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
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_idx == null ? 'Add Connection' : 'Edit Connection'),
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
                TextFormField(
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  autofocus: true,
                  autocorrect: false,
                  autovalidateMode: AutovalidateMode.disabled,
                  decoration: InputDecoration(
                    labelText: 'URI',
                    hintText: 'Server URI. e.g. https://ds:5001/myds',
                  ),
                  initialValue: _connection?.uri,
                  onChanged: (uri) {
                    _connection!.uri = uri.trim();
                    setState(() {}); // force re-render, to enable/disable test button
                  },
                  onFieldSubmitted: (uri) {
                    fieldFocus['user']!.requestFocus();
                  },
                  validator: (value) {
                    if (value!.trim().isEmpty) {
                      return 'Cannot be empty';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  textInputAction: TextInputAction.next,
                  focusNode: fieldFocus['user'],
                  autocorrect: false,
                  autovalidateMode: AutovalidateMode.disabled,
                  decoration: InputDecoration(
                    labelText: 'Username',
                  ),
                  initialValue: _connection?.user?.toString() ?? '',
                  onChanged: (user) {
                    _connection!.user = user.trim();
                  },
                  onFieldSubmitted: (user) {
                    fieldFocus['password']!.requestFocus();
                  },
                  validator: (user) {
                    if (user!.trim().isEmpty) {
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
                  onChanged: (password) {
                    _connection!.password = password;
                  },
                ),
                Divider(
                  color: Color.fromARGB(0, 0, 0, 0),
                ),

                Row(
                  children: [
                    ElevatedButton(
                      child: Text('Save'),
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) {
                          return;
                        }
                        _formKey.currentState!.save();

                        if (_idx != null && _idx! >= 0) {
                          connectionBloc.add(DSConnectionEvent(DSConnectionAction.edit, _connection, _idx));
                        } else {
                          connectionBloc.add(DSConnectionEvent(DSConnectionAction.add, _connection, null));
                        }
                        Navigator.pop(context);
                      },
                    ),
                    Padding(padding: EdgeInsets.only(right: 10)),
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(Colors.amberAccent)
                      ),
                        child: Text('Test'),
                        onPressed: isEmpty(_connection?.uri) || isTestingConnection
                            ? null
                            : () {
                          if ([_connection?.uri, _connection?.user, _connection?.password].any((e) => e == null)) {
                            return;
                          }

                          var apiContext = APIContext.uri(_connection!.uri!);
                          apiContext
                              .authApp(Syno.DownloadStation.name, _connection!.user!, _connection!.password!)
                              .then((authOK) {
                            ScaffoldMessenger.of(context)
                              ..removeCurrentSnackBar()
                              ..showSnackBar(buildSnackBar(
                                  'Connect ${authOK ? 'success' : 'failed'}',
                                  duration: Duration(seconds: 2),
                                  showProgressIndicator: false
                              ));
                            setState(() {
                              isTestingConnection = false;
                            });
                          });
                          ScaffoldMessenger.of(context)
                            ..removeCurrentSnackBar()
                            ..showSnackBar(buildSnackBar('Connecting...'));
                          setState(() {
                            isTestingConnection = true;
                          });
                        })
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ManageConnectionsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => ManageConnectionsPageState();
}

class ManageConnectionsPageState extends State<ManageConnectionsPage> {
  GlobalKey _fabKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
      bloc: BlocProvider.of<DSConnectionBloc>(context),
      builder: (context, DSConnectionState state) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Connections'),
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
              return ConnectionEditForm();
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
                Connection? conn = state.connections[index];
                return OpenContainer(
                  closedColor: Theme.of(context).scaffoldBackgroundColor,
                  closedBuilder: (context, openContainerCallback) {
                    return ListTile(
                      title: Text(conn!.buildUri()),
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
                    return ConnectionEditForm.edit(index, conn);
                  },
                );
              }),
        );
      },
    );
  }
}
