import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../models/user_book.dart';
import '../models/wishlist_book.dart';
import '../providers/czytella_provider.dart';
import 'isbn_scanner_view.dart';

class AddBookDialog extends StatefulWidget {
  final bool isWishlist;

  const AddBookDialog({super.key, required this.isWishlist});

  @override
  State<AddBookDialog> createState() => _AddBookDialogState();
}

class _AddBookDialogState extends State<AddBookDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _isbnController = TextEditingController();
  final _priceOrBudgetController = TextEditingController();
  final _notesController = TextEditingController();

  UserBookType _bookType = UserBookType.both;
  BookCondition _condition = BookCondition.veryGood;
  WishlistPriority _priority = WishlistPriority.medium;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _priceOrBudgetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<CzytellaProvider>();

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

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.isWishlist
                          ? Colors.purple.shade50
                          : Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.isWishlist
                          ? Icons.favorite_border
                          : Icons.auto_stories,
                      color: widget.isWishlist ? Colors.purple : Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isWishlist
                              ? 'Dodaj do listy życzeń'
                              : 'Dodaj książkę na półkę',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.isWishlist
                              ? 'Zakładka: Książki których szukam'
                              : 'Zakładka: Moje książki na wymianę/sprzedaż',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Scanner Shortcut Button
              OutlinedButton.icon(
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Zeskanuj kod ISBN zamiast wpisywać'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => IsbnScannerView(
                        targetMode: widget.isWishlist
                            ? ScannerTargetMode.wishlist
                            : ScannerTargetMode.myBooks,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),

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

              // ISBN
              TextFormField(
                controller: _isbnController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Numer ISBN (opcjonalnie)',
                  hintText: 'np. 9788308064177',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code),
                ),
              ),
              const SizedBox(height: 14),

              // Fields specific to Tab 1 (Moje książki)
              if (!widget.isWishlist) ...[
                DropdownButtonFormField<BookCondition>(
                  value: _condition,
                  decoration: const InputDecoration(
                    labelText: 'Stan książki',
                    border: OutlineInputBorder(),
                  ),
                  items: BookCondition.values
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.label),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _condition = val);
                  },
                ),
                const SizedBox(height: 12),
                SegmentedButton<UserBookType>(
                  segments: const [
                    ButtonSegment(
                      value: UserBookType.forExchange,
                      label: Text('Wymiana', style: TextStyle(fontSize: 11)),
                    ),
                    ButtonSegment(
                      value: UserBookType.forSale,
                      label: Text('Sprzedaż', style: TextStyle(fontSize: 11)),
                    ),
                    ButtonSegment(
                      value: UserBookType.both,
                      label: Text('Obie opcje', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                  selected: {_bookType},
                  onSelectionChanged: (set) {
                    setState(() => _bookType = set.first);
                  },
                ),
                const SizedBox(height: 12),
                if (_bookType != UserBookType.forExchange)
                  TextFormField(
                    controller: _priceOrBudgetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cena w PLN',
                      border: OutlineInputBorder(),
                      suffixText: 'zł',
                    ),
                  ),
              ],

              // Fields specific to Tab 2 (Wishlist)
              if (widget.isWishlist) ...[
                DropdownButtonFormField<WishlistPriority>(
                  value: _priority,
                  decoration: const InputDecoration(
                    labelText: 'Priorytet poszukiwania',
                    border: OutlineInputBorder(),
                  ),
                  items: WishlistPriority.values
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.label),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _priority = val);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceOrBudgetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Maksymalny budżet (opcjonalnie)',
                    border: OutlineInputBorder(),
                    suffixText: 'zł',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notatki (np. wydanie, stan)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 18),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: Text(
                    widget.isWishlist
                        ? 'Zapisz na liście życzeń'
                        : 'Zapisz na mojej półce',
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final title = _titleController.text.trim();
                      final author = _authorController.text.trim();
                      final isbn = _isbnController.text.trim();
                      final amount =
                          double.tryParse(_priceOrBudgetController.text);
                      final notes = _notesController.text.trim();

                      final coverUrl = isbn.isNotEmpty
                          ? 'https://covers.openlibrary.org/b/isbn/$isbn-M.jpg'
                          : null;

                      if (widget.isWishlist) {
                        provider.addWishlistBook(
                          WishlistBook(
                            id: 'w_${DateTime.now().millisecondsSinceEpoch}',
                            isbn: isbn.isNotEmpty ? isbn : null,
                            title: title,
                            author: author,
                            coverUrl: coverUrl,
                            maxBudget: amount,
                            notes: notes.isNotEmpty ? notes : null,
                            priority: _priority,
                          ),
                        );
                      } else {
                        provider.addUserBook(
                          UserBook(
                            id: 'ub_${DateTime.now().millisecondsSinceEpoch}',
                            book: Book(
                              id: 'b_${DateTime.now().millisecondsSinceEpoch}',
                              isbn: isbn.isNotEmpty ? isbn : '9788300000000',
                              title: title,
                              author: author,
                              condition: _condition,
                              coverUrl: coverUrl,
                            ),
                            type: _bookType,
                            price: amount,
                          ),
                        );
                      }

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Pomyślnie dodano: "$title" do ${widget.isWishlist ? "listy życzeń!" : "Twojej półki!"}',
                          ),
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
