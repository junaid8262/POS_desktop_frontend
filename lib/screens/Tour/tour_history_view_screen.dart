import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:namer_app/services/bills.dart';
import 'package:namer_app/services/customers.dart';
import 'package:provider/provider.dart';
import '../../components/bussiness_info_provider.dart';
import '../../models/bills.dart';
import '../../models/customer.dart';
import '../../models/tour.dart';
import '../../services/tour.dart';
import '../Customer Bills/Bill Widgets/show_bill_items.dart';

class TourHistoryDialog extends StatefulWidget {
  final Tour tour;

  TourHistoryDialog({required this.tour});

  @override
  _TourHistoryDialogState createState() => _TourHistoryDialogState();
}

class _TourHistoryDialogState extends State<TourHistoryDialog> {
  final TourService _tourService = TourService();
  bool _isLoading = false;
  late Tour _tour;

  @override
  void initState() {
    super.initState();
    _tour = widget.tour;
    _loadTourHistory();
  }

  Future<void> _loadTourHistory() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final updatedTour = await _tourService.getTourById(_tour.id);
      setState(() {
        _tour = updatedTour;
      });
    } catch (e) {
      print('Error loading tour history: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue.shade700,
          title: Text(
            'Tour History: ${_tour.routeName}',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _tour.history.isEmpty
            ? Center(
          child: Text(
            'No history available for this tour.',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        )
            : ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: _tour.history.length,
          itemBuilder: (context, historyIndex) {
            final history = _tour.history[historyIndex];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 4,
              margin: EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                leading: Icon(
                  Icons.history,
                  color: Colors.blue.shade700,
                  size: 30, // Increased icon size for better visibility
                ),
                title: Text(
                  'History Date: ${DateFormat.yMMMd().format(DateFormat('dd-MM-yyyy').parse(history.date))}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                tilePadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                childrenPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                collapsedIconColor: Colors.blue.shade700,
                children: [
                  Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 4.0),
                    child:ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: history.billDetails.length,
                      itemBuilder: (context, customerIndex) {
                        final customer = history.billDetails[customerIndex];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            color: Colors.blue.shade50,
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              leading: CircleAvatar(
                                backgroundColor: Colors.blueAccent,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              title: Text(
                                'Customer: ${customer.customerName}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Text(
                                    'Customer ID: ${customer.customerId}',
                                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                                  ),
                                  SizedBox(height: 6),
                                  _buildBillDetail('Debit Bill', customer.debitBill, customer.customerId),
                                  _buildBillDetail('Discount Bill', customer.discountBill, customer.customerId),
                                  _buildBillDetail('Return Bill', customer.returnBill, customer.customerId),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    )

                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBillDetail(String title, String billId, String customerId) {
    if (billId.isNotEmpty) {
      return TextButton.icon(
        onPressed: () async {
          try {
            // Fetch the bill using the billId
            BillService _billService = BillService();

            // Show a loading indicator or handle loading state here if needed

            Bill? bill = await _billService.getBill(billId);

            // Ensure the bill is not null
            if (bill == null) {
              print("Bill not found");
              return;
            }

            // Fetch the customer details
            Customer customer = await _billService.getCustomerById(customerId);

            // Check if the widget is still mounted before accessing the context
            if (!mounted) return;

            // Get the business details from the provider
            final businessDetails = Provider.of<BusinessDetailsProvider>(context, listen: false).businessDetails;

            // Determine which type of bill to show
            if (title == "Return Bill") {
              ShowBillItems.show(context, bill, customer, businessDetails);
            } else if (title == "Discount Bill" || title == "Debit Bill") {
              ShowBillItems.showDebitAndDiscountBill(context, bill, customer, businessDetails);
            }
          } catch (e) {
            // Handle errors and exceptions
            print('Error occurred: $e');
          }
        },
        icon: Icon(
          Icons.receipt_long,
          color: Colors.blue.shade700,
          size: 18,
        ),
        label: Text(
          '$title: View',
          style: TextStyle(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(
          '$title: Not Added',
          style: TextStyle(
            color: Colors.redAccent,
            fontStyle: FontStyle.italic,
            fontSize: 12,
          ),
        ),
      );
    }
  }
}

void showTourHistoryDialog(BuildContext context, Tour tour) {
  showDialog(
    context: context,
    builder: (context) => TourHistoryDialog(tour: tour),
  );
}
