import 'package:flutter/material.dart';

class CurrencyOption {
  const CurrencyOption({
    required this.symbol,
    required this.code,
    required this.name,
  });

  final String symbol;
  final String code;
  final String name;

  String get label => '$symbol ($code)';
}

const supportedCurrencies = <CurrencyOption>[
  CurrencyOption(symbol: '₺', code: 'TRY', name: 'Turkish lira'),
  CurrencyOption(symbol: r'$', code: 'USD', name: 'US dollar'),
  CurrencyOption(symbol: '€', code: 'EUR', name: 'Euro'),
];

CurrencyOption currencyOptionForSymbol(String symbol) {
  return supportedCurrencies.firstWhere(
    (option) => option.symbol == symbol,
    orElse: () => supportedCurrencies.first,
  );
}

class CurrencySelector extends StatelessWidget {
  const CurrencySelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.labelText,
    this.compact = false,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String? labelText;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final safeValue =
        supportedCurrencies.any((option) => option.symbol == value)
        ? value
        : supportedCurrencies.first.symbol;

    return DropdownButtonFormField<String>(
      key: ValueKey(safeValue),
      initialValue: safeValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: labelText,
        isDense: compact,
        prefixIcon: compact
            ? null
            : const Icon(Icons.currency_exchange_rounded),
        contentPadding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 10 : 14,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: supportedCurrencies
          .map(
            (option) => DropdownMenuItem<String>(
              value: option.symbol,
              child: Text(option.label, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}
