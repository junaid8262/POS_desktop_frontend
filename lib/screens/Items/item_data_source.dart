import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:namer_app/models/item.dart';

import '../../models/user.dart';
import '../../services/request.dart';
import 'item_action_datacell_request_logic.dart';
import 'item_management.dart';


class ItemDataSource extends DataTableSource {
  final List<Item> items;
  final void Function(Item) onEdit;
  final void Function(String) onDelete;
  final BuildContext context;
  final void Function(Item, int) onAddStock;
  List<Item> filteredItems;
  final User? user;

  ItemDataSource({
    required this.items,
    required this.onEdit,
    required this.onDelete,
    required this.onAddStock,
    required this.context,
    required this.user,
  }) : filteredItems = List.from(items);
  final RequestService _requestService = RequestService();

  void filterItems(String query) {
    final lowerQuery = query.toLowerCase();
    filteredItems
      ..clear()
      ..addAll(items.where((item) => item.name.toLowerCase().contains(lowerQuery)));
    notifyListeners();
  }

  void sortItems<T>(Comparable<T> Function(Item item) getField, bool ascending) {
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

  @override
  DataRow? getRow(int index) {
    final item = filteredItems[index];
    final bool isLowStock = item.availableQuantity <= item.minStock;
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(InkWell(
          onTap: (){
            _showFullImage(item.picture ?? '');
          },
          child: SizedBox(
              width: 50,
              height: 50,
              child: Image.network(item.picture != null?'${dotenv.env['BACKEND_URL']!}${item.picture}': '')),
        )),
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
        DataCell(ItemActionDataCell(
          futureRequest: _requestService.getRequestByEmployeeAndDocument(user!.id, 'Item', item.id),
          employeeId: user!.id,
          documentType: 'Item',
          documentId: item.id,
          userRole: user!.role,
          onEdit: (item) => onEdit(item),
          onDelete: (itemId) => onDelete(itemId),
          onAddStock: (item) => _showAddStockDialog(item),
          item: item,
        )),
      ],
      onSelectChanged: (selected) {
        // Optional: Add any onSelect behavior
      },
      color: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.hovered)) {
            return Colors.blue.withOpacity(0.1);
          }
          return isLowStock ? Colors.red.withOpacity(0.2) : null;
        },
      ),
    );
  }
  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(

            padding: EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    height: 300,
                    width: 600,
                    child: Image.network(imageUrl != null?'${dotenv.env['BACKEND_URL']!}${imageUrl}': '')),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  @override
  int get rowCount => filteredItems.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;

  void _showAddStockDialog(Item item) {
    showDialog(
      context: context,
      builder: (context) => AddStockDialog(
        item: item,
        onStockAdded: (quantity) => onAddStock(item, quantity),
      ),
    );
  }
}

