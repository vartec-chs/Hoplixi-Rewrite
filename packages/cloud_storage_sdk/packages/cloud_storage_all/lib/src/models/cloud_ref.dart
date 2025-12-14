sealed class CloudRef {
  const CloudRef();
}

final class CloudPath extends CloudRef {
  final String path;
  const CloudPath(this.path);

  @override
  String toString() => 'CloudPath($path)';
}

final class CloudId extends CloudRef {
  final String id;
  const CloudId(this.id);

  @override
  String toString() => 'CloudId($id)';
}

extension CloudRefRequire on CloudRef {
  String requirePath({String? message}) {
    final self = this;
    if (self is CloudPath) return self.path;
    throw ArgumentError(message ?? 'Expected CloudPath, got $runtimeType');
  }

  String requireId({String? message}) {
    final self = this;
    if (self is CloudId) return self.id;
    throw ArgumentError(message ?? 'Expected CloudId, got $runtimeType');
  }
}
