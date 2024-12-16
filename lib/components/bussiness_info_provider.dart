import 'package:flutter/material.dart';

import '../models/businessInfo.dart';

class BusinessDetailsProvider extends ChangeNotifier {
  BusinessDetails? _businessDetails;

  BusinessDetails? get businessDetails => _businessDetails;

  void setBusinessDetails(BusinessDetails newBusinessDetails) {
    _businessDetails = newBusinessDetails;
    notifyListeners(); // Notify listeners that the business details have changed
  }

  void clearBusinessDetails() {
    _businessDetails = null;
    notifyListeners(); // Notify listeners that the business details have been cleared
  }

  void updateBusinessDetails({
    String? companyLogo,
    String? companyAddress,
    String? companyPhoneNo,
    String? companyName,
    String? id,
  }) {
    if (_businessDetails != null) {
      _businessDetails = _businessDetails!.copyWith(
        companyLogo: companyLogo ?? _businessDetails!.companyLogo,
        companyAddress: companyAddress ?? _businessDetails!.companyAddress,
        companyPhoneNo: companyPhoneNo ?? _businessDetails!.companyPhoneNo,
        companyName: companyName ?? _businessDetails!.companyName,
        id: id ?? _businessDetails!.id,
      );
      notifyListeners();
    }
  }
}

// Extension method for copyWith in BusinessDetails
extension BusinessDetailsCopyWith on BusinessDetails {
  BusinessDetails copyWith({
    String? companyLogo,
    String? companyAddress,
    String? companyPhoneNo,
    String? companyName,
    String? id,
  }) {
    return BusinessDetails(
      id: id ?? this.id,
      companyLogo: companyLogo ?? this.companyLogo,
      companyAddress: companyAddress ?? this.companyAddress,
      companyPhoneNo: companyPhoneNo ?? this.companyPhoneNo,
      companyName: companyName ?? this.companyName,
    );
  }
}
