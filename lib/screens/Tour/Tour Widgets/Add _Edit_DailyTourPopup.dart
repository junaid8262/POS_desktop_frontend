import 'package:flutter/material.dart';

import '../../../models/customer.dart';
import '../../../models/tour.dart';
import '../../../services/customers.dart';
import '../../../services/tour.dart';
import 'customer_selection_dialog.dart';



class DailyTourPopup extends StatefulWidget {
  final Tour? tour; // Make tour optional
  final VoidCallback onTourUpdated; // Add the callback parameter

  // Constructor
  DailyTourPopup({this.tour, required this.onTourUpdated}); // Update constructor

  @override
  _DailyTourPopupState createState() => _DailyTourPopupState();
}

class _DailyTourPopupState extends State<DailyTourPopup> {
  final TextEditingController _tourNameController = TextEditingController();
  final TextEditingController _salesmanNameController = TextEditingController();
  final CustomerService _customerService = CustomerService();
  final TourService _tourService  = TourService();
  String _selectedDay = 'Monday';
  List<String> _daysOfWeek = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  List<Customer> _selectedCustomers = [];

  @override
  void initState() {
    super.initState();
    // If tour object is not null, populate the controllers
    if (widget.tour != null) {
      _tourNameController.text = widget.tour!.routeName;
      _selectedDay = widget.tour!.dayOfRoute;
      _salesmanNameController.text = widget.tour!.salesman;

      // Fetch customer details based on the tour's customer IDs
      _fetchCustomerDetails(widget.tour!.customerIds);
    }
  }

  Future<void> _fetchCustomerDetails(List<String> customerIds) async {
    List<Customer> customers = [];

    for (String id in customerIds) {
      try {
        // Fetch customer by ID and add it to the list
        Customer customer = await _customerService.getCustomerById(id);
        customers.add(customer);
      } catch (e) {
        print("Error fetching customer with ID $id: $e");
      }
    }

    setState(() {
      _selectedCustomers = customers; // Update the selected customers list
    });
  }


  void _addEditTour() async {
    Tour tour = Tour(
      id: widget.tour?.id ?? '', // Generate a new ID if adding a new tour
      routeName: _tourNameController.text,
      dayOfRoute: _selectedDay,
      salesman: _salesmanNameController.text,
      customerIds: _selectedCustomers.map((customer) => customer.id).toList(), // Assuming Customer has an 'id' property
    );

    try {
      if (widget.tour == null) {
        // Add new tour logic
        await _tourService.createTour(tour);
        print("Tour added successfully: ${tour.routeName}");
      } else {
        // Edit existing tour logic
        await _tourService.updateTour(widget.tour!.id, tour);
        print("Tour edited successfully: ${tour.routeName}");
      }

      // Invoke the callback function after adding or editing
      widget.onTourUpdated(); // Call the callback here
    } catch (e) {
      print("Error: $e"); // Handle any errors that occur
    } finally {
      // Close dialog after adding or editing
      Navigator.of(context).pop();
    }
  }


  void _selectCustomers() async {
    final customers = await _customerService.getCustomers();

    // Call the CustomerSelectionDialog
    final List<Customer>? selectedCustomers = await showDialog<List<Customer>>(
      context: context,
      builder: (BuildContext context) {

        return CustomerSelectionDialog(
          customers: customers,  // Pass the list of customers
          onCustomersSelected: (selected) {
            Navigator.of(context).pop(selected); // Return the selected customers
          },
        );
      },
    );

    // Handle selected customers if not null
    if (selectedCustomers != null) {
      setState(() {
        // Iterate over the newly selected customers
        for (var newCustomer in selectedCustomers) {
          // Check if the customer is already in the _selectedCustomers list
          bool exists = _selectedCustomers.any((existingCustomer) => existingCustomer.id == newCustomer.id);

          // If the customer is not in the list, add it
          if (!exists) {
            _selectedCustomers.add(newCustomer);
          }
        }
      });

      // Optionally, you can also print or do something with the selected customers
      print('Selected Customers: ${_selectedCustomers.map((c) => c.name).toList()}');
    }
  }

  void _removeSuggestion(int index) {
    setState(() {
      _selectedCustomers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Container(
        width: 400, // Specify width for the ListView container
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Daily Tour', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tour Name Field
              _buildInputField(
                controller: _tourNameController,
                label: 'Tour Name',
              ),
              const SizedBox(height: 16),
              // Tour Day Dropdown
              _buildDropdownField(
                label: 'Tour Day',
                value: _selectedDay,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedDay = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Salesman Name Field
              _buildInputField(
                controller: _salesmanNameController,
                label: 'Salesman Name',
                onChanged: (newValue) {
                  setState(() {
                    _salesmanNameController.text = newValue;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Select Customers Button
              _buildElevatedButton(
                label: 'Select Customers',
                onPressed: _selectCustomers,
              ),
              const SizedBox(height: 16),

              if (_selectedCustomers.isNotEmpty)
                Container(
                  height: 250, // Specify height for the ListView container
                  width: 400, // Specify width for the ListView container
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 4.0,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    itemCount: _selectedCustomers.length,
                    itemBuilder: (context, index) {
                      final suggestion = _selectedCustomers[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.0),
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.grey[100]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 4.0,
                              offset: Offset(0, 2),
                            ),
                          ],
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueGrey[100],
                            child: Icon(Icons.person, color: Colors.blueAccent),
                          ),
                          title: Text(
                            suggestion.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              color: Colors.blueGrey[900],
                            ),
                          ),
                          subtitle: Text(
                            "ID: ${suggestion.id}",
                            style: TextStyle(
                              color: Colors.blueGrey[600],
                              fontSize: 14,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.remove_circle, color: Colors.redAccent),
                            onPressed: () => _removeSuggestion(index),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 20),
              // Add/Edit Tour Button
              _buildElevatedButton(
                label: widget.tour == null ? 'Add Tour' : 'Edit Tour',
                onPressed: _salesmanNameController.text.isEmpty ? null : _addEditTour,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    void Function(String)? onChanged, // Optional onChanged parameter
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged, // Only call onChanged if it's not null
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),

        filled: true,
        fillColor: Colors.grey[200],
      ),
    );
  }
  Widget _buildDropdownField({required String label, required String value, required ValueChanged<String?> onChanged}) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      items: _daysOfWeek.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[200],
      ),
    );
  }

  Widget _buildElevatedButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 50, // Set the height if provided
      width: 200,   // Set the width if provided
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          backgroundColor: Theme.of(context).primaryColor,
          disabledBackgroundColor: Colors.white,
          elevation: 5,
        ),
        child: Text(label),
      ),
    );
  }

}
