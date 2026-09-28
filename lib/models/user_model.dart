import '../services/encryption_service.dart';

class AppUser {
  final String uid;
  final String email;
  final String fullName;
  final String role;
  final String profileImage; // base64-encoded avatar image

  AppUser({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    this.profileImage = '',
  });

  Map<String, dynamic> toMapEncrypted() {
    return {
      'email': email,
      'fullNameEncrypted': EncryptionService.encryptText(fullName),
      'role': role,
      'profileImage': profileImage,
    };
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: map['email'] as String? ?? '',
      fullName: EncryptionService.decryptText(
          map['fullNameEncrypted'] as String? ?? ''),
      role: map['role'] as String? ?? 'user',
      profileImage: map['profileImage'] as String? ?? '',
    );
  }

  /// Returns a copy with the given fields replaced.
  AppUser copyWith({String? profileImage}) {
    return AppUser(
      uid: uid,
      email: email,
      fullName: fullName,
      role: role,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}

