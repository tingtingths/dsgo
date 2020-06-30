import 'package:dsgo/bloc/connection_bloc.dart' as cBloc;
import 'package:dsgo/bloc/syno_api_bloc.dart';
import 'package:dsgo/model/model.dart';
import 'package:dsgo/provider/connection.dart';
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

  AccountForm.create();

  @override
  State<StatefulWidget> createState() => _AccountFormState(_idx, _connection);
}

class _AccountFormState extends State<AccountForm> {
  final _formKey = GlobalKey<FormState>();
  int _idx;
  Connection _connection;
  MobileConnectionProvider _connectionProvider = MobileConnectionProvider();
  cBloc.ConnectionBloc connectionBloc;
  SynoApiBloc apiBloc;
  Map<String, FocusNode> fieldFocus = {};

  _AccountFormState(this._idx, this._connection);

  @override
  void initState() {
    connectionBloc = BlocProvider.of<cBloc.ConnectionBloc>(context);
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
                  decoration: InputDecoration(icon: Icon(Icons.https)),
                  onChanged: (proto) {
                    _connection.proto = proto;
                    setState(() {});
                  },
                  items: <DropdownMenuItem>[
                    DropdownMenuItem(
                      value: 'https',
                      child: Text('https'),
                    ),
                    DropdownMenuItem(
                      value: 'http',
                      child: Text('http'),
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
                  onChanged: (host) {
                    _connection.host = host.trim();
                  },
                  onFieldSubmitted: (host) {
                    fieldFocus['port'].requestFocus();
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
                  onChanged: (port) {
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
                  onChanged: (user) {
                    _connection.user = user.trim();
                    setState(() {});
                  },
                  onFieldSubmitted: (user) {
                    fieldFocus['password'].requestFocus();
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
                    apiBloc.connection = _connection;
                    if (_idx != null && _idx >= 0) {
                      connectionBloc.add(cBloc.ConnectionEvent(
                          cBloc.Action.edit, _connection));
                    } else {
                      connectionBloc.add(
                          cBloc.ConnectionEvent(cBloc.Action.add, _connection));
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
