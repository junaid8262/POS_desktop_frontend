class Bill {
  String id;
  String customerId;
  List<BillItem> items;
  double totalAmount;
  double discount; // New attribute
  String paymentPromiseDate; // New attribute
  String status;
  String date;
  double amountGiven; // New attribute
  String billType;
  String description; // New attribute

  Bill({
    required this.id,
    required this.customerId,
    required this.items,
    required this.totalAmount,
    required this.discount, // New attribute
    required this.paymentPromiseDate, // New attribute
    required this.status,
    required this.date,
    required this.amountGiven, // New attribute
    required this.billType, // New attribute
    required this.description, // New attribute
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['_id'],
      customerId: json['customer'],
      items: (json['items'] as List).map((item) => BillItem.fromJson(item)).toList(),
      totalAmount: json['totalAmount'].toDouble(),
      discount: json['discount'].toDouble(), // New attribute
      paymentPromiseDate: json['paymentPromiseDate'], // New attribute
      status: json['status'],
      date: json['date'],
      amountGiven: json['amountGiven'].toDouble(), // New attribute
      billType: json['billType'], // New attribute
      description: json['description'], // New attribute
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer': customerId,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'discount': discount, // New attribute
      'paymentPromiseDate': paymentPromiseDate, // New attribute
      'status': status,
      'date': date,
      'amountGiven': amountGiven, // New attribute
      'billType': billType, // New attribute
      'description': description, // New attribute
    };
  }
}

class BillItem {
  String itemId;
  int quantity;
  double saleRate;
  double total;
  String name;
  double purchaseRate;
  String? customerName;  // Optional field for customer name
  String? date;  // Optional field for date
  double itemDiscount;
  final String? miniUnit;


  BillItem({
    required this.itemId,
    required this.quantity,
    required this.saleRate,
    required this.total,
    required this.name,
    required this.purchaseRate,
    required this.itemDiscount,
    required this.miniUnit,
    this.customerName,
    this.date,
  });

  // Factory method to create a BillItem from JSON
  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      itemId: json['itemId'] ?? json['item'] ?? '',
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 1,  // Default quantity to 1 if null
      saleRate: (json['saleRate'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      purchaseRate: (json['purchaseRate'] ?? 0).toDouble(),
      itemDiscount: (json['itemDiscount'] ?? 0).toDouble(),
      customerName: json['customerName'],  // Allow null
      date: json['date'],  // Allow null
      miniUnit: json['miniUnit'],

    );
  }

  // Method to convert the BillItem object to JSON
  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'quantity': quantity,
      'saleRate': saleRate,
      'miniUnit': miniUnit,
      'total': total,
      'name': name,
      'purchaseRate': purchaseRate,
      'itemDiscount': itemDiscount,
      'customerName': customerName,
      'date': date,
    };
  }
}
