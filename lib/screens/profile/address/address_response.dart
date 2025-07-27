class AddressResponse {
  final String message;
  final List<Address> addresses;
  final String defaultAddressId;

  AddressResponse({
    required this.message,
    required this.addresses,
    required this.defaultAddressId,
  });

  factory AddressResponse.fromJson(Map<String, dynamic> json) {
    return AddressResponse(
      message: json['message'] ?? '',
      addresses: (json['addresses'] as List)
          .map((e) => Address.fromJson(e))
          .toList(),
      defaultAddressId: json['defaultAddressId'] ?? '',
    );
  }
}

class Address {
  final String id;
  final String label;
  final String address;

  Address({
    required this.id,
    required this.label,
    required this.address,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] ?? '',
      label: json['label']?.trim() ?? '',
      address: json['address'] ?? '',
    );
  }
}
