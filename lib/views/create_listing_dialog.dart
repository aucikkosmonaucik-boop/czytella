import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../models/listing.dart';
import '../providers/czytella_provider.dart';

class CreateListingDialog extends StatefulWidget {
  const CreateListingDialog({super.key});

  @override
  State<CreateListingDialog> createState() => _CreateListingDialogState();
}

class _CreateListingDialogState extends State<CreateListingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _isbnController = TextEditingController();
  final _priceController = TextEditingController();
  final _preferencesController = TextEditingController();
  final _districtController = TextEditingController();

  ListingType _type = ListingType.both;
  BookCondition _condition = BookCondition.veryGood;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _priceController.dispose();
    _preferencesController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CzytellaProvider>();
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.campaign, color: Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Dodaj nowe ogłoszenie',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tytuł książki *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Podaj tytuł' : null,
              ),
              const SizedBox(height: 12),

              // Author
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(
                  labelText: 'Autor *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Podaj autora' : null,
              ),
              const SizedBox(height: 12),

              // ISBN (Optional)
              TextFormField(
                controller: _isbnController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Numer ISBN (opcjonalnie)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code),
                ),
              ),
              const SizedBox(height: 14),

              // Type Selector
              Text('Rodzaj oferty:', style: theme.textTheme.labelMedium),
              const SizedBox(height: 6),
              SegmentedButton<ListingType>(
                segments: const [
                  ButtonSegment(
                    value: ListingType.exchange,
                    label: Text('Wymiana', style: TextStyle(fontSize: 12)),
                  ),
                  ButtonSegment(
                    value: ListingType.sale,
                    label: Text('Sprzedaż', style: TextStyle(fontSize: 12)),
                  ),
                  ButtonSegment(
                    value: ListingType.both,
                    label: Text('Obie opcje', style: TextStyle(fontSize: 12)),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (set) {
                  setState(() => _type = set.first);
                },
              ),
              const SizedBox(height: 14),

              // Price (if sale or both)
              if (_type != ListingType.exchange) ...[
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cena w PLN *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.payments_outlined),
                    suffixText: 'zł',
                  ),
                  validator: (val) {
                    if (_type != ListingType.exchange) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Podaj cenę sprzedaży';
                      }
                      if (double.tryParse(val) == null) {
                        return 'Nieprawidłowa kwota';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ],

              // Condition dropdown
              DropdownButtonFormField<BookCondition>(
                value: _condition,
                decoration: const InputDecoration(
                  labelText: 'Stan książki',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.grade_outlined),
                ),
                items: BookCondition.values.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Text(c.label),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _condition = val);
                },
              ),
              const SizedBox(height: 12),

              // District / Neighborhood
              TextFormField(
                controller: _districtController,
                decoration: InputDecoration(
                  labelText: 'Dzielnica / Okolica (${provider.currentCity})',
                  hintText: 'np. Mokotów, Śródmieście, Stare Miasto',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // Preferences description
              TextFormField(
                controller: _preferencesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Preferencje wymiany / opis dla czytelników',
                  hintText: 'np. Chętnie wymienię na Kinga lub Dukaja',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Opublikuj ogłoszenie w Czytelli'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final title = _titleController.text.trim();
                      final author = _authorController.text.trim();
                      final isbn = _isbnController.text.trim();
                      final price = double.tryParse(_priceController.text);
                      final district = _districtController.text.trim();
                      final prefs = _preferencesController.text.trim();

                      final book = Book(
                        id: 'book_${DateTime.now().millisecondsSinceEpoch}',
                        isbn: isbn.isNotEmpty ? isbn : '9788300000000',
                        title: title,
                        author: author,
                        condition: _condition,
                        coverUrl: isbn.isNotEmpty
                            ? 'https://covers.openlibrary.org/b/isbn/$isbn-M.jpg'
                            : null,
                        description: prefs,
                      );

                      provider.createDirectListing(
                        book: book,
                        type: _type,
                        price: price,
                        exchangePreferences: prefs.isNotEmpty ? prefs : null,
                        district: district.isNotEmpty ? district : null,
                      );

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Pomyślnie dodano ogłoszenie: "$title"!'),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
