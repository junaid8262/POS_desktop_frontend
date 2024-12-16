import 'package:flutter/material.dart';
import 'package:namer_app/models/item.dart';
import 'package:namer_app/services/items.dart';
import 'package:namer_app/theme/theme.dart';
import 'package:provider/provider.dart';

import '../../components/export_csv.dart';
import '../../components/user_provider.dart';
import '../../models/user.dart';
import 'edit_or_add_item.dart';
import 'item_data_source.dart';

class ItemsPage extends StatefulWidget {
  @override
  _ItemsPageState createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  final ItemService _itemService = ItemService();
  List<Item> _items = [];
  ItemDataSource? _dataSource;
  bool _isLoading = true;
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
  String _searchQuery = '';
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  User? _user;

  @override
  void initState() {
    super.initState();
    _fetchRole();
    _fetchItems();
  }

  Future<void> _fetchRole() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _user = userProvider.user;
    print('provider check ${_user!.role}');
  }

  Future<void> _confirmDeleteItem(String id) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevents closing the dialog by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete this vendor bill?',style: TextStyle(fontSize: 18),),
                Text(
                  'Deleting this item may corrupt related data in customer/vendor bills and affect app functionality.',
                  style: TextStyle(fontSize: 10, color: Colors.red),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.redAccent),
              ),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await _deleteItem(id); // Call the delete function if confirmed
              },
            ),
          ],
        );
      },
    );
  }


  Future<void> _fetchItems() async {
    final items = await _itemService.getItems();
    setState(() {
      _items = items;
      _dataSource = ItemDataSource(
        items: _items,
        onEdit: _showAddEditItemDialog,
        onDelete: _confirmDeleteItem,
        onAddStock: _addStock,
        context: context,
        user: _user
      );
      _isLoading = false;
    });
  }

  void _showAddEditItemDialog([Item? item]) {
    showDialog(
      context: context,
      builder: (context) => AddEditItemDialog(
        item: item,
        onItemSaved: _fetchItems,
      ),
    );
  }

  Future<void> _deleteItem(String id) async {
    await _itemService.deleteItem(id);
    _fetchItems();
  }

  Future<void> _addStock(Item item, int quantity) async {
    final updatedItem = item.copyWith(availableQuantity: item.availableQuantity + quantity);
    await _itemService.updateItem(item.id, updatedItem);
    _fetchItems();
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _dataSource?.filterItems(query);
    });
  }

  void _onSort<T>(Comparable<T> Function(Item item) getField, int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _dataSource?.sortItems(getField, ascending);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _dataSource == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Center(

          child:
          Container(
            width: MediaQuery.of(context).size.width * 0.9,
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,

            ),
            // width: double.infinity,
            child: PaginatedDataTable(
              header: Row(
                children: [
                  Text('Items', style: AppTheme.headline6),
                  Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        CsvExporter.exportItems( _items,context,); // Call the export utility
                        //_showAddDebitDialog(false); // Call your function to add a debit bill
                      },
                      child: Text('Export'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue, // Set button color if needed
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.15,
                    child: TextField(
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
                    onPressed: _fetchItems,
                  ),
                ],
              ),
              headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                  return Colors.blue.withOpacity(0.2);
                },
              ),
              columns: [

                DataColumn(
                  label: Text('Picture'),
                  onSort: (columnIndex, ascending) => _onSort((item) => item.picture ?? '', columnIndex, ascending),
                ),
                DataColumn(
                  label: Text('Name'),
                  onSort: (columnIndex, ascending) => _onSort((item) => item.name, columnIndex, ascending),
                ),
                DataColumn(
                  label: Text('Brand'),
                  onSort: (columnIndex, ascending) => _onSort((item) => item.brand, columnIndex, ascending),
                ),
                DataColumn(
                  label: Text('Quantity'),
                  onSort: (columnIndex, ascending) => _onSort((item) => item.availableQuantity, columnIndex, ascending),
                ),
                DataColumn(
                  label: Text('Name in Urdu'),
                  onSort: (columnIndex, ascending) => _onSort((item) => item.nameInUrdu ?? '', columnIndex, ascending),
                ),
                DataColumn(
                  label: Text('Mini Unit'),
                  onSort: (columnIndex, ascending) => _onSort((item) => item.miniUnit ?? '', columnIndex, ascending),
                ),
                DataColumn(
                  label: Text('Packaging'),
                  onSort: (columnIndex, ascending) => _onSort((item) => item.packaging ?? '', columnIndex, ascending),
                ),
                DataColumn(
                  label: Text('Purchase Rate'),
                  onSort: (columnIndex, ascending) => _onSort((item) => item.purchaseRate, columnIndex, ascending),
                ),
                DataColumn(
                  label: Text('Sale Rate'),
                  onSort: (columnIndex, ascending) => _onSort((item) => item.saleRate, columnIndex, ascending),
                ),
                DataColumn(
                  label: Text('Min Stock'),
                  onSort: (columnIndex, ascending) => _onSort((item) => item.minStock, columnIndex, ascending),
                ),
                DataColumn(
                  label: Text('Location'),
                  onSort: (columnIndex, ascending) => _onSort((item) => item.location ?? '', columnIndex, ascending),
                ),

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
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditItemDialog(),
        child: Icon(Icons.add),
      ),
    );
  }
}



class AddStockDialog extends StatefulWidget {
  final Item item;
  final void Function(int) onStockAdded;

  const AddStockDialog({required this.item, required this.onStockAdded, Key? key}) : super(key: key);

  @override
  _AddStockDialogState createState() => _AddStockDialogState();
}

class _AddStockDialogState extends State<AddStockDialog> {
  final TextEditingController _quantityController = TextEditingController();

  void _handleAddStock() {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    widget.onStockAdded(quantity);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Stock to ${widget.item.name}'),
      content: TextField(
        controller: _quantityController,
        decoration: InputDecoration(labelText: 'Quantity'),
        keyboardType: TextInputType.number,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _handleAddStock,
          child: Text('Add Stock'),
        ),
      ],
    );
  }
}

