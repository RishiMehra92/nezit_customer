class ReturnReason {
  final int id;
  final String title;
  final bool proofRequired;
  final bool otpRequired;

  ReturnReason({
    required this.id,
    required this.title,
    required this.proofRequired,
    required this.otpRequired,
  });

  factory ReturnReason.fromJson(Map<String, dynamic> json) {
    return ReturnReason(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: json['title'] as String? ?? '',
      proofRequired: json['proof_required'] is bool
          ? json['proof_required'] as bool
          : (json['proof_required'] == 1 || json['proof_required'] == '1'),
      otpRequired: json['otp_required'] is bool
          ? json['otp_required'] as bool
          : (json['otp_required'] == 1 || json['otp_required'] == '1'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'proof_required': proofRequired,
      'otp_required': otpRequired,
    };
  }
}
