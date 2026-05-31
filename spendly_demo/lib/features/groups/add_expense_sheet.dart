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

  String _splitType = 'equal'; // 'equal', 'percentage', 'exact'
  Set<String> _selectedUsers = {};
  Map<String, double> _customValues =
      {}; // Holds percentage or exact amounts per user

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_recalculateSplit);
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _recalculateSplit() {
    setState(
      () {},
    ); // Trigger rebuild to show calculated values (mostly for 'equal')
  }

  double get _totalAmount => double.tryParse(_amountController.text) ?? 0.0;

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
                _customValues.clear();
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
    // Determine the calculated or inputted value to show
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
    } else {
      // Inputs for percentage or exact
      trailingWidget = SizedBox(
        width: 80,
        child: TextField(
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            isDense: true,
            suffixText: _splitType == 'percentage' ? '%' : currency,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
          ),
          onChanged: (val) {
            final parsed = double.tryParse(val) ?? 0.0;
            setState(() {
              _customValues[member.userId] = parsed;
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
                _customValues.remove(member.userId);
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
            alignment: Alignment.centerRight,
            child: trailingWidget,
          ),
        ),
        if (isSelected && (_splitType == 'percentage' || _splitType == 'exact'))
          Slider(
            value: (_customValues[member.userId] ?? 0).clamp(
              0.0,
              _splitType == 'percentage' ? 100.0 : _totalAmount,
            ),
            min: 0,
            max: _splitType == 'percentage'
                ? 100.0
                : (_totalAmount > 0 ? _totalAmount : 1.0),
            divisions: 100,
            label: _customValues[member.userId]?.toStringAsFixed(0),
            onChanged: (val) {
              setState(() {
                _customValues[member.userId] = val;
              });
            },
          ),
      ],
    );
  }

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
        splitData[uid] = {'amount': share, 'paid': uid == widget.currentUserId};
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
        };
      }
    } else if (_splitType == 'percentage') {
      double totalPercentage = 0;
      _customValues.forEach((uid, pct) {
        if (_selectedUsers.contains(uid)) totalPercentage += pct;
      });

      if ((totalPercentage - 100).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yüzdelerin toplamı 100 olmalıdır.')),
        );
        return;
      }

      for (var uid in _selectedUsers) {
        final pct = _customValues[uid] ?? 0;
        splitData[uid] = {
          'amount': double.parse(((amount * pct) / 100).toStringAsFixed(2)),
          'paid': uid == widget.currentUserId,
        };
      }
    } else if (_splitType == 'exact') {
      double totalExact = 0;
      _customValues.forEach((uid, val) {
        if (_selectedUsers.contains(uid)) totalExact += val;
      });

      if ((totalExact - amount).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tutar dağılımı toplam harcamaya eşit olmalıdır.'),
          ),
        );
        return;
      }

      for (var uid in _selectedUsers) {
        splitData[uid] = {
          'amount': _customValues[uid] ?? 0.0,
          'paid': uid == widget.currentUserId,
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
    );

    try {
      await ref.read(groupServiceProvider).addGroupTransaction(tx);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }
}
