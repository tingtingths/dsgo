import 'package:dsgo/datasource/connection.dart';
import 'package:dsgo/util/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:synoapi/synoapi.dart';

import '../main.dart';
import '../model/model.dart';

class ConnectionEditForm extends StatefulWidget {
  final int? _idx;
  final Connection? _connection;

  ConnectionEditForm.edit(this._idx, this._connection);

  ConnectionEditForm()
      : _idx = null,
        _connection = null;

  @override
  State<StatefulWidget> createState() => _ConnectionEditFormState(_idx, _connection);
}

class _ConnectionEditFormState extends State<ConnectionEditForm> {
  final _formKey = GlobalKey<FormState>();
  int? _idx;
  Connection _connection;
  Map<String, FocusNode> fieldFocus = {};

  // UI State
  bool isTestingConnection = false;

  _ConnectionEditFormState(this._idx, Connection? connection) : _connection = connection ?? Connection.empty();

  @override
  void initState() {
    fieldFocus = {
      'port': FocusNode(),
      'user': FocusNode(),
      'password': FocusNode(),
    };
    super.initState();
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
                  initialValue: _connection.uri,
                  onChanged: (uri) {
                    _connection.uri = uri.trim();
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
                  enabled: !isTestingConnection,
                ),
                TextFormField(
                  textInputAction: TextInputAction.next,
                  focusNode: fieldFocus['user'],
                  autocorrect: false,
                  autovalidateMode: AutovalidateMode.disabled,
                  decoration: InputDecoration(
                    labelText: 'Username',
                  ),
                  initialValue: _connection.user?.toString() ?? '',
                  onChanged: (user) {
                    _connection.user = user.trim();
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
                  enabled: !isTestingConnection,
                ),
                TextFormField(
                  textInputAction: TextInputAction.done,
                  focusNode: fieldFocus['password'],
                  decoration: InputDecoration(
                    labelText: 'Password',
                  ),
                  obscureText: true,
                  initialValue: _connection.password?.toString() ?? '',
                  onChanged: (password) {
                    _connection.password = password;
                  },
                  enabled: !isTestingConnection,
                ),
                Divider(
                  color: Color.fromARGB(0, 0, 0, 0),
                ),
                Row(
                  children: [
                    ElevatedButton(
                      child: Text('Connect'),
                      onPressed: isEmpty(_connection.uri) || isTestingConnection
                          ? null
                          : () {
                              if (!_formKey.currentState!.validate()) {
                                return;
                              }
                              setState(() {
                                isTestingConnection = true;
                              });
                              ScaffoldMessenger.of(context)
                                ..removeCurrentSnackBar()
                                ..showSnackBar(buildSnackBar('Connecting'));
                              _formKey.currentState!.save();

                              // test connection
                              var apiContext = APIContext.uri(_connection.uri!);
                              apiContext.authApp(Syno.DownloadStation.name, _connection.user!, _connection.password!,
                                  otpCallback: () async {
                                return await showOTPDialog(context) ?? '';
                              }).then((authOK) {
                                ScaffoldMessenger.of(context)
                                  ..removeCurrentSnackBar()
                                  ..showSnackBar(buildSnackBar('Login ${authOK ? 'success' : 'failed'}!',
                                      duration: Duration(seconds: 3), showProgressIndicator: false));
                                if (authOK) {
                                  _connection.sid = apiContext.getSid(Syno.DownloadStation.name);
                                  context.read(connectionProvider).state = _connection;
                                  if (_idx != null && _idx! >= 0) {
                                    context.read(connectionDatastoreProvider).replace(_idx!, _connection);
                                  } else {
                                    context.read(connectionDatastoreProvider).add(_connection);
                                  }
                                  Navigator.pop(context, _connection);
                                } else {
                                  setState(() {
                                    isTestingConnection = false;
                                  });
                                }
                              });
                            },
                    ),
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

Future<String?> showOTPDialog(context) {
  String _value = '';
  return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
            title: Text('One-time password'),
            content: TextFormField(
              keyboardType: TextInputType.number,
              autofocus: true,
              autocorrect: false,
              autovalidateMode: AutovalidateMode.disabled,
              onChanged: (value) {
                _value = value;
              },
            ),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(_value);
                },
              )
            ]);
      });
}
