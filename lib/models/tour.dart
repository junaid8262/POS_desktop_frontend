class Tour {
  final String id;
  final String routeName;
  final String dayOfRoute; // You can change this to List<String> if you want to handle multiple days
  final String salesman;
  final List<String> customerIds; // Assuming customer IDs are passed as a list of strings
  final List<History> history; // History field

  Tour({
    required this.id,
    required this.routeName,
    required this.dayOfRoute,
    required this.salesman,
    required this.customerIds,
    List<History>? history, // Make history optional
  }) : this.history = history ?? []; // Set default value to an empty list if null

  factory Tour.fromJson(Map<String, dynamic> json) {
    return Tour(
      id: json['_id'],
      routeName: json['routeName'],
      dayOfRoute: json['dayOfRoute'],
      salesman: json['salesman'],
      customerIds: List<String>.from(json['customerIds']),
      history: (json['history'] as List?)?.map((item) => History.fromJson(item)).toList() ?? [], // Handle null case
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'routeName': routeName,
      'dayOfRoute': dayOfRoute,
      'salesman': salesman,
      'customerIds': customerIds,
      'history': history.map((item) => item.toJson()).toList(), // Convert history to JSON
    };
  }
}
class History {
  final List<CustomerTourInfo> billDetails;
  final String date;

  History({
    required this.billDetails,
    required this.date,
  });

  factory History.fromJson(Map<String, dynamic> json) {
    var billList = json['billDetails'] as List;
    List<CustomerTourInfo> bills = billList
        .map((bill) => CustomerTourInfo.fromJson(bill))
        .toList();

    return History(
      billDetails: bills, // Assign bills to billDetails
      date: json['date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'billDetails': billDetails.map((bill) => bill.toJson()).toList(), // Convert List<CustomerBillingInfo> to JSON
      'date': date,
    };
  }
}


class CustomerTourInfo {
  final String customerId;
  final String customerName;
  final String debitBill;
  final String discountBill;
  final String returnBill;

  CustomerTourInfo({
    required this.customerId,
    required this.customerName,
    required this.debitBill,
    required this.discountBill,
    required this.returnBill,
  });

  factory CustomerTourInfo.fromJson(Map<String, dynamic> json) {
    return CustomerTourInfo(
      customerId: json['customerId'],
      customerName: json['customerName'],
      debitBill: json['debitBill'],
      discountBill: json['discountBill'],
      returnBill: json['returnBill'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'debitBill': debitBill,
      'discountBill': discountBill,
      'returnBill': returnBill,
    };
  }
}
