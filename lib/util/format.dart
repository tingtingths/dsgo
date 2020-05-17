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

String fmtNum(num n, {int p: 1}) {
  return n.toStringAsFixed(n.truncateToDouble() == n ? 0 : p);
}
