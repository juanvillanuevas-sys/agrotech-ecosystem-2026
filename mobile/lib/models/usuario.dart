class Usuario {
  final int id;
  final String username;
  final String email;
  final String rol;

  Usuario({
    required this.id,
    required this.username,
    required this.email,
    required this.rol,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id:       json['id'],
      username: json['username'],
      email:    json['email'],
      rol:      json['rol'],
    );
  }
}
