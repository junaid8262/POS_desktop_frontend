import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:namer_app/models/item.dart';
import 'package:namer_app/screens/Items/edit_or_add_item.dart';
import 'package:namer_app/services/items.dart';
import 'package:namer_app/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ItemDataSource extends DataTableSource {
  final List<Item> items;
  final void Function(Item) onEdit;
  final void Function(String) onDelete;
  final BuildContext context;
  final void Function(Item, int) onAddStock;
  final void Function(Item) onSelectItem;
  final void Function(List<Item>)
      onSelectionChanged; // Callback for selection changes
  List<Item> filteredItems;
  Set<Item> selectedItems; // Store selected items

  ItemDataSource({
    required this.items,
    required this.onEdit,
    required this.onDelete,
    required this.onAddStock,
    required this.context,
    required this.onSelectItem,
    required this.onSelectionChanged,
  })  : filteredItems = List.from(items),
        selectedItems = {};

  void filterItems(String query) {
    final lowerQuery = query.toLowerCase();
    filteredItems
      ..clear()
      ..addAll(
          items.where((item) => item.name.toLowerCase().contains(lowerQuery)));
    notifyListeners();
  }

  void sortItems<T>(
      Comparable<T> Function(Item item) getField, bool ascending) {
    filteredItems.sort((a, b) {
      if (!ascending) {
        final Item c = a;
        a = b;
        b = c;
      }
      final Comparable<T> aValue = getField(a);
      final Comparable<T> bValue = getField(b);
      return Comparable.compare(aValue, bValue);
    });
    notifyListeners();
  }

  void _onSelectRow(bool? selected, Item item) {
    if (selected != null && selected) {
      selectedItems.add(item);
    } else {
      selectedItems.remove(item);
    }
    onSelectionChanged(selectedItems.toList());
    notifyListeners();
  }

  @override
  DataRow? getRow(int index) {
    final item = filteredItems[index];
    return DataRow.byIndex(
      index: index,
      selected: selectedItems.contains(item),
      onSelectChanged: (selected) => _onSelectRow(selected, item),
      cells: [
        DataCell(Text(item.name)),
        DataCell(Text(item.brand)),
        DataCell(Text(item.availableQuantity.toString())),
        DataCell(Text(item.nameInUrdu ?? '')),
        DataCell(Text(item.miniUnit ?? '')),
        DataCell(Text(item.packaging ?? '')),
        DataCell(Text(item.purchaseRate.toString())),
        DataCell(Text(item.saleRate.toString())),
        DataCell(Text(item.minStock.toString())),
        DataCell(Text(item.location ?? '')),
        DataCell(SizedBox(
            width: 50,
            height: 50,
            child: Image.network(item.picture != null
                ? '${dotenv.env['BACKEND_URL']!}${item.picture}'
                : ''))),
      ],
    );
  }

  @override
  int get rowCount => filteredItems.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => selectedItems.length;
}

class ItemSelectionDialog extends StatefulWidget {
  final List<Item> items;
  final void Function(List<Item>) onItemsSelected;

  const ItemSelectionDialog({
    Key? key,
    required this.items,
    required this.onItemsSelected,
  }) : super(key: key);

  @override
  _ItemSelectionDialogState createState() => _ItemSelectionDialogState();
}

class _ItemSelectionDialogState extends State<ItemSelectionDialog> {
  ItemDataSource? _dataSource;
  String _searchQuery = '';
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
  List<Item> _selectedItems = [];

  @override
  void initState() {
    super.initState();
    _dataSource = ItemDataSource(
      items: widget.items,
      onEdit: (item) {},
      onDelete: (id) {},
      onAddStock: (item, quantity) {},
      context: context,
      onSelectItem: (item) {},
      onSelectionChanged: (selectedItems) {
        setState(() {
          _selectedItems = selectedItems;
        });
      },
    );
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _dataSource?.filterItems(query);
    });
  }

  void _onSubmitSelection() {
    widget.onItemsSelected(_selectedItems);
    Navigator.pop(context);
  }

  final ItemService _itemService = ItemService();
  void refreshItems() async {
    final items = await _itemService.getItems();
    setState(() {
      _dataSource = ItemDataSource(
        items: items,
        onEdit: (item) {},
        onDelete: (id) {},
        onAddStock: (item, quantity) {},
        context: context,
        onSelectItem: (item) {},
        onSelectionChanged: (selectedItems) {
          setState(() {
            _selectedItems = selectedItems;
          });
        },
      );
    });

  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
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
                SizedBox(
                  width: 5,
                ),
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 40,
                    width: 250,
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AddEditItemDialog(
                              onItemSaved: () {
                               refreshItems();// Pass the new item here
                              },
                            );
                          },
                        );
                      },
                      child: Text('Add Item'),
                    ),
                  ),
                )
              ],
            ),
            Expanded(
              child: Center(
                // Center the table
                child: SingleChildScrollView(
                  child: PaginatedDataTable(
                    columns: [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Brand')),
                      DataColumn(label: Text('Quantity')),
                      DataColumn(label: Text('Name in Urdu')),
                      DataColumn(label: Text('Mini Unit')),
                      DataColumn(label: Text('Packaging')),
                      DataColumn(label: Text('Purchase Rate')),
                      DataColumn(label: Text('Sale Rate')),
                      DataColumn(label: Text('Min Stock')),
                      DataColumn(label: Text('Location')),
                      DataColumn(label: Text('Picture')),
                    ],
                    source: _dataSource!,
                    rowsPerPage: _rowsPerPage,
                    availableRowsPerPage: [5, 10, 20, 30],
                    onRowsPerPageChanged: (value) {
                      setState(() {
                        _rowsPerPage = value!;
                      });
                    },
                    columnSpacing: 20,
                    horizontalMargin: 20,
                    showCheckboxColumn: true,
                  ),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _onSubmitSelection,
              child: Text('Select Items'),
            ),
          ],
        ),
      ),
    );
  }
}
