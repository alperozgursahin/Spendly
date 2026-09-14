import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as image_lib;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/friendly_error.dart';

final receiptServiceProvider = Provider<ReceiptService>((ref) {
  return ReceiptService(Supabase.instance.client);
});

final expenseReceiptsProvider =
    FutureProvider.family<List<ReceiptAttachment>, String>((
      ref,
      expenseId,
    ) async {
      final rows = await Supabase.instance.client
          .from('expense_attachments')
          .select('id, storage_path, uploaded_by, created_at')
          .eq('expense_id', expenseId)
          .order('created_at');
      return rows
          .map(
            (row) => ReceiptAttachment(
              id: row['id'] as String,
              storagePath: row['storage_path'] as String,
              uploadedBy: row['uploaded_by'] as String,
              createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
            ),
          )
          .toList(growable: false);
    });

class ReceiptScanResult {
  const ReceiptScanResult({
    required this.image,
    required this.rawText,
    required this.suggestedDescription,
    required this.suggestedAmount,
    required this.confidence,
  });

  final XFile image;
  final String rawText;
  final String? suggestedDescription;
  final double? suggestedAmount;
  final double confidence;
}

class ReceiptAttachment {
  const ReceiptAttachment({
    required this.id,
    required this.storagePath,
    required this.uploadedBy,
    required this.createdAt,
  });
  final String id;
  final String storagePath;
  final String uploadedBy;
  final DateTime createdAt;
}

class ReceiptService {
  ReceiptService(this._client);
  final SupabaseClient _client;
  final ImagePicker _picker = ImagePicker();

  bool get canScan =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<ReceiptScanResult?> pickAndScan({
    ImageSource source = ImageSource.camera,
  }) async {
    if (!canScan) throw const FriendlyException('pro_ocr_mobile_only');
    final selected = await _picker.pickImage(
      source: source,
      maxWidth: 2200,
      imageQuality: 90,
      requestFullMetadata: false,
    );
    if (selected == null) return null;

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognized = await recognizer.processImage(
        InputImage.fromFilePath(selected.path),
      );
      final parsed = ReceiptTextParser.parse(recognized.text);
      return ReceiptScanResult(
        image: selected,
        rawText: recognized.text,
        suggestedDescription: parsed.description,
        suggestedAmount: parsed.amount,
        confidence: parsed.confidence,
      );
    } finally {
      await recognizer.close();
    }
  }

  Future<ReceiptAttachment> uploadForExpense({
    required XFile image,
    required String expenseId,
  }) {
    return _upload(image: image, expenseId: expenseId);
  }

  Future<ReceiptAttachment> uploadForTransaction({
    required XFile image,
    required String transactionId,
  }) {
    return _upload(image: image, transactionId: transactionId);
  }

  Future<ReceiptAttachment> _upload({
    required XFile image,
    String? expenseId,
    String? transactionId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const FriendlyException('error_not_authenticated');
    }
    final sourceBytes = await image.readAsBytes();
    if (sourceBytes.isEmpty) throw const FriendlyException('media_image_empty');
    final decoded = image_lib.decodeImage(sourceBytes);
    if (decoded == null) {
      throw const FriendlyException('pro_receipt_invalid_image');
    }
    final resized = decoded.width > 1800
        ? image_lib.copyResize(decoded, width: 1800)
        : decoded;
    final Uint8List bytes = Uint8List.fromList(
      image_lib.encodeJpg(resized, quality: 82),
    );
    if (bytes.length > 5 * 1024 * 1024) {
      throw const FriendlyException('media_image_too_large');
    }

    final random = Random.secure().nextInt(1 << 32).toRadixString(16);
    final path = '$userId/${DateTime.now().microsecondsSinceEpoch}_$random.jpg';
    await _client.storage
        .from('receipt-attachments')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            cacheControl: '3600',
            upsert: false,
          ),
        );
    try {
      final row = await _client
          .from('expense_attachments')
          .insert({
            'expense_id': expenseId,
            'transaction_id': transactionId,
            'uploaded_by': userId,
            'storage_path': path,
            'mime_type': 'image/jpeg',
            'byte_size': bytes.length,
          })
          .select('id, storage_path, created_at')
          .single();
      return ReceiptAttachment(
        id: row['id'] as String,
        storagePath: row['storage_path'] as String,
        uploadedBy: userId,
        createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
      );
    } catch (_) {
      await _client.storage.from('receipt-attachments').remove([path]);
      rethrow;
    }
  }

  Future<String> createSignedUrl(String storagePath) {
    return _client.storage
        .from('receipt-attachments')
        .createSignedUrl(storagePath, 300);
  }

  Future<void> deleteAttachment(ReceiptAttachment attachment) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || attachment.uploadedBy != userId) {
      throw const FriendlyException('error_not_authorized');
    }
    await _client.from('expense_attachments').delete().eq('id', attachment.id);
    try {
      await _client.storage.from('receipt-attachments').remove([
        attachment.storagePath,
      ]);
    } catch (_) {
      // The database trigger queued this path for the scheduled cleanup job.
    }
  }
}

/// Deterministic, offline receipt parsing. OCR output is suggestion-only: the
/// caller always leaves the editable form visible and never writes a ledger
/// row without explicit confirmation.
class ReceiptTextParser {
  const ReceiptTextParser._();

  static ReceiptParsingResult parse(String text) {
    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final totalWords = RegExp(
      r'(grand\s*total|total|toplam|summe|totale|montant|totaal|итого|total\s+a\s+pagar)',
      caseSensitive: false,
    );
    final amountPattern = RegExp(
      r'(?<!\d)(\d{1,3}(?:[ .]\d{3})*[,.]\d{2}|\d+[,.]\d{2})(?!\d)',
    );
    final candidates = <({double value, bool totalLine, int index})>[];
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      for (final match in amountPattern.allMatches(line)) {
        final value = _parseLocalizedAmount(match.group(1)!);
        if (value != null && value > 0 && value < 1000000000) {
          candidates.add((
            value: value,
            totalLine: totalWords.hasMatch(line),
            index: index,
          ));
        }
      }
    }
    candidates.sort((a, b) {
      if (a.totalLine != b.totalLine) return a.totalLine ? -1 : 1;
      return b.index.compareTo(a.index);
    });
    final best = candidates.isEmpty ? null : candidates.first;
    final description = lines.firstWhere(
      (line) =>
          line.length >= 2 &&
          line.length <= 60 &&
          RegExp(r'[A-Za-zÀ-ž]').hasMatch(line) &&
          !totalWords.hasMatch(line) &&
          !RegExp(r'^\d').hasMatch(line),
      orElse: () => '',
    );
    return ReceiptParsingResult(
      amount: best?.value,
      description: description.isEmpty ? null : description,
      confidence: best == null ? 0 : (best.totalLine ? .9 : .55),
    );
  }

  static double? _parseLocalizedAmount(String value) {
    final compact = value.replaceAll(' ', '');
    final lastComma = compact.lastIndexOf(',');
    final lastDot = compact.lastIndexOf('.');
    final decimalIndex = max(lastComma, lastDot);
    if (decimalIndex < 0) return double.tryParse(compact);
    final integer = compact
        .substring(0, decimalIndex)
        .replaceAll(RegExp(r'[,.]'), '');
    final decimal = compact.substring(decimalIndex + 1);
    return double.tryParse('$integer.$decimal');
  }
}

class ReceiptParsingResult {
  const ReceiptParsingResult({
    this.amount,
    this.description,
    required this.confidence,
  });
  final double? amount;
  final String? description;
  final double confidence;
}
