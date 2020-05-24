extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${this.substring(1)}';
  }

  bool equalsIgnoreCase(String s) {
    return this.toLowerCase() == s.toLowerCase();
  }
}
