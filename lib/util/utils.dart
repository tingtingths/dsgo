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

SnackBar loadingSnackBar(String text,
    {Duration duration: const Duration(days: 365)}) {
  return SnackBar(
    duration: duration,
    content: Row(
      children: [
        Padding(
          child: CircularProgressIndicator(),
          padding: EdgeInsets.fromLTRB(0, 0, 15, 0),
        ),
        Text(text)
      ],
    ),
  );
}
