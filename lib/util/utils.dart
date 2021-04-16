import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void copyToClipboard(String? text, BuildContext context) {
  if (text == null) return;
  Clipboard.setData(ClipboardData(text: text)).then((value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: Duration(milliseconds: 1000),
      content: Text('Copied to clipboard.'),
    ));
  });
}

SnackBar buildSnackBar(String text,
    {Duration duration: const Duration(days: 365), SnackBarAction? action, bool showProgressIndicator: true}) {
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

V? mapGet<K, V>(Map<K, dynamic>? dict, K key, {otherwise, Function? mapper, Function(V value)? ifPresent}) {
  if (dict == null || !dict.containsKey(key) || dict[key] == null) {
    return otherwise;
  }

  if (ifPresent != null) {
    ifPresent(dict[key]);
  }

  if (mapper != null) return mapper(dict[key]);
  return dict[key];
}
