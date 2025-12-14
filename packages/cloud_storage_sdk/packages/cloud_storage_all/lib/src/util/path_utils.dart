String cloudBasename(String path) {
  var p = path.trim();
  if (p.isEmpty) return '';
  while (p.length > 1 && p.endsWith('/')) {
    p = p.substring(0, p.length - 1);
  }
  final idx = p.lastIndexOf('/');
  if (idx == -1) return p;
  return p.substring(idx + 1);
}

String cloudJoinPath(String folderPath, String name) {
  var base = folderPath.trim();
  if (base.isEmpty || base == '/') {
    return '/$name';
  }
  while (base.endsWith('/')) {
    base = base.substring(0, base.length - 1);
  }
  if (name.startsWith('/')) {
    return '$base$name';
  }
  return '$base/$name';
}
