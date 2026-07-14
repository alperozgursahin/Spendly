import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'group_provider.dart';
import 'group_transaction_model.dart';
import 'group_model.dart';
import '../profile/currency_provider.dart';

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

  double get _totalAmount => double.tryParse(_amountController.text) ?? 0.0;

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
    final currency = ref.watch(currencyProvider);

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
          const Text(
            'Harcama Ekle',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _descController,
            decoration: InputDecoration(
              labelText: 'Ne için?',
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
              labelText: 'Toplam Tutar ($currency)',
              prefixText: '$currency ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Segmented Control for Split Type
          SegmentedButton<String>(
            segments: [
              const ButtonSegment(value: 'equal', label: Text('Eşit (=)')),
              const ButtonSegment(
                value: 'percentage',
                label: Text('Yüzde (%)'),
              ),
              ButtonSegment(value: 'exact', label: Text('Tutar ($currency)')),
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
          const Text(
            'Kimin için harcandı?',
            style: TextStyle(fontWeight: FontWeight.bold),
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Hata: $e')),
            ),
          ),

          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submitExpense,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Kaydet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
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
          title: Text(
            isMe
                ? 'Sen'
                : '@${member.username ?? member.userId.substring(0, 4)}',
          ),
          secondary: CircleAvatar(
            backgroundColor: isMe
                ? Colors.deepPurple.shade100
                : Colors.grey.shade200,
            child: Icon(
              Icons.person,
              color: isMe ? Colors.deepPurple : Colors.grey,
            ),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          subtitle: Align(
            alignment: _splitType == 'percentage'
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: trailingWidget,
          ),
        ),
      ],
    );
  }

  String _initialStatusFor(String uid) =>
      uid == widget.currentUserId ? 'approved' : 'pending';

  void _submitExpense() async {
    final amount = _totalAmount;
    if (amount <= 0 || _descController.text.isEmpty || _selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen geçerli bilgiler girin ve en az 1 kişi seçin.'),
        ),
      );
      return;
    }

    Map<String, dynamic> splitData = {};

    if (_splitType == 'equal') {
      final share = double.parse(
        (amount / _selectedUsers.length).toStringAsFixed(2),
      );
      for (var uid in _selectedUsers) {
        splitData[uid] = {
          'amount': share,
          'paid': uid == widget.currentUserId,
          'status': _initialStatusFor(uid),
        };
      }

      // Fix rounding errors (add remainder to current user if they are in the split, or first user)
      double totalCalculated = share * _selectedUsers.length;
      if ((amount - totalCalculated).abs() > 0.001) {
        String firstUser = _selectedUsers.first;
        splitData[firstUser] = {
          'amount': double.parse(
            (share + (amount - totalCalculated)).toStringAsFixed(2),
          ),
          'paid': firstUser == widget.currentUserId,
          'status': _initialStatusFor(firstUser),
        };
      }
    } else if (_splitType == 'percentage') {
      _syncPercentageAutoFill();
      final splitValues = <String, double>{};
      for (final userId in _selectedUsers) {
        final value = _percentageValues[userId];
        if (value == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Yüzde alanlarında en fazla 1 kişi boş kalabilir ve toplam 100 olmalıdır.',
              ),
            ),
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
          const SnackBar(content: Text('Yüzdelerin toplamı 100 olmalıdır.')),
        );
        return;
      }

      for (var uid in _selectedUsers) {
        final pct = splitValues[uid] ?? 0.0;
        splitData[uid] = {
          'amount': double.parse(((amount * pct) / 100).toStringAsFixed(2)),
          'paid': uid == widget.currentUserId,
          'status': _initialStatusFor(uid),
        };
      }
    } else if (_splitType == 'exact') {
      final splitValues = _syncExactSplitValues(amount);
      if (splitValues == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tutar alanlarında en fazla 1 kişi boş kalabilir ve toplam harcamaya eşit olmalıdır.',
            ),
          ),
        );
        return;
      }

      for (var uid in _selectedUsers) {
        splitData[uid] = {
          'amount': splitValues[uid] ?? 0.0,
          'paid': uid == widget.currentUserId,
          'status': _initialStatusFor(uid),
        };
      }
    }

    final tx = GroupTransactionModel(
      groupId: widget.groupId,
      payerId: widget.currentUserId,
      amount: amount,
      description: _descController.text,
      splitType: _splitType,
      splitData: splitData,
      status: 'pending',
    );

    try {
      await ref.read(groupServiceProvider).addGroupTransaction(tx);
      ref.invalidate(groupTransactionsStreamProvider(widget.groupId));
      ref.invalidate(balanceEngineProvider(widget.groupId));
      ref.read(groupDataRefreshProvider.notifier).state++;

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
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
