import 'package:flutter/material.dart';
import 'package:namer_app/components/user_provider.dart';
import 'package:namer_app/screens/users.dart';
import 'package:namer_app/services/auth.dart';
import 'package:namer_app/theme/theme.dart';
import 'package:provider/provider.dart';

import '../screens/Tour/tour_week_screen.dart';

class BasePage extends StatelessWidget {
  final Widget child;

  const BasePage({required this.child});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
      ),
      drawer: NavigationDrawer(),
      body: SafeArea(
        child: child,
      ),
    );
  }
}

class NavigationDrawer extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
            ),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),

          /*ListTile(
            leading: Icon(Icons.insights),
            title: Text('Insight'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/insight');
            },
          ),*/
          ListTile(
            leading: Icon(Icons.dashboard),
            title: Text('Items'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/items');
            },
          ),
          ListTile(
            leading: Icon(Icons.receipt_long),
            title: Text('Customer Bills'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/bills');
            }
          ),
          ListTile(
              leading: Icon(Icons.person),
              title: Text('Customers'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/customers');
              }
          ),

          ListTile(
              leading: Icon(Icons.request_quote),
              title: Text('Vendor Bills'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/vendors bills');
              }
          ),
          ListTile(
              leading: Icon(Icons.store),
              title: Text('Vendor'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/vendors');
              }
          ),


          ListTile(
              leading: Icon(Icons.tour),
              title: Text('Tour'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/tour');
              }
          ),
          userProvider.user!.role == "admin"
              ? ListTile(
            leading: Icon(Icons.people),
            title: Text('Users'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/users');
            },
          )
              : SizedBox(),

          userProvider.user!.role == "admin" ?
          ListTile(
              leading: Icon(Icons.info),
              title: Text('Business Info'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/businessInfo');
              }
          ) : SizedBox(),
          userProvider.user!.role == "admin" ?
          ListTile(
              leading: Icon(Icons.app_settings_alt_rounded),
              title: Text('Approval Request'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/request');
              }
          ) : SizedBox(),

          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () {
              AuthService.logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
    );
  }
}
