import 'package:medusa_admin/src/core/utils/enums.dart';

class AuthPreference {
  final bool? useBiometric;
  final AuthenticationType authType;
  final MedusaApiVersion medusaApiVersion;

  AuthPreference({
    this.useBiometric,
    required this.authType,
    required this.medusaApiVersion,
  });

  AuthPreference.defaultSettings({
    this.useBiometric,
    this.authType = AuthenticationType.jwt,
    this.medusaApiVersion = MedusaApiVersion.v1,
  });

  AuthPreference copyWith({
    bool? useBiometric,
    bool resetBiometric = false,
    AuthenticationType? authType,
    MedusaApiVersion? medusaApiVersion,
  }) =>
      AuthPreference(
        useBiometric: resetBiometric ? null : useBiometric ?? this.useBiometric,
        authType: authType ?? this.authType,
        medusaApiVersion: medusaApiVersion ?? this.medusaApiVersion,
      );

  Map<String, dynamic> toJson() => {
        'useBiometric': useBiometric,
        'authType': authType.toString(),
        'medusaApiVersion': medusaApiVersion.toString(),
      };

  factory AuthPreference.fromJson(Map<String, dynamic>? json) {
    return AuthPreference(
      useBiometric: json?['useBiometric'],
      authType: AuthenticationType.values.firstWhere(
        (element) => element.toString() == json?['authType'],
        orElse: () => AuthenticationType.jwt,
      ),
      medusaApiVersion: MedusaApiVersion.values.firstWhere(
        (element) => element.toString() == json?['medusaApiVersion'],
        orElse: () => MedusaApiVersion.v1,
      ),
    );
  }
}


