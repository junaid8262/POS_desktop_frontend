class Vendor {
  final String id;
  final String name;
  final String phoneNumber;
  final String address;
  final String businessName;
  late final double balance;

  Vendor({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.address,
    required this.businessName,
    required this.balance,

  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['_id'],
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      address: json['address'],
      businessName: json['businessName'],
      balance: json['balance'].toDouble(),

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'address': address,
      'businessName': businessName,
      'balance': balance,

    };
  }
}
