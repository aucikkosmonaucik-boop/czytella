import 'package:flutter/material.dart';

class SafeExchangeBadge extends StatelessWidget {
  final bool compact;

  const SafeExchangeBadge({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (compact) {
      return InkWell(
        onTap: () => _showSafetyModal(context),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.teal.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield_outlined, size: 16, color: Colors.teal),
              const SizedBox(width: 6),
              Text(
                'Bezpieczna wymiana (brak tel/FB)',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.teal.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bezpieczna wymiana w Czytelli',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Wszystkie szczegóły dogadaj bezpośrednio tutaj na wewnętrznym czacie. Nie ma potrzeby podawania numeru telefonu ani prywatnego profilu na Facebooku.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green.shade900,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, size: 18, color: Colors.green),
            onPressed: () => _showSafetyModal(context),
            tooltip: 'Wskazówki bezpieczeństwa',
          ),
        ],
      ),
    );
  }

  void _showSafetyModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.verified_user, color: Colors.teal),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Zasady bezpiecznej wymiany',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTipRow(
              Icons.chat_bubble_outline,
              'Rozmawiaj tylko w Czytelli',
              'Nasz wewnętrzny czat chroni Twoją prywatność. Nie musisz ujawniać numeru telefonu, adresu e-mail ani kont społecznościowych.',
            ),
            _buildTipRow(
              Icons.place_outlined,
              'Wybieraj miejsca publiczne',
              'Umawiaj się w uczęszczanych punktach: kawiarnie, biblioteki, stacje metra lub centra handlowe.',
            ),
            _buildTipRow(
              Icons.menu_book_outlined,
              'Sprawdź stan książki',
              'Podczas spotkania obejrzyj strony, grzbiet i blok książki przed finalizacją wymiany.',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Rozumiem, dbajmy o bezpieczeństwo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipRow(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.teal.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
