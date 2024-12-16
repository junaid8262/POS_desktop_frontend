import 'package:flutter/material.dart';
import 'package:namer_app/screens/Request/request_detail_screen.dart';
import '../../models/request.dart';
import '../../services/request.dart';

class RequestScreen extends StatefulWidget {
  @override
  _RequestScreenState createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  List<Request>? _pendingRequests = [];
  final RequestService _requestService = RequestService();


  @override
  void initState() {
    super.initState();
    getPendingRequest();
  }

  Future<void> getPendingRequest() async {
    try {
      _pendingRequests = await _requestService.getPendingRequests();
      setState(() {}); // Trigger UI update after fetching requests
    } catch (e) {
      print('Error fetching requests: $e');
    }
  }

  Future<String> getRequestingUserName(String id) async {
    try {

      // Regular expression to find the username part
      RegExp regex = RegExp(r'username:\s*([^,}]+)');

      // Find the match
      RegExpMatch? match = regex.firstMatch(id);

      // Extract the username
      String? username = match?.group(1); // Group 1 contains the username

      print('Username: $username');

      return username ?? 'Unknown User';
    } catch (e) {
      print('Error fetching user: $e');
      return 'Unknown User';
    }
  }


  Future<void> showConfirmationDialog(
      BuildContext context, String action, String documentId, Function onActionConfirmed) async {
    // Show a confirmation dialog with the action name ("accept" or "reject")
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to dismiss
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(action == "approved" ? 'Are you sure you want to Approve this request?' : 'Are you sure you want to Reject this request?' ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text(action == "approved" ? 'Approve' : 'Reject'),
              onPressed: () {
                // Call the function passed when user confirms the action
                onActionConfirmed();
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }


  void handleRequest(String action, String documentId) async {
    // Show the confirmation dialog
    await showConfirmationDialog(context, action, documentId, () async {
      // Call performAction based on the action
      await _requestService.performAction(documentId, action);

      // Update the UI based on the result
      getPendingRequest();

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pendingRequests == null || _pendingRequests!.isEmpty
          ? Center(
        child: Text(
          'No pending requests',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blueGrey[50]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, // Adjust the number of items per row
            crossAxisSpacing: 16, // Horizontal space between items
            mainAxisSpacing: 16, // Vertical space between items
            childAspectRatio: 1.1, // Adjust the aspect ratio
          ),
          itemCount: _pendingRequests!.length,
          itemBuilder: (context, index) {
            final request = _pendingRequests![index];
            return FutureBuilder(
              future: getRequestingUserName(request.employeeId),  // Get the username
              builder: (context, AsyncSnapshot<String> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error loading data'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No data available'));
                }

                // Extract the username from the snapshot data
                final userName = snapshot.data!;  // Username is the data

                return _buildRequestCard(request, userName);  // Pass username to the card
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildRequestCard(Request request, String userName) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 40,
      shadowColor: Colors.grey.withOpacity(0.55),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20.0),
        height: 300, // Set a fixed height for the card
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Request type
            Row(
              children: [
                Text(
                  'REQUEST FOR ${request.documentType.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Spacer(),
                Tooltip(
                  message: 'View Details',
                  child: IconButton(
                    icon: Icon(Icons.visibility),
                    onPressed: () {
                      RequestDetailsPopup requestDetailsPopup = RequestDetailsPopup(context); // Pass current BuildContext
                      requestDetailsPopup.showRequestDetails(request); // Pass the Request object
                    },
                  ),
                ),


              ],
            ),
            SizedBox(height: 10),

            // User name
            Row(
              children: [
                Icon(Icons.person, color: Colors.blueAccent, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Requested by: $userName',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                    overflow: TextOverflow.ellipsis, // Handle long names
                  ),
                ),
              ],
            ),

            SizedBox(height: 10),

            // Bill details
            Row(
              children: [
                Icon(Icons.description, color: Colors.orangeAccent, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Type: ${request.documentType}',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            SizedBox(height: 10),

            // Bill ID
            Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ID: ${request.documentId}',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            SizedBox(height: 10),

            // Request Date
            Text(
              'Requested on: ${request.requestDate.toString().split(' ')[0]}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.blueGrey,
              ),
            ),

            SizedBox(height: 10),

            // Status with rounded background
            Container(
              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: BoxDecoration(
                color: request.status == 'Pending' ? Colors.orangeAccent : Colors.blueAccent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                'Status: ${request.status}',
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),

            Spacer(),

            // Approval and Denial buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionButton(
                  icon: Icons.check_circle,
                  color: Colors.green,
                  label: 'Approve',
                  onTap: () => handleRequest('approved', request.id),
                ),
                SizedBox(width: 10,),
                _buildActionButton(
                  icon: Icons.cancel,
                  color: Colors.red,
                  label: 'Deny',
                  onTap: () => handleRequest('denied', request.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.2),
      ),
      icon: Icon(icon, size: 20, color: Colors.white),
      label: Text(label, style: TextStyle(color: Colors.white, fontSize: 16)),
      onPressed: onTap,
    );
  }


}
