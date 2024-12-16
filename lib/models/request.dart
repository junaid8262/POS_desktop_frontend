class Request {
  final String id;
  final String employeeId;
  final String documentType;
  final String documentId;
  final String status;
  final String? adminResponse;
  final DateTime requestDate;

  Request({
    required this.id,
    required this.employeeId,
    required this.documentType,
    required this.documentId,
    required this.status,
    this.adminResponse,
    required this.requestDate,
  });

  // Factory method to create a Request object from JSON
  factory Request.fromJson(Map<String, dynamic> json) {
    return Request(
      id: json['_id'] as String,
      employeeId: json['employeeId'].toString() ,
      documentType: json['documentType'] as String,
      documentId: json['documentId'].toString() ,
      status: json['status'] as String,
      adminResponse: json['adminResponse'] as String?,
      requestDate: DateTime.parse(json['requestDate']),
    );
  }

  // Method to convert a Request object into JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'employeeId': employeeId,
      'documentType': documentType,
      'documentId': documentId,
      'status': status,
      'adminResponse': adminResponse,
      'requestDate': requestDate.toIso8601String(),
    };
  }
}
