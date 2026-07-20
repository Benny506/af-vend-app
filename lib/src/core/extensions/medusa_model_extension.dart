import 'package:medusa_admin/src/core/utils/enums.dart';
import 'package:medusa_admin_dart_client/medusa_admin_dart_client_v2.dart';

extension UserFullName on User {
  String get fullName {
    if (firstName == null && lastName == null) {
      return email ?? 'No Name';
    }
    return '$firstName $lastName';
  }
}

extension CustomerName on Customer {
  String? get fullName {
    if (firstName == null && lastName == null) {
      return null;
    }
    return '${firstName ?? ''} ${lastName ?? ''}';
  }
}

extension AuthTypeExtension on String? {
  AuthenticationType authType() {
    switch (this) {
      case 'JWT':
        return AuthenticationType.jwt;
      case 'Cookie':
        return AuthenticationType.cookie;
      case 'Api Token':
        return AuthenticationType.token;
      default:
        return AuthenticationType.jwt;
    }
  }
}

extension OrderExtension on Order {
  String get currencyCode => (metadata?['currency_code'] as String?) ?? 'usd';
  num get subTotal => (metadata?['subtotal'] as num?) ?? subtotal ?? 0;
  num get shippingTotalValue => (metadata?['shipping_total'] as num?) ?? shippingTotal ?? 0;
  num get taxTotalValue => (metadata?['tax_total'] as num?) ?? taxTotal ?? 0;
  num get totalValue => (metadata?['total'] as num?) ?? total ?? 0;
  num get refundedTotal => (metadata?['refunded_total'] as num?) ?? summary?.refundedTotal ?? 0;
  num get paidTotal => (metadata?['paid_total'] as num?) ?? summary?.paidTotal ?? 0;
  num get refundableAmount => totalValue - refundedTotal;
  Address? get shippingAddress => metadata?['shipping_address'] != null 
      ? Address.fromJson(Map<String, dynamic>.from(metadata?['shipping_address'] as Map)) 
      : null;
  String get customerName {
    final address = metadata?['shipping_address'] as Map?;
    if (address == null) return 'N/A';
    final firstName = address['first_name'] as String?;
    final lastName = address['last_name'] as String?;
    if (firstName == null && lastName == null) return 'N/A';
    return '${firstName ?? ''} ${lastName ?? ''}'.trim();
  }
}

