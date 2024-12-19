import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:process_run/process_run.dart';
import 'package:provider/provider.dart';
import '../components/bussiness_info_provider.dart';
import '../components/input_field.dart';
import '../components/user_provider.dart';
import '../models/bills.dart';
import '../models/businessInfo.dart';
import '../models/user.dart';
import '../services/auth.dart';
import '../services/businessInfo.dart';
import '../theme/theme.dart';
import 'Customer Bills/edit_or_add_bill.dart'; // Update this import with your actual path
import 'package:http/http.dart' as http;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>  with WidgetsBindingObserver{
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final BusinessDetailsService _businessDetailsService = BusinessDetailsService();

  bool _isLoading = false;


  /////////////////////////////////////////
  /////////////////////////////////////////
  /////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////////
  ////////////////////THESE FUNCTIONS ARE FOR LOCAL DEPLOYEMENT OF THE APP ////////
  //////////////////////////////////////////////////////////////////////////////////
  ////////////////////SO YOU CAN REMOVE THEM BEFORE STARTING THE APP ///// ////////
  ////////////////////////////////////////////////////////////////////////////////
/*

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Start in test mode with custom paths
    startBackendServices(
        isTest: true,
        mongoTestPath: 'D:/IAMS/mongodb/mongod.exe',  // Correct path to MongoDB executable
        nodeTestPath: 'D:/IAMS/node-backend.exe'      // Correct path to Node.js backend executable
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      stopMongoDB();
      stopNodeBackend();
    }
  }

  // Method to start backend services
  Future<void> startBackendServices({bool isTest = false, String? mongoTestPath, String? nodeTestPath}) async {
    try {
      await startMongoDB(isTest: isTest, testPath: mongoTestPath).then((_) async {
        showSnackbar("MongoDB started successfully!", Colors.green);
        // No user seeding required, removed seedUser.js functionality
      });
    } catch (e) {
      showSnackbar("Error starting MongoDB: $e", Colors.red);
    }

    try {
      await startNodeBackend(isTest: isTest, testPath: nodeTestPath).then((_) {
        showSnackbar("Node.js backend started successfully!", Colors.green);
      });
    } catch (e) {
      showSnackbar("Error starting Node.js backend: $e", Colors.red);
    }
    //checkBackendHealth();

  }

  // Helper method to show a snackbar
  void showSnackbar(String message, Color color) {
    final snackBar = SnackBar(

      content: Text(message),
      backgroundColor: color,
      duration: Duration(seconds: 2), // Set the duration to 2 seconds

    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Method to start MongoDB
  Future<void> startMongoDB({bool isTest = false, String? testPath}) async {
    var shell = Shell();
    String dbPath = isTest && testPath != null ? 'D:/IAMS/db' : 'db';  // Adjust this path for your data directory
    try {
      // Use the correct path to the MongoDB executable
      await shell.run('''"${isTest && testPath != null ? testPath : 'mongodb/mongod.exe'}" --dbpath "$dbPath"''');
      print('MongoDB started successfully.');
    } catch (e) {
      print('Failed to start MongoDB: $e');
    }
  }

  // Method to start Node.js backend
  Future<void> startNodeBackend({bool isTest = false, String? testPath}) async {
    var shell = Shell();
    try {
      // Use the correct path to the Node.js executable
      await shell.run('''"${isTest && testPath != null ? testPath : 'node-backend.exe'}"''');
      print('Node.js backend started successfully.');
    } catch (e) {
      print('Failed to start Node.js backend: $e');
    }
  }

  // Method to stop MongoDB
  Future<void> stopMongoDB() async {
    var shell = Shell();
    try {
      await shell.run('''taskkill /F /IM mongod.exe''');
      print('MongoDB stopped successfully.');
    } catch (e) {
      print('Failed to stop MongoDB: $e');
    }
  }

  // Method to stop Node.js backend
  Future<void> stopNodeBackend() async {
    var shell = Shell();
    try {
      await shell.run('''taskkill /F /IM node-backend.exe''');
      print('Node.js backend stopped successfully.');
    } catch (e) {
      print('Failed to stop Node.js backend: $e');
    }
  }

*/


/*  Future<void> checkBackendHealth() async {
    try {
      // Check Node.js backend health
      final nodeResponse = await http.get(Uri.parse('http://localhost:3000/health'));
      print("Node.js backend response: ${nodeResponse.statusCode}");
      if (nodeResponse.statusCode == 200) {
        showSnackbar("Node.js Backend is Active", Colors.green);
      } else {
        showSnackbar("Node.js Backend is down", Colors.red);
      }

      // Check MongoDB health
      final dbResponse = await http.get(Uri.parse('http://localhost:3000/db-health'));
      print("MongoDB health response: ${dbResponse.statusCode}");
      if (dbResponse.statusCode == 200) {
        showSnackbar("MongoDB is Connected", Colors.green);
      } else {
        showSnackbar("MongoDB is not connected", Colors.red);
      }

      // Check system health
      final systemResponse = await http.get(Uri.parse('http://localhost:3000/system-health'));
      print("System health response: ${systemResponse.statusCode}");
      if (systemResponse.statusCode == 200) {
        showSnackbar("System Health: OK", Colors.green);
      } else {
        showSnackbar("System Health: Issues detected", Colors.orange);
      }

      // Check environment variables
      final envResponse = await http.get(Uri.parse('http://localhost:3000/env-health'));
      print("Environment variables health response: ${envResponse.statusCode}");
      if (envResponse.statusCode == 200) {
        showSnackbar("Environment Variables: OK", Colors.green);
      } else {
        showSnackbar("Missing Environment Variables", Colors.red);
      }
    } catch (e) {
      print("Error: $e");
      showSnackbar("Error: $e", Colors.red);
    }
  }*/



  //////////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////
  /////////////////////////////////////////


  void _showAddEditBillDialog([Bill? bill]) {
    showDialog(
      context: context,
      builder: (context) => AddEditBillDialog(
        bill: bill,
        onBillSaved: (){},
      ),
    );
  }



  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    final user = await _authService.login(username, password);
    List<BusinessDetails> businessDetails = await _businessDetailsService.getBusinessDetails();

    setState(() {
      _isLoading = false;
    });

    if (user != null) {

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.setUser(user);

      print(businessDetails[0].companyName);
      print(businessDetails.length);
      if (businessDetails.isNotEmpty )
        {
          print("provider check");
          final businessProvider = Provider.of<BusinessDetailsProvider>(context, listen: false);
          businessProvider.setBusinessDetails(businessDetails[0]);
          print(businessProvider.businessDetails!.companyName);

        }
      else
        {

          BusinessDetails businessDetailsTemp = BusinessDetails(
              companyLogo: '', companyAddress: "Add Company Address",
              companyPhoneNo: "Add Company PhoneNo", companyName: 'Add Company Name');
          final businessProvider = Provider.of<BusinessDetailsProvider>(context, listen: false);
          businessProvider.setBusinessDetails(businessDetailsTemp);

        }

      Navigator.pushNamed(context, '/bills');
      _showAddEditBillDialog();
    } else {
      // Show an error message
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Login Failed'),
            content: Text('Invalid username or password.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  height: constraints.maxHeight,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                    ),
                    child: SvgPicture.asset(
                      'assets/login.svg',
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child:Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Login', style: AppTheme.headline1),
                    SizedBox(height: 20),
                    CustomTextField(
                      controller: _usernameController,
                      label: 'Username',
                    ),
                    SizedBox(height: 20),
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Password',
                      obscureText: true,
                    ),
                    SizedBox(height: 20),
                    _isLoading
                        ? CircularProgressIndicator()
                        : ElevatedButton(
                      onPressed: _handleLogin,
                      style: AppTheme.elevatedButtonStyle,
                      child: Text('Login', style: AppTheme.button),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
