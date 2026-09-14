import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/analytics_service.dart';
import '../../core/app_strings.dart';
import '../../core/friendly_error.dart';
import '../../core/splixa_loading.dart';
import 'financial_models.dart';
import 'group_provider.dart';
import 'group_model.dart';
import '../profile/currency_provider.dart';
import '../profile/currency_selector.dart';
import '../profile/exchange_rate_provider.dart';
import '../subscriptions/premium_provider.dart';
import '../subscriptions/pro_access.dart';
import '../subscriptions/receipt_service.dart';

class AddExpenseSheet extends ConsumerStatefulWidget {
  final String groupId;
  final String currentUserId;

  const AddExpenseSheet({
    super.key,
    required this.groupId,
    required this.currentUserId,
  });

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  final Map<String, TextEditingController> _exactControllers = {};
  final Map<String, double> _percentageValues = {};
  String? _percentageAutoUserId;
  String? _exactAutoUserId;

  String _splitType = 'equal'; // 'equal', 'percentage', 'exact'
  Set<String> _selectedUsers = {};
  String? _selectedCurrency;
  XFile? _receiptImage;
  double? _manualExchangeRate;
  bool _isScanning = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_recalculateSplit);
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    for (final controller in _exactControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _recalculateSplit() {
    setState(
      () {},
    ); // Trigger rebuild to show calculated values (mostly for 'equal')

    if (_splitType == 'exact') {
      _syncExactSplitValues(_totalAmount);
    }

    if (_splitType == 'percentage') {
      _syncPercentageAutoFill();
    }
  }

  double get _totalAmount => _parseValue(_amountController.text) ?? 0.0;

  TextEditingController _exactControllerFor(String userId) {
    return _exactControllers.putIfAbsent(userId, () => TextEditingController());
  }

  void _removeSelectedUserValue(String userId) {
    _percentageValues.remove(userId);
    if (_percentageAutoUserId == userId) {
      _percentageAutoUserId = null;
    }
    final controller = _exactControllers.remove(userId);
    if (_exactAutoUserId == userId) {
      _exactAutoUserId = null;
    }
    controller?.dispose();
  }

  double? _parseValue(String text) {
    final normalized = text.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  void _clearModeSpecificValues() {
    _percentageValues.clear();
    _percentageAutoUserId = null;
    _exactAutoUserId = null;
    for (final controller in _exactControllers.values) {
      controller.dispose();
    }
    _exactControllers.clear();
  }

  void _syncPercentageAutoFill() {
    if (_splitType != 'percentage' || _selectedUsers.isEmpty) return;

    final selectedUserIds = _selectedUsers.toList();
    if (_percentageAutoUserId != null &&
        !selectedUserIds.contains(_percentageAutoUserId)) {
      _percentageAutoUserId = null;
    }

    final missingUsers = selectedUserIds
        .where((userId) => !_percentageValues.containsKey(userId))
        .toList();

    if (_percentageAutoUserId == null && missingUsers.length == 1) {
      _percentageAutoUserId = missingUsers.first;
    }

    final autoUserId = _percentageAutoUserId;
    if (autoUserId == null || !selectedUserIds.contains(autoUserId)) return;

    final manualTotal = selectedUserIds
        .where((userId) => userId != autoUserId)
        .fold<double>(
          0.0,
          (sum, userId) => sum + (_percentageValues[userId] ?? 0.0),
        );

    final remainder = double.parse((100.0 - manualTotal).toStringAsFixed(2));
    if (remainder < 0) return;

    _percentageValues[autoUserId] = remainder;
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(groupMembersProvider(widget.groupId));
    final profileCurrency = ref.watch(currencyProvider);
    final currency = _selectedCurrency ?? profileCurrency;
    final isPremium = ref.watch(premiumProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr(ref, 'groups_add_expense'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isScanning ? null : _scanReceipt,
            icon: _isScanning
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.document_scanner_rounded),
            label: Text(
              _receiptImage == null
                  ? '${tr(ref, 'groups_scan_receipt')} ✨${isPremium ? '' : ' · Pro'}'
                  : tr(ref, 'pro_receipt_ready'),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            decoration: InputDecoration(
              labelText: tr(ref, 'groups_expense_desc_label'),
              prefixIcon: const Icon(Icons.description),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: '${tr(ref, 'groups_total_amount_label')} ($currency)',
              prefixText: '$currency ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          CurrencySelector(
            value: currency,
            labelText: tr(ref, 'common_currency'),
            customRateUnlocked: isPremium,
            customRateTooltip:
                '${tr(ref, 'groups_custom_exchange_rate')}${isPremium ? '' : ' · Pro'}',
            onCustomRatePressed: () =>
                _handleProFeature(feature: ProFeature.customExchangeRate),
            onChanged: (value) {
              setState(() {
                _selectedCurrency = value;
                _manualExchangeRate = null;
              });
            },
          ),
          const SizedBox(height: 24),

          // Segmented Control for Split Type
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'equal',
                label: Text(tr(ref, 'groups_split_equal')),
              ),
              ButtonSegment(
                value: 'percentage',
                label: Text(tr(ref, 'groups_split_percentage')),
              ),
              ButtonSegment(
                value: 'exact',
                label: Text('${tr(ref, 'groups_split_exact')} ($currency)'),
              ),
            ],
            selected: {_splitType},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _splitType = newSelection.first;
                // Reset custom values when switching mode
                _clearModeSpecificValues();
              });
            },
          ),

          const SizedBox(height: 24),
          Text(
            tr(ref, 'groups_split_for_whom'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: membersAsync.when(
              data: (members) {
                // Initialize selected users if empty
                if (_selectedUsers.isEmpty && members.isNotEmpty) {
                  _selectedUsers = members.map((m) => m.userId).toSet();
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final isSelected = _selectedUsers.contains(member.userId);
                    final isMe = member.userId == widget.currentUserId;

                    return _buildMemberTile(member, isSelected, isMe, currency);
                  },
                );
              },
              loading: () => const SplixaSkeletonView(
                type: SplixaSkeletonType.list,
                itemCount: 4,
                padding: EdgeInsets.symmetric(vertical: 8),
              ),
              error: (e, st) => Center(child: Text(friendlyErrorMessage(e))),
            ),
          ),

          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitExpense,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    tr(ref, 'common_save'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _handleProFeature({required ProFeature feature}) async {
    if (!await requirePro(context, ref, feature) || !mounted) return;
    if (feature != ProFeature.customExchangeRate) return;
    final currency = (_selectedCurrency ?? ref.read(currencyProvider))!;
    if (currencyOptionForSymbol(currency).code == 'TRY') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(ref, 'pro_custom_rate_try_identity'))),
      );
      return;
    }
    final result = await _showCustomRateDialog(currency);
    if (result != null && mounted) {
      setState(() => _manualExchangeRate = result);
    }
  }

  Future<double?> _showCustomRateDialog(String currency) async {
    final controller = TextEditingController(
      text: _manualExchangeRate?.toStringAsFixed(4) ?? '',
    );
    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr(ref, 'pro_custom_rate_title')),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: trp(ref, 'pro_custom_rate_label', {
              'currency': currency,
            }),
            helperText: tr(ref, 'pro_custom_rate_helper'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr(ref, 'common_cancel')),
          ),
          FilledButton(
            onPressed: () {
              final value = _parseValue(controller.text);
              if (value != null && value > 0) {
                Navigator.pop(dialogContext, value);
              }
            },
            child: Text(tr(ref, 'common_save')),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _scanReceipt() async {
    final canContinue = await requirePro(
      context,
      ref,
      ProFeature.receiptScanner,
    );
    if (!canContinue || !mounted) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: Text(tr(ref, 'pro_receipt_camera')),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text(tr(ref, 'pro_receipt_gallery')),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    setState(() => _isScanning = true);
    try {
      final result = await ref
          .read(receiptServiceProvider)
          .pickAndScan(source: source);
      if (result == null || !mounted) return;
      setState(() {
        _receiptImage = result.image;
        if (result.suggestedDescription?.isNotEmpty == true) {
          _descController.text = result.suggestedDescription!;
        }
        if (result.suggestedAmount != null) {
          _amountController.text = result.suggestedAmount!.toStringAsFixed(2);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(ref, 'pro_receipt_review_required'))),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Widget _buildMemberTile(
    GroupMemberModel member,
    bool isSelected,
    bool isMe,
    String currency,
  ) {
    Widget trailingWidget;

    if (!isSelected) {
      trailingWidget = const Text('0.00', style: TextStyle(color: Colors.grey));
    } else if (_splitType == 'equal') {
      final share = _selectedUsers.isNotEmpty
          ? _totalAmount / _selectedUsers.length
          : 0.0;
      trailingWidget = Text(
        '$currency${share.toStringAsFixed(2)}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      );
    } else if (_splitType == 'percentage') {
      final currentValue = _percentageValues[member.userId] ?? 0.0;
      trailingWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 140,
            child: Slider(
              value: currentValue.clamp(0.0, 100.0),
              min: 0,
              max: 100,
              divisions: 100,
              label: '${currentValue.toStringAsFixed(0)}%',
              onChanged: (val) {
                setState(() {
                  _percentageValues[member.userId] = double.parse(
                    val.toStringAsFixed(2),
                  );
                  _syncPercentageAutoFill();
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            child: Text(
              '${currentValue.toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    } else {
      final controller = _exactControllerFor(member.userId);
      trailingWidget = SizedBox(
        width: 120,
        child: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            isDense: true,
            hintText: '0.00',
            suffixText: currency,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
          ),
          onChanged: (val) {
            setState(() {
              _syncExactSplitValues(_totalAmount);
            });
          },
        ),
      );
    }

    return Column(
      children: [
        CheckboxListTile(
          value: isSelected,
          onChanged: (val) {
            setState(() {
              if (val == true) {
                _selectedUsers.add(member.userId);
              } else {
                _selectedUsers.remove(member.userId);
                _removeSelectedUserValue(member.userId);
              }
              if (_splitType == 'percentage') {
                _syncPercentageAutoFill();
              }
              if (_splitType == 'exact') {
                _syncExactSplitValues(_totalAmount);
              }
            });
          },
          title: Row(
            children: [
              Flexible(
                child: Text(
                  isMe
                      ? tr(ref, 'common_you')
                      : '@${member.username ?? member.userId.substring(0, 4)}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelected &&
                  ((_splitType == 'percentage' &&
                          member.userId == _percentageAutoUserId) ||
                      (_splitType == 'exact' &&
                          member.userId == _exactAutoUserId))) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tr(ref, 'groups_auto_badge'),
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ),
              ],
            ],
          ),
          secondary: CircleAvatar(
            backgroundColor: isMe
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.grey.shade200,
            child: Icon(
              Icons.person,
              color: isMe ? Theme.of(context).colorScheme.primary : Colors.grey,
            ),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          subtitle: Align(
            alignment: _splitType == 'percentage'
                ? AlignmentDirectional.centerStart
                : AlignmentDirectional.centerEnd,
            child: trailingWidget,
          ),
        ),
      ],
    );
  }

  void _submitExpense() async {
    final amount = _totalAmount;
    if (amount <= 0 || _descController.text.isEmpty || _selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(ref, 'groups_expense_validation_generic'))),
      );
      return;
    }

    final splitAmounts = <String, double>{};
    final splitPercentages = <String, double>{};

    if (_splitType == 'equal') {
      final share = double.parse(
        (amount / _selectedUsers.length).toStringAsFixed(2),
      );
      for (var uid in _selectedUsers) {
        splitAmounts[uid] = share;
      }

      // Fix rounding errors (add remainder to current user if they are in the split, or first user)
      double totalCalculated = share * _selectedUsers.length;
      if ((amount - totalCalculated).abs() > 0.001) {
        String firstUser = _selectedUsers.first;
        splitAmounts[firstUser] = double.parse(
          (share + (amount - totalCalculated)).toStringAsFixed(2),
        );
      }
    } else if (_splitType == 'percentage') {
      _syncPercentageAutoFill();
      final splitValues = <String, double>{};
      for (final userId in _selectedUsers) {
        final value = _percentageValues[userId];
        if (value == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr(ref, 'groups_percentage_validation'))),
          );
          return;
        }
        splitValues[userId] = value;
      }

      final totalPercentage = splitValues.values.fold<double>(
        0.0,
        (sum, value) => sum + value,
      );
      if ((totalPercentage - 100).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(ref, 'groups_percentage_total_validation')),
          ),
        );
        return;
      }

      for (var uid in _selectedUsers) {
        final pct = splitValues[uid] ?? 0.0;
        splitAmounts[uid] = double.parse(
          ((amount * pct) / 100).toStringAsFixed(2),
        );
        splitPercentages[uid] = pct;
      }
    } else if (_splitType == 'exact') {
      final splitValues = _syncExactSplitValues(amount);
      if (splitValues == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(ref, 'groups_exact_validation'))),
        );
        return;
      }

      for (var uid in _selectedUsers) {
        splitAmounts[uid] = splitValues[uid] ?? 0.0;
      }
    }

    final String entryCurrency =
        _selectedCurrency ?? ref.read(currencyProvider);
    final currencyOption = currencyOptionForSymbol(entryCurrency);
    final exchanger = ref.read(exchangeRateProvider);
    final isBaseCurrency = currencyOption.code == 'TRY';
    final canConvert =
        isBaseCurrency ||
        _manualExchangeRate != null ||
        await exchanger.ensureFresh();
    if (!canConvert) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(ref, 'exchange_rate_unavailable'))),
        );
      }
      return;
    }

    final exchangeRate = isBaseCurrency
        ? 1.0
        : _manualExchangeRate ?? 1 / exchanger.rateFor(entryCurrency);
    final baseAmount = _roundMoney(amount * exchangeRate);
    final shares = _buildExpenseShares(
      originalShares: splitAmounts,
      percentages: splitPercentages,
      exchangeRate: exchangeRate,
      targetBaseAmount: baseAmount,
    );
    final rateLockedAt = isBaseCurrency || _manualExchangeRate != null
        ? DateTime.now().toUtc()
        : exchanger.lastUpdatedAt!;

    final expense = ExpenseDraft(
      groupId: widget.groupId,
      payerId: widget.currentUserId,
      description: _descController.text,
      expenseDate: DateTime.now(),
      splitType: ExpenseSplitTypeCodec.parse(_splitType),
      originalAmount: amount,
      currencyCode: currencyOption.code,
      baseAmount: baseAmount,
      baseCurrencyCode: 'TRY',
      exchangeRate: exchangeRate,
      rateSource: isBaseCurrency
          ? 'identity'
          : _manualExchangeRate != null
          ? 'manual_user_locked'
          : exchanger.currentRateSource,
      rateLockedAt: rateLockedAt,
      shares: shares,
    );

    try {
      setState(() => _isSubmitting = true);
      final created = await ref
          .read(groupServiceProvider)
          .createExpense(expense);
      final receiptImage = _receiptImage;
      if (receiptImage != null) {
        try {
          await ref
              .read(receiptServiceProvider)
              .uploadForExpense(image: receiptImage, expenseId: created.id);
          ref.invalidate(expenseReceiptsProvider(created.id));
          await ref
              .read(analyticsServiceProvider)
              .proFeatureCompleted(
                feature: ProFeature.receiptAttachment.analyticsValue,
              );
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(tr(ref, 'pro_receipt_upload_failed'))),
            );
          }
        }
      }
      ref.invalidate(groupExpensesStreamProvider(widget.groupId));
      ref.invalidate(groupBalancesProvider(widget.groupId));
      ref.invalidate(groupSettlementsProvider(widget.groupId));
      ref.read(groupDataRefreshProvider.notifier).state++;

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  double _roundMoney(double value) {
    return double.parse(value.toStringAsFixed(2));
  }

  List<ExpenseShareDraft> _buildExpenseShares({
    required Map<String, double> originalShares,
    required Map<String, double> percentages,
    required double exchangeRate,
    required double targetBaseAmount,
  }) {
    final baseShares = {
      for (final entry in originalShares.entries)
        entry.key: _roundMoney(entry.value * exchangeRate),
    };
    final convertedTotal = baseShares.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    final adjustment = _roundMoney(targetBaseAmount - convertedTotal);
    if (baseShares.isNotEmpty && adjustment.abs() >= 0.01) {
      final firstKey = baseShares.keys.first;
      baseShares[firstKey] = _roundMoney(baseShares[firstKey]! + adjustment);
    }

    return originalShares.entries
        .map(
          (entry) => ExpenseShareDraft(
            participantId: entry.key,
            originalShareAmount: entry.value,
            baseShareAmount: baseShares[entry.key]!,
            sharePercentage: percentages[entry.key],
          ),
        )
        .toList(growable: false);
  }

  Map<String, double>? _syncExactSplitValues(double targetTotal) {
    if (_splitType != 'exact' || _selectedUsers.isEmpty) return null;

    final values = <String, double>{};
    final emptyUsers = <String>[];

    for (final userId in _selectedUsers) {
      final raw = _exactControllers[userId]?.text ?? '';
      final parsed = _parseValue(raw);

      if (parsed == null) {
        emptyUsers.add(userId);
        continue;
      }

      values[userId] = parsed;
    }

    final selectedUserIds = _selectedUsers.toList();
    if (_exactAutoUserId != null &&
        !selectedUserIds.contains(_exactAutoUserId)) {
      _exactAutoUserId = null;
    }

    if (_exactAutoUserId == null && emptyUsers.length == 1) {
      _exactAutoUserId = emptyUsers.first;
    }

    final autoUserId = _exactAutoUserId;
    if (autoUserId == null || !selectedUserIds.contains(autoUserId)) {
      return null;
    }

    final manualTotal = selectedUserIds
        .where((userId) => userId != autoUserId)
        .fold<double>(0.0, (sum, userId) => sum + (values[userId] ?? 0.0));

    final remainder = double.parse(
      (targetTotal - manualTotal).toStringAsFixed(2),
    );
    if (remainder < -0.01) {
      return null;
    }

    values[autoUserId] = remainder;
    final controller = _exactControllers[autoUserId];
    if (controller != null) {
      final formatted = remainder.toStringAsFixed(2);
      if (controller.text != formatted) {
        controller.value = controller.value.copyWith(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
          composing: TextRange.empty,
        );
      }
    }

    return values;
  }
}
