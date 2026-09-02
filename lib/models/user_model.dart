class User {
  final String name;
  final String email;
  final String classCode;
  final String className;
  final String? ulid;

  const User({
    required this.name,
    required this.email,
    required this.classCode,
    required this.className,
    this.ulid,
  });
}
