import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

void main() {
  print(Locale('en').toString());
  print(Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant').toString());
}
