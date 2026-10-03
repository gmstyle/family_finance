class FamilyMember {
  const FamilyMember({
    required this.userId,
    required this.role,
    required this.displayName,
  });

  final String userId;
  final String role;
  final String displayName;

  bool get isAdmin => role == 'admin';
}

class FamilyInvite {
  const FamilyInvite({
    required this.id,
    required this.invitedEmail,
    required this.token,
    required this.status,
    this.expiresAt,
  });

  final String id;
  final String invitedEmail;
  final String token;
  final String status;
  final DateTime? expiresAt;
}

class FamilyInfo {
  const FamilyInfo({
    required this.id,
    required this.name,
    required this.currency,
    required this.timezone,
    required this.ownerId,
    required this.status,
  });

  final String id;
  final String name;
  final String currency;
  final String timezone;
  final String ownerId;
  final String status;
}
