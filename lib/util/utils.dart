import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void copyToClipboard(String text, BuildContext context) {
  if (text == null) return;
  Clipboard.setData(ClipboardData(text: text));
  Scaffold.of(context).showSnackBar(SnackBar(
    duration: Duration(milliseconds: 1000),
    content: Text('Copied to clipboard'),
  ));
}