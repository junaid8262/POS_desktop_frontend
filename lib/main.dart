import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:namer_app/components/base_page.dart';
import 'package:namer_app/screens/Customer%20Bills/bills.dart';
import 'package:namer_app/screens/Customer/customers.dart';
import 'package:namer_app/screens/Request/request.dart';
import 'package:namer_app/screens/Tour/tour_week_screen.dart';
import 'package:namer_app/screens/Vendor%20Bills/vendor_bills.dart';
import 'package:namer_app/screens/Vendor/vendors.dart';
import 'package:namer_app/screens/business_info_screen.dart';
import 'package:namer_app/screens/insight_graph.dart';
import 'package:namer_app/screens/login.dart';
import 'package:namer_app/screens/users.dart';
import 'package:namer_app/theme/theme.dart';
import 'package:process_run/process_run.dart';
import 'package:provider/provider.dart';
import 'components/bussiness_info_provider.dart';
import 'components/user_provider.dart';
import 'models/bills.dart';
import 'screens/Items/item_management.dart';

class MyApp extends StatelessWidget {



  @override
  Widget build(BuildContext context) {



    return MaterialApp(
      debugShowCheckedModeBanner: false, // This line removes the debug banner

      title: 'Flutter Inventory',
      theme: AppTheme.themeData,
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/items': (context) => BasePage(child: ItemsPage()),
        '/bills': (context) => BasePage(child: BillsPage()),
        '/customers': (context) => BasePage(child: CustomerPage()),
        '/users': (context) => BasePage(child: UserPage()),
        '/vendors': (context) => BasePage(child: VendorPage()),
        '/vendors bills': (context) => BasePage(child: VendorBillsPage()),
        '/insight': (context) => BasePage(child: InsightGraphsPage()),
        '/tour': (context) => BasePage(child: TourWeek()),
        '/request': (context) => BasePage(child: RequestScreen()),
        '/businessInfo': (context) => BasePage(child: BusinessInfoScreen()),
      },
    );
  }
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => BusinessDetailsProvider()),
      ],
      child: MyApp(),
    ),
  );

 /* if (args.isNotEmpty && args.first == 'multi_window') {
    final windowId = int.parse(args[1]);
    final arguments = args.length > 2 ? jsonDecode(args[2]) : {};
    runApp(SubWindowApp(windowId: windowId, arguments: arguments));
  } else {

  }*/



}

class SubWindowApp extends StatefulWidget {
  final int windowId;
  final Map<String, dynamic> arguments;

  SubWindowApp({required this.windowId, required this.arguments});

  @override
  _SubWindowAppState createState() => _SubWindowAppState();
}

class _SubWindowAppState extends State<SubWindowApp> {
  int result = 0;
  bool isCalculating = false;
  String cpuUsage = "Fetching...";
  int n = 35; // The value for Fibonacci calculation

  @override
  void initState() {
    super.initState();
  }

  // Simulate a high load function: Fibonacci calculation with progress updates
  Future<void> calculateFibonacci(int n) async {
    setState(() {
      isCalculating = true;
    });

    int fib(int n) {
      if (n <= 1) return n;
      return fib(n - 1) + fib(n - 2);
    }

    // Execute the high load calculation
    int fibonacciResult = fib(n);

    setState(() {
      result = fibonacciResult;
      isCalculating = false;
    });
  }

  // Fetch CPU usage


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Sub Window with High Load')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Arguments: ${widget.arguments}', style: TextStyle(fontSize: 16)),
              SizedBox(height: 20),

              Text('CPU Usage: $cpuUsage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),

              isCalculating
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: () {
                  calculateFibonacci(n);
                },
                child: Text('Run High-Load Task'),
              ),

              if (!isCalculating)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text('Fibonacci($n) = $result', style: TextStyle(fontSize: 18)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
