class Customer {
  final String id;
  final String name;
  final String phoneNumber;
  final String address;
  final String tour;
  late final double balance;

  Customer({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.address,
    required this.tour,
    required this.balance,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['_id'],
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      address: json['address'],
      tour: json['tour'],
      balance: json['balance'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'address': address,
      'tour': tour,
      'balance': balance,
    };
  }
}
