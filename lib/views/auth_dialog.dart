import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/czytella_provider.dart';

class AuthDialog extends StatefulWidget {
  final int initialTabIndex; // 0 = login, 1 = register

  const AuthDialog({super.key, this.initialTabIndex = 0});

  static Future<bool?> show(BuildContext context, {int initialTabIndex = 0}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AuthDialog(initialTabIndex: initialTabIndex),
    );
  }

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login form
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _loginObscure = true;
  bool _loginLoading = false;

  // Register form
  final _registerFormKey = GlobalKey<FormState>();
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerCityController = TextEditingController(text: 'Warszawa');
  final _registerBioController = TextEditingController();
  bool _registerObscure = true;
  bool _registerLoading = false;
  bool _acceptTerms = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void didUpdateWidget(AuthDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabIndex != widget.initialTabIndex) {
      _tabController.animateTo(widget.initialTabIndex);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerCityController.dispose();
    _registerBioController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _loginLoading = true);

    final provider = context.read<CzytellaProvider>();
    final success = await provider.login(
      email: _loginEmailController.text,
      password: _loginPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _loginLoading = false);

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Witaj ponownie, ${provider.currentUser?.name ?? "Czytelniku"}!'),
          backgroundColor: const Color(0xFF1E5128),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleDemoLogin() async {
    setState(() => _loginLoading = true);
    final provider = context.read<CzytellaProvider>();
    await provider.login(
      email: 'jan.czytelnik@czytella.pl',
      password: 'demo_password_123',
    );
    if (!mounted) return;
    setState(() => _loginLoading = false);
    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Zalogowano na konto demonstracyjne: Jan Czytelnik'),
        backgroundColor: Color(0xFF1E5128),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proszę zaakceptować zasady bezpiecznej wymiany'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _registerLoading = true);
    final provider = context.read<CzytellaProvider>();
    final success = await provider.register(
      name: _registerNameController.text,
      email: _registerEmailController.text,
      password: _registerPasswordController.text,
      city: _registerCityController.text,
      bio: _registerBioController.text.isNotEmpty
          ? _registerBioController.text
          : null,
    );

    if (!mounted) return;
    setState(() => _registerLoading = false);

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Konto utworzone pomyślnie! Witaj w Czytella, ${provider.currentUser?.name}!'),
          backgroundColor: const Color(0xFF1E5128),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: const Color(0xFFF9FAF8),
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 26,
                      height: 26,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.menu_book_rounded,
                        color: Color(0xFF1E5128),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Konto w Czytella',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E5128),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close),
                  tooltip: 'Zamknij',
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF1E5128),
                indicatorWeight: 3,
                labelColor: const Color(0xFF1E5128),
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.login_rounded, size: 20),
                    text: 'Logowanie',
                  ),
                  Tab(
                    icon: Icon(Icons.person_add_alt_1_rounded, size: 20),
                    text: 'Rejestracja',
                  ),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildLoginTab(theme),
                _buildRegisterTab(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Zaloguj się do swojego profilu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E5128),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Zarządzaj swoimi książkami na półce, wystawiaj ogłoszenia i rozmawiaj z sąsiadami.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),

            // Email
            TextFormField(
              controller: _loginEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Adres e-mail',
                hintText: 'np. jan.kowalski@gmail.com',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Podaj adres e-mail';
                }
                if (!val.contains('@') || !val.contains('.')) {
                  return 'Podaj poprawny adres e-mail';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password
            TextFormField(
              controller: _loginPasswordController,
              obscureText: _loginObscure,
              decoration: InputDecoration(
                labelText: 'Hasło',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_loginObscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () =>
                      setState(() => _loginObscure = !_loginObscure),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Podaj hasło';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),

            // Submit Button
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E5128),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _loginLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.login_rounded, size: 20),
              label: Text(
                _loginLoading ? 'Logowanie...' : 'Zaloguj się',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              onPressed: _loginLoading ? null : _handleLogin,
            ),
            const SizedBox(height: 14),

            // Divider or demo
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'LUB',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),
            const SizedBox(height: 14),

            // Demo Login Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: Colors.green.shade700),
              ),
              icon: const Icon(Icons.play_circle_outline_rounded,
                  color: Color(0xFF1E5128)),
              label: const Text(
                'Szybkie logowanie demo (Jan Czytelnik)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E5128),
                ),
              ),
              onPressed: _loginLoading ? null : _handleDemoLogin,
            ),
            const SizedBox(height: 16),

            // Switch to register tab
            Center(
              child: TextButton(
                onPressed: () => _tabController.animateTo(1),
                child: const Text('Nie masz jeszcze konta? Zarejestruj się za darmo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Form(
        key: _registerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Utwórz darmowe konto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E5128),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Dołącz do lokalnej społeczności czytelników. Wymieniaj i kupuj książki w okolicy!',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),

            // Name
            TextFormField(
              controller: _registerNameController,
              decoration: InputDecoration(
                labelText: 'Imię lub pseudonim',
                hintText: 'np. Tomasz K.',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Wpisz swoje imię lub pseudonim';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Email
            TextFormField(
              controller: _registerEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Adres e-mail',
                hintText: 'np. tomasz@czytella.pl',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Podaj adres e-mail';
                }
                if (!val.contains('@') || !val.contains('.')) {
                  return 'Podaj poprawny adres e-mail';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // City
            TextFormField(
              controller: _registerCityController,
              decoration: InputDecoration(
                labelText: 'Twoje miasto / dzielnica',
                hintText: 'np. Warszawa, Mokotów',
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Podaj miasto, aby wyszukiwać książki w okolicy 5 km';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Password
            TextFormField(
              controller: _registerPasswordController,
              obscureText: _registerObscure,
              decoration: InputDecoration(
                labelText: 'Hasło',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_registerObscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () =>
                      setState(() => _registerObscure = !_registerObscure),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().length < 6) {
                  return 'Hasło musi mieć minimum 6 znaków';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Bio (optional)
            TextFormField(
              controller: _registerBioController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'O mnie (opcjonalnie)',
                hintText: 'np. Czytam głównie reportaże, kryminały i fantastykę.',
                prefixIcon: const Icon(Icons.info_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Terms checkbox
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _acceptTerms,
              activeColor: const Color(0xFF1E5128),
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Akceptuję zasady bezpiecznej i kulturalnej wymiany książek w Czytelli.',
                style: TextStyle(fontSize: 12),
              ),
              onChanged: (val) => setState(() => _acceptTerms = val ?? false),
            ),
            const SizedBox(height: 14),

            // Submit Button
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E5128),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _registerLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.person_add_rounded, size: 20),
              label: Text(
                _registerLoading ? 'Rejestracja...' : 'Zarejestruj się',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              onPressed: _registerLoading ? null : _handleRegister,
            ),
            const SizedBox(height: 12),

            // Switch to login tab
            Center(
              child: TextButton(
                onPressed: () => _tabController.animateTo(0),
                child: const Text('Masz już konto? Zaloguj się'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
