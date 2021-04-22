import 'package:flutter/cupertino.dart';

void main() {
  print(Locale('en').toString());
  print(Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant').toString());
}
