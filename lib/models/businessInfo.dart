class BusinessDetails {
  String? id;              // To store the ID of the business detail
  String companyLogo;
  String companyAddress;
  String companyPhoneNo;
  String companyName;

  BusinessDetails({
    this.id,
    required this.companyLogo,
    required this.companyAddress,
    required this.companyPhoneNo,
    required this.companyName,
  });

  // Convert JSON to BusinessDetails object
  factory BusinessDetails.fromJson(Map<String, dynamic> json) {
    return BusinessDetails(
      id: json['_id'],
      companyLogo: json['companyLogo'],
      companyAddress: json['companyAddress'],
      companyPhoneNo: json['companyPhoneNo'],
      companyName: json['companyName'],
    );
  }

  // Convert BusinessDetails object to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'companyLogo': companyLogo,
      'companyAddress': companyAddress,
      'companyPhoneNo': companyPhoneNo,
      'companyName': companyName,
    };
  }
}
