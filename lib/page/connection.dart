import 'package:dio/dio.dart';
import 'package:dsgo/datasource/connection.dart';
import 'package:dsgo/util/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:synoapi/synoapi.dart';

import '../main.dart';
import '../model/model.dart';

class ConnectionEditForm extends ConsumerStatefulWidget {
  final int? _idx;
  final Connection? _connection;

  ConnectionEditForm.edit(this._idx, this._connection);

  ConnectionEditForm()
      : _idx = null,
        _connection = null;

  @override
  ConsumerState<ConnectionEditForm> createState() => _ConnectionEditFormState(_idx, _connection);
}

class _ConnectionEditFormState extends ConsumerState<ConnectionEditForm> {
  final _formKey = GlobalKey<FormState>();
  int? _idx;
  Connection _connection;
  Map<String, FocusNode> fieldFocus = {};

  // UI State
  bool isTestingConnection = false;

  _ConnectionEditFormState(this._idx, Connection? connection) : _connection = connection ?? Connection.empty();

  @override
  void initState() {
    fieldFocus = {'uri': FocusNode(), 'user': FocusNode(), 'password': FocusNode(), 'connectBtn': FocusNode()};
    super.initState();
  }

  @override
  void dispose() {
    fieldFocus.values.forEach((e) => e.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_idx == null ? l10n.addConnection : l10n.editConnection),
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
                  focusNode: fieldFocus['uri'],
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  autofocus: true,
                  autocorrect: false,
                  autovalidateMode: AutovalidateMode.disabled,
                  decoration: InputDecoration(
                    labelText: l10n.uri,
                    hintText: l10n.connectionFormUriHint,
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
                      return l10n.inputWarningEmpty;
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
                    labelText: l10n.username,
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
                      return l10n.inputWarningEmpty;
                    }
                    return null;
                  },
                  enabled: !isTestingConnection,
                ),
                TextFormField(
                  textInputAction: TextInputAction.done,
                  focusNode: fieldFocus['password'],
                  decoration: InputDecoration(
                    labelText: l10n.password,
                  ),
                  obscureText: true,
                  initialValue: _connection.password?.toString() ?? '',
                  onChanged: (password) {
                    _connection.password = password;
                  },
                  onFieldSubmitted: (_) {
                    fieldFocus['connectBtn']!.requestFocus();
                  },
                  enabled: !isTestingConnection,
                ),
                Divider(
                  color: Color.fromARGB(0, 0, 0, 0),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: ElevatedButton(
                          focusNode: fieldFocus['connectBtn'],
                          child: Text(l10n.login),
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
                                    ..showSnackBar(buildSnackBar(l10n.connecting));
                                  _formKey.currentState!.save();

                                  // test connection
                                  var apiContext = APIContext.uri(_connection.uri!);
                                  apiContext
                                      .authApp(Syno.DownloadStation.name, _connection.user!, _connection.password!,
                                          otpCallback: () async {
                                    return await showOTPDialog(context) ?? '';
                                  }).then((authOK) {
                                    ScaffoldMessenger.of(context)
                                      ..removeCurrentSnackBar()
                                      ..showSnackBar(buildSnackBar('${authOK ? l10n.loginSuccess : l10n.loginFailed}',
                                          duration: Duration(seconds: 3), showProgressIndicator: false));
                                    if (authOK) {
                                      _connection.sid = apiContext.getSid(Syno.DownloadStation.name);
                                      ref.read(connectionProvider.state).state = _connection;
                                      if (_idx != null && _idx! >= 0) {
                                        ref.read(connectionDatastoreProvider).replace(_idx!, _connection);
                                      } else {
                                        ref.read(connectionDatastoreProvider).add(_connection);
                                      }
                                      Navigator.pop(context, _connection);
                                    } else {
                                      setState(() {
                                        isTestingConnection = false;
                                      });
                                    }
                                  }, onError: (err, stack) {
                                    ScaffoldMessenger.of(context)
                                      ..removeCurrentSnackBar()
                                      ..showSnackBar(buildSnackBar(
                                          err is DioError ? l10n.connectionFailed : '${l10n.failed} ${err.error}',
                                          showProgressIndicator: false,
                                          duration: Duration(seconds: 4)));
                                    setState(() {
                                      isTestingConnection = false;
                                    });
                                  });
                                },
                        ),
                      ),
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
  final l10n = AppLocalizations.of(context)!;
  final FocusNode submitBtnFocus = FocusNode();
  String _value = '';
  return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
            title: Text(l10n.oneTimePassword),
            content: TextFormField(
              keyboardType: TextInputType.number,
              autofocus: true,
              autocorrect: false,
              autovalidateMode: AutovalidateMode.disabled,
              onChanged: (value) {
                _value = value;
              },
              onFieldSubmitted: (value) {
                submitBtnFocus.requestFocus();
              },
            ),
            actions: [
              TextButton(
                child: Text(l10n.submit),
                focusNode: submitBtnFocus,
                onPressed: () {
                  Navigator.of(context).pop(_value);
                },
              )
            ]);
      });
}
