import 'package:dsgo/datasource/connection.dart';
import 'package:dsgo/util/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:synoapi/synoapi.dart';

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
  Connection? _connection;
  Map<String, FocusNode> fieldFocus = {};

  // UI State
  bool isTestingConnection = false;

  _ConnectionEditFormState(this._idx, this._connection);

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
                          context.read(connectionDatastoreProvider).replace(_idx!, _connection!);
                        } else {
                          context.read(connectionDatastoreProvider).add(_connection!);
                        }
                        Navigator.pop(context, _connection);
                      },
                    ),
                    Padding(padding: EdgeInsets.only(right: 10)),
                    ElevatedButton(
                        style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.amberAccent)),
                        child: Text('Test'),
                        onPressed: isEmpty(_connection?.uri) || isTestingConnection
                            ? null
                            : () {
                                if ([_connection?.uri, _connection?.user, _connection?.password]
                                    .any((e) => e == null)) {
                                  return;
                                }

                                var apiContext = APIContext.uri(_connection!.uri!);
                                apiContext
                                    .authApp(Syno.DownloadStation.name, _connection!.user!, _connection!.password!)
                                    .then((authOK) {
                                  ScaffoldMessenger.of(context)
                                    ..removeCurrentSnackBar()
                                    ..showSnackBar(buildSnackBar('Connect ${authOK ? 'success' : 'failed'}',
                                        duration: Duration(seconds: 2), showProgressIndicator: false));
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
