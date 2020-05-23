String humanifySize(int sizeBytes, {int p: 1}) {
  if (sizeBytes == null || sizeBytes <= 0) return '0 B';

  var unit = [
    {1000000000000, 'TB'},
    {1000000000, 'GB'},
    {1000000, 'MB'},
    {1000, 'KB'},
    {1, 'B'}
  ];

  var i = 0;
  while (true) {
    var r = sizeBytes / unit[i].elementAt(0);
    if (r >= 1) {
      return '${fmtNum(r, p: p)} ${unit[i].elementAt(1)}';
    }
    i += 1;
  }

  return '?';
}

String humanifySeconds(int duration, {int accuracy: 0}) {
  if (duration == null || duration <= 0) return '0 Second';
  if (duration <= accuracy) return '';

  var unit = [
    {86400, 'Day'},
    {3600, 'Hour'},
    {60, 'Minute'},
    {1, 'Second'}
  ];

  var i = 0;
  while (true) {
    var r = duration / unit[i].elementAt(0);
    if (r >= 1) {
      int floored = r.floor();
      int rem = duration - floored * unit[i].elementAt(0);
      String trailing = '';
      if (rem > 0) {
        trailing = ' ' + humanifySeconds(rem, accuracy: accuracy);
      }

      return '$floored ${unit[i].elementAt(1)}${floored > 1 ? "s" : ""}' + trailing;
    }
    i += 1;
  }

  return '?';
}

String fmtNum(num n, {int p: 1}) {
  return n.toStringAsFixed(n.truncateToDouble() == n ? 0 : p);
}
