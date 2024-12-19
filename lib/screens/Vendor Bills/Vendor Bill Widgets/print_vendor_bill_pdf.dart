import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../models/businessInfo.dart';
import '../../../models/vendor.dart';
import '../../../models/vendor_bills.dart';

class VendorBillPdfGenerator {
  static Future<void> generatePdfAndView(VendorBill bill, Vendor vendor, String billType, BusinessDetails? businessDetails) async {
    final pdf = pw.Document();
    DateTime date = DateTime.parse(bill.date);
    String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final isReturnBill = billType == 'Return Bill';
    final billColor = isReturnBill ? PdfColors.redAccent : PdfColors.blueAccent;
    final netImage = await networkImage('${dotenv.env['BACKEND_URL']!}${businessDetails!.companyLogo}');

    const int itemsPerPage = 7; // Limit of items per page
    final totalPages = (bill.items.length / itemsPerPage).ceil(); // Calculate total number of pages

    for (int page = 0; page < totalPages; page++) {
      final itemsForPage = bill.items.skip(page * itemsPerPage).take(itemsPerPage).toList();

      // Add a new page with items for the current page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a5, // Changed to A5 page format
          margin: pw.EdgeInsets.all(10), // Adjust margins for A5
          build: (context) {
            final List<List<String>> tableData = List.generate(itemsForPage.length, (index) {
              final item = itemsForPage[index];
              final total = (item.purchaseRate * item.quantity).toStringAsFixed(2);
              return [
                (index + 1 + page * itemsPerPage).toString(), // Adjust item index for pages
                item.name,
                item.quantity.toString(),
                item.miniUnit.toString(),
                item.purchaseRate.toStringAsFixed(2),
                total,
              ];
            });

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (page == 0) ...[
                  // Only show this section on the first page
                  pw.Container(
                    padding: pw.EdgeInsets.symmetric(vertical: 8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                    ),
                    child: pw.Padding(
                      padding: pw.EdgeInsets.all(8), // Adjust padding for A5
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          businessDetails.companyLogo.isEmpty
                              ? pw.SizedBox(
                            width: 100,
                            height: 70,
                            child: pw.Image(
                              pw.MemoryImage(
                                // Replace this with the path to your placeholder image in your assets
                                File('assets/placeholder.jpg').readAsBytesSync(),
                              ),
                            ),
                          )
                              : pw.SizedBox(
                              width: 100,
                              height: 70,
                              child: pw.Image(netImage)
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(businessDetails.companyName,
                                  style: pw.TextStyle(
                                      fontSize: 22, // Adjusted font size for A5
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.black)),
                              pw.SizedBox(height: 5),
                              pw.Text(businessDetails.companyAddress,
                                  style: pw.TextStyle(fontSize: 10, color: PdfColors.black)),
                              pw.Text(businessDetails.companyPhoneNo,
                                  style: pw.TextStyle(fontSize: 10, color: PdfColors.black)),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                'Invoice',
                                style: pw.TextStyle(
                                  fontSize: 22, // Adjusted font size for A5
                                  fontWeight: pw.FontWeight.bold,
                                  color: billColor,
                                ),
                              ),
                              pw.SizedBox(height: 5),
                              pw.Container(
                                padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                                decoration: pw.BoxDecoration(
                                  color: billColor,
                                  borderRadius: pw.BorderRadius.circular(4),
                                ),
                                child: pw.Text(
                                  "VENDOR " + billType.toUpperCase(),
                                  style: pw.TextStyle(
                                    color: PdfColors.white,
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text('Invoice Details',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Container(
                    padding: pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('Vendor Business Name:',
                                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                                pw.SizedBox(height: 3),
                                pw.Text('${vendor.businessName}',
                                    style: pw.TextStyle(
                                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
                              ],
                            ),
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('Vendor Name:',
                                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                                pw.SizedBox(height: 3),
                                pw.Text('${vendor.name}',
                                    style: pw.TextStyle(
                                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 5),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('Vendor Address:',
                                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                                pw.SizedBox(height: 3),
                                pw.Text('${vendor.address}',
                                    style: pw.TextStyle(
                                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
                              ],
                            ),
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('Vendor Phone:',
                                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                                pw.SizedBox(height: 3),
                                pw.Text('${vendor.phoneNumber}',
                                    style: pw.TextStyle(
                                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 5),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('Purchase Date:',
                                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                                pw.SizedBox(height: 3),
                                pw.Text(formattedDate,
                                    style: pw.TextStyle(
                                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),
                ],
                // Items Table with pagination logic
                pw.Text('Items',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                pw.Table.fromTextArray(
                  headers: ['#', 'Product Name', 'Qty', 'Unit', 'Purchase Price', 'Total'],
                  data: tableData,
                  headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.white),
                  headerDecoration: pw.BoxDecoration(
                    color: PdfColors.lightBlue,
                  ),
                  cellStyle: pw.TextStyle(fontSize: 10), // Adjusted for A5
                  cellHeight: 20,
                  columnWidths: {
                    0: pw.FlexColumnWidth(0.5),
                    1: pw.FlexColumnWidth(2),
                    2: pw.FlexColumnWidth(1),
                    3: pw.FlexColumnWidth(1),
                    4: pw.FlexColumnWidth(1.5),
                    5: pw.FlexColumnWidth(1.5),
                  },
                  border: pw.TableBorder.all(color: PdfColors.grey),
                ),
                pw.SizedBox(height: 10),
                // Continuation for multiple pages
                if (page != totalPages - 1)
                  pw.Text('Page ${page + 1} of $totalPages', style: pw.TextStyle(fontSize: 10)),
                // Only on the last page
                if (page == totalPages - 1) ...[
                  pw.SizedBox(height: 10),
                  pw.Container(
                    padding: pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Description:',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            )),
                        pw.SizedBox(height: 5),
                        pw.Text(
                            bill.description.trim().isEmpty ? 'N/A' : bill.description,
                            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  // Totals Section with Previous Balance and Credit Amount
                  pw.Container(
                    padding: pw.EdgeInsets.all(6), // Reduced padding
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: pw.BorderRadius.circular(5), // Reduced border radius
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Payment Details',
                          style: pw.TextStyle(
                            fontSize: 12, // Reduced font size
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
                          ),
                        ),
                        pw.SizedBox(height: 4), // Reduced spacing
                        pw.Container(
                          padding: pw.EdgeInsets.all(4), // Reduced padding
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey200,
                            borderRadius: pw.BorderRadius.circular(4), // Reduced border radius
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    'Total Amount:',
                                    style: pw.TextStyle(
                                      fontSize: 12,
                                      fontWeight: pw.FontWeight.normal,
                                      color: PdfColors.grey600,
                                    ),
                                  ),
                                  pw.Text(
                                    'Rs ${bill.totalAmount.toStringAsFixed(2)}',
                                    style: pw.TextStyle(
                                      fontSize: 12,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.black,
                                    ),
                                  ),
                                ],
                              ),
                              pw.SizedBox(height: 3), // Reduced spacing
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    'Credit Amount:',
                                    style: pw.TextStyle(
                                      fontSize: 10, // Reduced font size
                                      fontWeight: pw.FontWeight.normal,
                                      color: PdfColors.grey600,
                                    ),
                                  ),
                                  pw.Text(
                                    'Rs ${bill.amountGiven.toStringAsFixed(2)}',
                                    style: pw.TextStyle(
                                      fontSize: 10, // Reduced font size
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 6), // Reduced spacing
                        pw.Text(
                          'Total Outstanding:',
                          style: pw.TextStyle(
                            fontSize: 10, // Reduced font size
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
                          ),
                        ),
                        pw.Text(
                          'Rs ${(bill.totalAmount - bill.amountGiven).toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 12, // Reduced font size
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Signature: ____________________',
                          style: pw.TextStyle(fontSize: 12)),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                              'Sub Total: Rs ${(bill.totalAmount - bill.discount).toStringAsFixed(2)}',
                              style: pw.TextStyle(fontSize: 12)),
                          pw.Text('Discount: Rs ${bill.discount.toStringAsFixed(2)}',
                              style: pw.TextStyle(fontSize: 12)),
                          pw.Text('Total: Rs ${bill.totalAmount.toStringAsFixed(2)}',
                              style: pw.TextStyle(
                                  fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ]
              ],
            );
          },
        ),
      );
    }

    // Save the PDF document
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/vendor_bill_invoice_${bill.id}.pdf');
    await file.writeAsBytes(await pdf.save());

    // Open the PDF document in the viewer
    OpenFile.open(file.path);
  }
}
