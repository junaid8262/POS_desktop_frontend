import 'package:flutter/material.dart';
import 'package:namer_app/models/user.dart';
import 'package:namer_app/services/users.dart';
import 'package:namer_app/theme/theme.dart';
import 'package:namer_app/components/input_field.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/user_provider.dart';

class UserDataSource extends DataTableSource {
  final List<User> users;
  final void Function(User) onEdit;
  final void Function(String) onDelete;
  List<User> filteredUsers;

  UserDataSource({
    required this.users,
    required this.onEdit,
    required this.onDelete,
  }) : filteredUsers = List.from(users);

  void filterUsers(String query) {
    final lowerQuery = query.toLowerCase();
    filteredUsers = users.where((user) {
      return user.email.toLowerCase().contains(lowerQuery);
    }).toList();
    notifyListeners();
  }

  @override
  DataRow? getRow(int index) {
    final user = filteredUsers[index];
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(user.email)),
        DataCell(Text(user.role)),
        DataCell(Row(
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: () => onEdit(user),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => onDelete(user.email),
            ),
          ],
        )),
      ],
    );
  }

  @override
  int get rowCount => filteredUsers.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}

class UserPage extends StatefulWidget {
  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  User? _user;
  final UserService _userService = UserService();
  List<User> _users = [];
  UserDataSource? _dataSource;
  bool _isLoading = true;
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkRole();
  }
//13Dec(updated)
// Latest Update (Role Was Not Fetching properly shared Prefs were used prev)
  Future<void> _checkRole() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _user = userProvider.user;
    String? role = _user!.role;
    if (role != 'admin') {
      Placeholder();
    } else {
      _fetchUsers();
    }
  }

  Future<void> _fetchUsers() async {
    final users = await _userService.getUsers();
    setState(() {
      _users = users;
      _dataSource = UserDataSource(
        users: _users,
        onEdit: _showAddEditUserDialog,
        onDelete: _deleteUser,
      );
      _isLoading = false;
    });
  }

  void _navigateToItemsPage() {
    Navigator.pushReplacementNamed(context, '/items');
  }

  void _showAddEditUserDialog([User? user]) {
    showDialog(
      context: context,
      builder: (context) => AddEditUserDialog(
        user: user,
        onUserSaved: _fetchUsers,
      ),
    );
  }

  Future<void> _deleteUser(String email) async {
    await _userService.deleteUser(email);
    _fetchUsers();
  }

  void _onSearch(String query) {
    _dataSource?.filterUsers(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 5)],
              color: Colors.white,
            ),
            child: PaginatedDataTable(
              header: Row(
                children: [
                  Text('User List', style: AppTheme.headline6),
                  Spacer(),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.15,
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearch,
                      decoration: InputDecoration(
                        labelText: 'Search',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: _fetchUsers,
                  ),
                ],
              ),
              headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                  return Colors.blue.withOpacity(0.2);
                },
              ),
              columns: [
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Role')),
                DataColumn(label: Text('Actions')),
              ],
              source: _dataSource!,
              rowsPerPage: _rowsPerPage,
              onRowsPerPageChanged: (value) {
                setState(() {
                  _rowsPerPage = value!;
                });
              },
              availableRowsPerPage: [5, 10, 20, 30],
              columnSpacing: 20,
              horizontalMargin: 20,
              showCheckboxColumn: false,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditUserDialog(),
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddEditUserDialog extends StatefulWidget {
  final User? user;
  final VoidCallback onUserSaved;

  const AddEditUserDialog({Key? key, this.user, required this.onUserSaved}) : super(key: key);

  @override
  _AddEditUserDialogState createState() => _AddEditUserDialogState();
}

class _AddEditUserDialogState extends State<AddEditUserDialog> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // final TextEditingController _roleController = TextEditingController();
  final UserService _userService = UserService();
  bool _isLoading = false;
  String? _selectedRole; // New variable for storing the selected role

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _emailController.text = widget.user!.email;
      _passwordController.text = widget.user!.password;
      _selectedRole = widget.user!.role; // Set the selected role if editing
    }
  }

  Future<void> _handleSave() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text;
      final password = _passwordController.text;

      final user = User(
        email: email,
        password: widget.user?.password ?? password,
        role: _selectedRole ?? widget.user?.role ?? 'employee', // Default to 'employee' if null
        id: widget.user?.id ?? '',
      );

      if (widget.user == null) {
        // Create a new user
        await _userService.createUser(user);
      } else {
        // Update existing user
        await _userService.updateUser(user);
      }

      widget.onUserSaved();
      Navigator.pop(context);
    } catch (e) {
      // Handle error (e.g., show a snackbar or dialog)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save user: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Color(0xFFF8F9FA),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        padding: EdgeInsets.all(16),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.user == null ? 'Add User' : 'Edit User', style: AppTheme.headline6),
              SizedBox(height: 16),
              CustomTextField(controller: _emailController, label: 'Email'),
              SizedBox(height: 16),
              // if (widget.user == null)
              CustomTextField(controller: _passwordController, label: 'Password'),
              SizedBox(height: 16),
              SizedBox(
                width: 400,
                child: DropdownButtonFormField<String>(
                  value: _selectedRole, // Current selected value
                  hint: Text('Role'), // Placeholder
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(),
                    labelText: 'Role',
                  ),
                  items: ['admin', 'employee'] // Dropdown options
                      .map((role) => DropdownMenuItem<String>(
                    value: role,
                    child: Text(role),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value; // Update selected role
                    });
                  },
                ),
              ),

              SizedBox(height: 16),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _handleSave,
                style: AppTheme.elevatedButtonStyle,
                child: Text('Save', style: AppTheme.button),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
