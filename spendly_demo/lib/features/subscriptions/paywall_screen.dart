import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../core/friendly_error.dart';
import 'premium_provider.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offeringsAsync = ref.watch(offeringsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primaryContainer,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: colorScheme.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Icon(Icons.workspace_premium, size: 80, color: colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'Spendly Pro\'ya Geç',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Limitsiz grup oluşturun, tüm istatistiklere erişin ve finansal özgürlüğün tadını çıkarın!',
                style: TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Expanded(
                child: offeringsAsync.when(
                  data: (offerings) {
                    if (offerings == null ||
                        offerings.current == null ||
                        offerings.current!.availablePackages.isEmpty) {
                      return const Center(
                        child: Text('Şu an paket bulunmuyor.'),
                      );
                    }

                    return ListView.builder(
                      itemCount: offerings.current!.availablePackages.length,
                      itemBuilder: (context, index) {
                        final package =
                            offerings.current!.availablePackages[index];
                        return _buildPackageCard(context, ref, package);
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text(friendlyErrorMessage(e))),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final success = await ref
                      .read(premiumProvider.notifier)
                      .restorePurchases();
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Satın alımlar geri yüklendi!'),
                      ),
                    );
                    context.pop();
                  }
                },
                child: Text(
                  'Satın Alımları Geri Yükle',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackageCard(
    BuildContext context,
    WidgetRef ref,
    Package package,
  ) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          // A blocking spinner with no way out feels broken if the purchase
          // call hangs. Track whether the user dismissed it manually so the
          // late-arriving result doesn't pop/navigate a screen they're no
          // longer looking at.
          var cancelled = false;

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              content: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Expanded(child: Text('Satın alma işleniyor...')),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    cancelled = true;
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('İptal'),
                ),
              ],
            ),
          );

          final success = await ref
              .read(premiumProvider.notifier)
              .purchasePackage(package);

          if (cancelled || !context.mounted) return;

          Navigator.pop(context);
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Spendly Pro\'ya hoş geldiniz!')),
            );
            context.pop();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('İşlem iptal edildi veya başarısız oldu.'),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    package.storeProduct.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    package.storeProduct.description,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
              Text(
                package.storeProduct.priceString,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
