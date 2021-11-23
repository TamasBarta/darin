class DependencyHandle {
  final Type type;
  final dynamic qualifier;

  const DependencyHandle(this.type, this.qualifier);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DependencyHandle &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          qualifier == other.qualifier;

  @override
  int get hashCode => Object.hash(type, qualifier);

  @override
  String toString() => "[type: $type, qualifier: $qualifier]";
}
