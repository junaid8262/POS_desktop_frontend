import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:namer_app/models/item.dart';
import 'package:namer_app/services/items.dart';
import 'package:namer_app/theme/theme.dart';
import 'package:namer_app/components/input_field.dart';
import 'dart:io';
import 'package:file_selector/file_selector.dart';


class AddEditItemDialog extends StatefulWidget {
  final Item? item;
  final VoidCallback onItemSaved;

  const AddEditItemDialog({Key? key, this.item, required this.onItemSaved}) : super(key: key);

  @override
  _AddEditItemDialogState createState() => _AddEditItemDialogState();
}

class _AddEditItemDialogState extends State<AddEditItemDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _nameInUrduController = TextEditingController();
  final TextEditingController _miniUnitController = TextEditingController();
  final TextEditingController _packagingController = TextEditingController();
  final TextEditingController _purchaseRateController = TextEditingController();
  final TextEditingController _saleRateController = TextEditingController();
  final TextEditingController _minStockController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final ItemService _itemService = ItemService();
  bool _isLoading = false;
  File? _image;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _brandController.text = widget.item!.brand;
      _quantityController.text = widget.item!.availableQuantity.toString();
      _nameInUrduController.text = widget.item!.nameInUrdu!;
      _miniUnitController.text = widget.item!.miniUnit!;
      _packagingController.text = widget.item!.packaging!;
      _purchaseRateController.text = widget.item!.purchaseRate.toString();
      _saleRateController.text = widget.item!.saleRate.toString();
      _minStockController.text = widget.item!.minStock.toString();
      _locationController.text = widget.item!.location!;
    }
  }

  Future<void> _pickImage() async {
    try {
      final typeGroup = XTypeGroup(
        label: 'images',
        extensions: <String>['jpg', 'png', 'jpeg'],
      );
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file != null) {
        setState(() {
          _image = File(file.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _handleSave() async {
    setState(() {
      _isLoading = true;
    });

    final name = _nameController.text.trim().isEmpty ? 'N/A' : _nameController.text;
    final brand = _brandController.text.trim().isEmpty ? 'N/A' : _brandController.text;
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final nameInUrdu = _nameInUrduController.text.trim().isEmpty ? 'N/A' : _nameInUrduController.text;
    final miniUnit = _miniUnitController.text.trim().isEmpty ? 'N/A' : _miniUnitController.text;
    final packaging = _packagingController.text.trim().isEmpty ? 'N/A' : _packagingController.text;
    final purchaseRate = double.tryParse(_purchaseRateController.text) ?? 0;
    final saleRate = double.tryParse(_saleRateController.text) ?? 0;
    final minStock = int.tryParse(_minStockController.text) ?? 0;
    final location = _locationController.text.trim().isEmpty ? 'N/A' : _locationController.text;
    String pictureUrl = widget.item?.picture ?? '';

    if (_image != null) {
      // If the user has selected an image, upload it
      pictureUrl = await _itemService.uploadImage(_image!);
    } else {
      // If _image is null, upload a placeholder image from assets
      pictureUrl = await _itemService.uploadImage(File('assets/placeholder.jpg'));
    }

    if (widget.item == null) {
      await _itemService.addItem(Item(
        id: '',
        name: name,
        brand: brand,
        availableQuantity: quantity,
        nameInUrdu: nameInUrdu,
        miniUnit: miniUnit,
        packaging: packaging,
        purchaseRate: purchaseRate,
        saleRate: saleRate,
        minStock: minStock,
        addedEditDate: DateTime.now(),
        location: location,
        picture: pictureUrl,
      ));
    } else {
      await _itemService.updateItem(widget.item!.id, Item(
        id: widget.item!.id,
        name: name,
        brand: brand,
        availableQuantity: quantity,
        nameInUrdu: nameInUrdu,
        miniUnit: miniUnit,
        packaging: packaging,
        purchaseRate: purchaseRate,
        saleRate: saleRate,
        minStock: minStock,
        addedEditDate: widget.item!.addedEditDate,
        location: location,
        picture: pictureUrl,
      ));
    }

    setState(() {
      _isLoading = false;
    });

    widget.onItemSaved();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Check if any required field is empty
    bool isFormValid() {
      return _nameController.text.isNotEmpty &&
          _quantityController.text.isNotEmpty &&
          _purchaseRateController.text.isNotEmpty &&
          _saleRateController.text.isNotEmpty &&
          _locationController.text.isNotEmpty;
    }

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
              Text(widget.item == null ? 'Add Item' : 'Edit Item', style: AppTheme.headline6),
              SizedBox(height: 16),
              CustomTextField(
                controller: _nameController,
                label: 'Item Name*',
                hintText: 'Item Name',
              ),
              SizedBox(height: 16),
              CustomTextField(
                controller: _brandController,
                label: 'Brand',
                hintText: "Samsung, Apple , Lays",
              ),
              SizedBox(height: 16),
              CustomTextField(
                controller: _quantityController,
                label: 'Available Quantity*',
                keyboardType: TextInputType.number,
                hintText: "0",
              ),
              SizedBox(height: 16),
              CustomTextField(
                controller: _nameInUrduController,
                label: 'Name in Urdu',
                hintText: "سیمسنگ, ایپل, لیز",
              ),
              SizedBox(height: 16),
              CustomTextField(
                controller: _miniUnitController,
                label: 'Mini Unit',
              ),
              SizedBox(height: 16),
              CustomTextField(
                controller: _packagingController,
                label: 'Packaging',
              ),
              SizedBox(height: 16),
              CustomTextField(
                controller: _purchaseRateController,
                label: 'Purchase Rate*',
                keyboardType: TextInputType.number,
                hintText: '300',
              ),
              SizedBox(height: 16),
              CustomTextField(
                controller: _saleRateController,
                label: 'Sale Rate*',
                keyboardType: TextInputType.number,
                hintText: '450',
              ),
              SizedBox(height: 16),
              CustomTextField(
                controller: _minStockController,
                label: 'Min Stock',
                keyboardType: TextInputType.number,
                hintText: '1',
              ),
              SizedBox(height: 16),
              CustomTextField(
                controller: _locationController,
                label: 'Location*',
                hintText: "LHR, ISB, FSD",
              ),
              SizedBox(height: 16),
              widget.item?.picture != null && _image == null
                  ? SizedBox(
                width: 300,
                height: 200,
                child: Image.network('${dotenv.env['BACKEND_URL']!}${widget.item!.picture}'),
              )
                  : _image != null
                  ? SizedBox(
                width: 300,
                height: 200,
                child: Image.file(
                  _image!,
                  fit: BoxFit.cover,
                ),
              )
                  : SizedBox(),
              _image == null
                  ? TextButton.icon(
                icon: Icon(Icons.image),
                label: Text('Pick Image'),
                onPressed: _pickImage,
              )
                  : TextButton.icon(
                icon: Icon(Icons.image),
                label: Text('Change Image'),
                onPressed: _pickImage,
              ),
              SizedBox(height: 16),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: isFormValid() ? _handleSave : null, // Disable button if form is not valid
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