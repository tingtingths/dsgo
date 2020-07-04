import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void copyToClipboard(String text, BuildContext context) {
  if (text == null) return;
  Clipboard.setData(ClipboardData(text: text)).then((value) {
    Scaffold.of(context).showSnackBar(SnackBar(
      duration: Duration(milliseconds: 1000),
      content: Text('Copied to clipboard.'),
    ));
  });
}

SnackBar buildSnackBar(String text,
    {Duration duration: const Duration(days: 365), SnackBarAction action, bool showProgressIndicator: true}) {
  var children = <Widget>[Text(text)];

  if (showProgressIndicator) {
    children.insert(
        0,
        Padding(
          child: CircularProgressIndicator(),
          padding: EdgeInsets.fromLTRB(0, 0, 15, 0),
        ));
  }

  return SnackBar(
    duration: duration,
    action: action,
    content: Row(
      children: children,
    ),
  );
}
