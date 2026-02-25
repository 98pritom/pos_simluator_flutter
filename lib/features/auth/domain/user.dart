import 'package:equatable/equatable.dart';

enum UserRole { admin, cashier }

class User extends Equatable {
  final String id;
  final String name;
  final String pin;
  final UserRole role;

  const User({
    required this.id,
    required this.name,
    required this.pin,
    required this.role,
  });

  bool get isAdmin => role == UserRole.admin;

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      name: map['name'] as String,
      pin: map['pin'] as String,
      role: map['role'] == 'admin' ? UserRole.admin : UserRole.cashier,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'pin': pin,
      'role': role == UserRole.admin ? 'admin' : 'cashier',
    };
  }

  @override
  List<Object?> get props => [id, name, pin, role];
}
