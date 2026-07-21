class UserModel {
  final int id;
  final String code;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  String? career;
  List<String> especialidades;
  final String currentCycle;
  bool setupComplete;

  UserModel({
    required this.id,
    required this.code,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.role = 'estudiante',
    this.career,
    List<String>? especialidades,
    this.currentCycle = '2026-1',
    this.setupComplete = false,
  }) : especialidades = especialidades ?? <String>[];

  String get fullName => '$firstName $lastName';
  bool get isDelegate => role == 'delegado' || role == 'subdelegado';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final name = (json['full_name'] as String? ?? '').split(' ');
    return UserModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      code: json['code'] as String? ?? '',
      firstName: name.isNotEmpty ? name.first : '',
      lastName: name.length > 1 ? name.sublist(1).join(' ') : '',
      email: json['institutional_email'] as String? ?? json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'estudiante',
      career: json['career'] is Map ? (json['career'] as Map)['name'] as String? : json['career'] as String?,
      especialidades: json['especialidades'] != null
          ? (json['especialidades'] as List).map((e) {
              if (e is String) return e;
              if (e is Map) return e['name'] as String? ?? '';
              return '';
            }).where((e) => e.isNotEmpty).toList()
          : <String>[],
      currentCycle: json['currentCycle'] as String? ?? json['current_level']?.toString() ?? '2026-1',
      setupComplete: json['setupComplete'] as bool? ?? json['specialty_setup_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'role': role,
        'career': career,
        'especialidades': especialidades,
        'currentCycle': currentCycle,
        'setupComplete': setupComplete,
      };
}
