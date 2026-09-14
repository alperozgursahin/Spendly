import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/app_formatting.dart';
import '../../../core/app_strings.dart';
import '../../../core/locale_provider.dart';
import '../../transactions/transaction_model.dart';

class PdfExportService {
  static Future<void> generateAndShareMonthlyReport(
    List<TransactionModel> transactions,
    DateTime month, {
    AppLanguage language = fallbackAppLanguage,
    String currencySymbol = '\u20ba',
    double Function(double baseAmount)? displayAmount,
  }) async {
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
    );

    double totalIncome = 0;
    double totalExpense = 0;

    final convert = displayAmount ?? (amount) => amount;
    for (var t in transactions) {
      if (t.type == 'income') {
        totalIncome += convert(t.baseAmount);
      } else {
        totalExpense += convert(t.baseAmount);
      }
    }

    String formatCurrency(num value) =>
        AppFormat.amountWithSymbol(value, currencySymbol, language);
    final monthYear = AppFormat.monthYear(month, language);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              AppStrings.of(
                'pdf_title',
                language,
              ).replaceFirst('%s', monthYear),
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "${AppStrings.of('pdf_total_income', language)}: "
                "${formatCurrency(totalIncome)}",
                style: const pw.TextStyle(
                  color: PdfColors.green700,
                  fontSize: 16,
                ),
              ),
              pw.Text(
                "${AppStrings.of('pdf_total_expense', language)}: "
                "${formatCurrency(totalExpense)}",
                style: const pw.TextStyle(
                  color: PdfColors.red700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            "${AppStrings.of('pdf_net_balance', language)}: "
            "${formatCurrency(totalIncome - totalExpense)}",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
          ),
          pw.SizedBox(height: 30),
          pw.Text(
            AppStrings.of('pdf_transaction_details', language),
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          if (transactions.isEmpty)
            pw.Text(
              AppStrings.of('pdf_no_transactions', language),
              style: const pw.TextStyle(color: PdfColors.grey700),
            )
          else
            pw.TableHelper.fromTextArray(
              context: context,
              headers: [
                AppStrings.of('common_date', language),
                AppStrings.of('common_category', language),
                AppStrings.of('pdf_header_type', language),
                AppStrings.of('dashboard_amount_hint', language),
              ],
              data: transactions.map((t) {
                return [
                  AppFormat.shortDate(t.date, language),
                  categoryLabelForLanguage(language, t.category),
                  (t.type == 'income'
                          ? AppStrings.of('common_income', language)
                          : AppStrings.of('common_expense', language))
                      .toUpperCase(),
                  formatCurrency(convert(t.baseAmount)),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey800,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
              ),
            ),
        ],
      ),
    );

    // Filenames stay ASCII-safe and sortable regardless of report language.
    final safeMonthYear =
        '${month.year}-${month.month.toString().padLeft(2, '0')}';
    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Splixa_Report_$safeMonthYear.pdf',
    );
  }

  static Future<void> generateAndShareCsv(
    List<TransactionModel> transactions, {
    AppLanguage language = fallbackAppLanguage,
  }) async {
    final rows = <List<dynamic>>[
      [
        AppStrings.of('common_date', language),
        AppStrings.of('common_category', language),
        AppStrings.of('pdf_header_type', language),
        'original_amount',
        'currency_code',
        'base_amount',
        'base_currency_code',
        'exchange_rate',
        'rate_source',
        'rate_locked_at',
      ],
      ...transactions.map(
        (transaction) => [
          '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}-${transaction.date.day.toString().padLeft(2, '0')}',
          categoryLabelForLanguage(language, transaction.category),
          transaction.type,
          transaction.originalAmount,
          transaction.currencyCode,
          transaction.baseAmount,
          transaction.baseCurrencyCode,
          transaction.exchangeRate,
          transaction.rateSource,
          transaction.rateLockedAt.toIso8601String(),
        ],
      ),
    ];
    final contents = Csv().encode(rows);
    final bytes = utf8.encode('\uFEFF$contents');
    final now = DateTime.now();
    final filename =
        'Splixa_Export_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.csv';
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'text/csv', name: filename)],
        fileNameOverrides: [filename],
      ),
    );
  }
}
