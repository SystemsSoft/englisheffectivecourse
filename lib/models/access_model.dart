class AccessDto {
  final int id;
  final String? ulid;
  final String className;
  final String classCode;
  final String name;
  final String password;
  final String email;

  AccessDto({
    required this.id,
    this.ulid,
    required this.className,
    required this.classCode,
    required this.name,
    required this.password,
    required this.email,
  });

  factory AccessDto.fromJson(Map<String, dynamic> json) {
    return AccessDto(
      id: json['id'] as int? ?? 0,
      ulid: json['ulid'] as String?,
      className: json['className'] as String? ?? '',
      classCode: json['classCode'] as String? ?? '',
      name: json['name'] as String? ?? '',
      password: json['password'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ulid': ulid,
        'className': className,
        'classCode': classCode,
        'name': name,
        'password': password,
        'email': email,
      };
}
