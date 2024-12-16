class VendorBill {
  String id;
  String vendorId;
  List<VendorBillItem> items;
  String billType;
  double totalAmount;
  double discount;
  String paymentPromiseDate;
  String status;
  String date;
  double amountGiven;
  String description;

  VendorBill({
    required this.id,
    required this.vendorId,
    required this.items,
    required this.billType,
    required this.totalAmount,
    required this.discount,
    required this.paymentPromiseDate,
    required this.status,
    required this.date,
    required this.amountGiven,
    required this.description,
  });

  factory VendorBill.fromJson(Map<String, dynamic> json) {
    return VendorBill(
      id: json['_id'] ?? '',
      vendorId: json['vendor'] ?? '',
      items: (json['items'] as List)
          .map((item) => VendorBillItem.fromJson(item))
          .toList(),
      billType: json['billType'] ?? 'Sale Bill',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      paymentPromiseDate: json['paymentPromiseDate'] ?? '',
      status: json['status'] ?? 'Non Completed',
      date: json['date'] ?? '',
      amountGiven: (json['amountGiven'] ?? 0).toDouble(),
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vendor': vendorId,
      'items': items.map((item) => item.toJson()).toList(),
      'billType': billType,
      'totalAmount': totalAmount,
      'discount': discount,
      'paymentPromiseDate': paymentPromiseDate,
      'status': status,
      'date': date,
      'amountGiven': amountGiven,
      'description': description,
    };
  }
}

class VendorBillItem {
  String itemId;
  int quantity;
  double purchaseRate;
  double total;
  String name;
  String? vendorName;
  String? date;
  String? miniUnit;

  VendorBillItem({
    required this.itemId,
    required this.quantity,
    required this.purchaseRate,
    required this.total,
    required this.name,
    required this.miniUnit,
    this.vendorName,
    this.date,
  });

  factory VendorBillItem.fromJson(Map<String, dynamic> json) {
    return VendorBillItem(
      itemId: json['itemId'] ?? json['item'] ?? '',
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 1,  // Default quantity to 1 if null
      purchaseRate: (json['purchaseRate'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      vendorName: json['vendorName'],  // Allow null
      date: json['date'],  // Allow null
      miniUnit: json['miniUnit'],  // Allow null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'quantity': quantity,
      'purchaseRate': purchaseRate,
      'total': total,
      'name': name,
      'vendorName': vendorName,
      'date': date,
      'miniUnit': miniUnit,
    };
  }
}
