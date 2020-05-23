import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:synodownloadstation/bloc/connection_bloc.dart' as cBloc;
import 'package:synodownloadstation/model/model.dart';
import 'package:synodownloadstation/provider/connection.dart';

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

  _AccountFormState(this._idx, this._connection);

  @override
  Widget build(BuildContext context) {
    cBloc.ConnectionBloc bloc = BlocProvider.of<cBloc.ConnectionBloc>(context);

    if (_connection == null) {
      _connection = Connection.empty();
      _connection.proto = 'https';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_idx == null ? 'Add Account' : 'Edit Account'),
      ),
      body: Form(
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
                decoration: InputDecoration(
                  labelText: 'Host',
                  hintText: 'Server address',
                ),
                initialValue: _connection?.host,
                onChanged: (host) {
                  _connection.host = host.trim();
                },
              ),
              TextFormField(
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
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Username',
                ),
                initialValue: _connection?.user?.toString() ?? '',
                onChanged: (user) {
                  _connection.user = user.trim();
                  setState(() {});
                },
              ),
              TextFormField(
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
                  if (_idx != null && _idx >= 0) {
                    bloc.add(
                        cBloc.ConnectionEvent(cBloc.Action.edit, _connection));
                  } else {
                    bloc.add(
                        cBloc.ConnectionEvent(cBloc.Action.add, _connection));
                  }
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
