import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_provider.dart';
import '../services/api_service.dart';

// ============================================
// MENU SCREEN - Stranica s jelima i košaricom
// ============================================
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin {
  List<MenuItem> _menuItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMenuItems();
  }

  Future<void> _loadMenuItems() async {
    final response = await ApiService.getMenuItems();

    if (response.success && response.data != null) {
      final List<dynamic> data = response.data;
      setState(() {
        _menuItems = data.map((item) => MenuItem(
          id: item['id'].toString(),
          name: item['name'] ?? '',
          description: item['description'] ?? '',
          price: (item['price'] as num).toDouble(),
          category: item['category'] ?? '',
          imageUrl: item['imageUrl'] ?? '',
        )).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = response.error;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'MENU',
          style: TextStyle(
            letterSpacing: 8,
            fontWeight: FontWeight.w300,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Degustacijski Menu — Sezona 2026',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  letterSpacing: 2,
                ),
              ),
            ),

            // Lista jela
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1C1917),
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                style: TextStyle(color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _isLoading = true;
                                    _error = null;
                                  });
                                  _loadMenuItems();
                                },
                                child: const Text('Pokušaj ponovo'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _menuItems.length,
                          itemBuilder: (context, index) {
                            return _MenuItemCard(item: _menuItems[index]);
                          },
                        ),
            ),

            // Košarica bar na dnu
            const _CartBottomBar(),
          ],
        ),
      ),
    );
  }
}

// ============================================
// MENU ITEM CARD - Kartica jela s dodavanjem
// ============================================
class _MenuItemCard extends StatelessWidget {
  final MenuItem item;

  const _MenuItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final quantity = cart.getQuantity(item.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Slika jela
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(16),
            ),
            child: item.imageUrl.isNotEmpty
                ? Image.network(
                    item.imageUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[200],
                        child: Icon(Icons.restaurant, color: Colors.grey[400], size: 40),
                      );
                    },
                  )
                : Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[200],
                    child: Icon(Icons.restaurant, color: Colors.grey[400], size: 40),
                  ),
          ),
          // Tekst
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.category.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 2,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Cijena i gumb za dodavanje
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${item.price.toStringAsFixed(0)} EUR',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      // Gumb za dodavanje/količina
                      quantity == 0
                          ? GestureDetector(
                              onTap: () {
                                cart.addItem(
                                  id: item.id,
                                  name: item.name,
                                  description: item.description,
                                  price: item.price,
                                  imageUrl: item.imageUrl,
                                );
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.green[400],
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            '${item.name} dodano',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    duration: const Duration(milliseconds: 1500),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: const Color(0xFF1C1917),
                                    margin: const EdgeInsets.only(
                                      bottom: 100,
                                      left: 20,
                                      right: 20,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 8,
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1C1917),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Dodaj',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => cart.decreaseQuantity(item.id),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      child: Icon(
                                        Icons.remove,
                                        size: 16,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      '$quantity',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => cart.increaseQuantity(item.id),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF1C1917),
                                        borderRadius: BorderRadius.horizontal(
                                          right: Radius.circular(10),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// CART BOTTOM BAR - Traka košarice na dnu
// ============================================
class _CartBottomBar extends StatelessWidget {
  const _CartBottomBar();

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return GestureDetector(
      onTap: () => _showCartBottomSheet(context),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1917),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'KOŠARICA',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cart.isEmpty
                      ? 'Košarica je prazna'
                      : '${cart.itemCount} ${cart.itemCount == 1 ? 'stavka' : cart.itemCount < 5 ? 'stavke' : 'stavki'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Text(
              cart.isEmpty ? '0 EUR' : cart.formattedTotal,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCartBottomSheet(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return const _CartBottomSheet();
        },
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          );
        },
      ),
    );
  }
}

// ============================================
// CART BOTTOM SHEET - Animirani prikaz košarice
// ============================================
class _CartBottomSheet extends StatefulWidget {
  const _CartBottomSheet();

  @override
  State<_CartBottomSheet> createState() => _CartBottomSheetState();
}

class _CartBottomSheetState extends State<_CartBottomSheet> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isLoading = false;
  double _dragOffset = 0;
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dy;
      if (_dragOffset < 0) _dragOffset = 0; // Ne dozvoli povlačenje prema gore iznad početne pozicije
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final screenHeight = MediaQuery.of(context).size.height;
    final threshold = screenHeight * 0.2; // 20% ekrana

    if (_dragOffset > threshold || (details.primaryVelocity ?? 0) > 500) {
      // Zatvori ako je povučeno dovoljno dolje ili brzo
      Navigator.pop(context);
    } else {
      // Vrati natrag
      _animation = Tween<double>(begin: _dragOffset, end: 0).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
      );
      _animController.forward(from: 0).then((_) {
        setState(() => _dragOffset = 0);
      });
      _animation.addListener(() {
        setState(() => _dragOffset = _animation.value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Košarica
              Positioned(
                left: 0,
                right: 0,
                bottom: -_dragOffset,
                height: screenHeight * 0.92,
                child: GestureDetector(
                  onTap: () {}, // Prevent closing when tapping the sheet
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF1C1917),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      children: [
                        // Ručica za povlačenje - draggable
                        GestureDetector(
                          onVerticalDragUpdate: _onDragUpdate,
                          onVerticalDragEnd: _onDragEnd,
                          child: Container(
                            padding: const EdgeInsets.only(top: 12, bottom: 8),
                            width: double.infinity,
                            color: Colors.transparent,
                            child: Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Header - također draggable
                        GestureDetector(
                          onVerticalDragUpdate: _onDragUpdate,
                          onVerticalDragEnd: _onDragEnd,
                          child: Container(
                            color: Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'KOŠARICA',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 4,
                                    color: Colors.white,
                                  ),
                                ),
                                if (!cart.isEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      cart.clear();
                                    },
                                    child: Text(
                                      'Isprazni',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.red[300],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),

                        // Sadržaj
                        Expanded(
                          child: cart.isEmpty
                              ? _buildEmptyCart()
                              : _buildCartContent(cart, null),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Prazna košarica
  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 60,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Košarica je prazna',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dodajte jela iz menija',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1C1917),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'PREGLEDAJ MENU',
              style: TextStyle(
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sadržaj košarice s adresom
  Widget _buildCartContent(CartProvider cart, ScrollController? scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stavke u košarici
          Text(
            'VAŠA NARUDŽBA',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 2,
              color: Colors.white.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          ...cart.items.map((item) => _buildCartItem(item, cart)),

          const SizedBox(height: 24),

          // Podaci za dostavu
          Text(
            'PODACI ZA DOSTAVU',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 2,
              color: Colors.white.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _nameController,
            label: 'Ime i prezime',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _phoneController,
            label: 'Broj telefona',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _addressController,
            label: 'Adresa dostave',
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _noteController,
            label: 'Napomena (opcionalno)',
            icon: Icons.note_outlined,
          ),

          const SizedBox(height: 24),

          // Ukupno
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ukupno stavki',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                    ),
                    Text(
                      '${cart.itemCount}',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dostava',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                    ),
                    Text(
                      'Besplatno',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green[400],
                      ),
                    ),
                  ],
                ),
                Divider(height: 24, color: Colors.white.withValues(alpha: 0.2)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'UKUPNO',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      cart.formattedTotal,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Gumb za naručivanje
          _buildSubmitButton('NARUČI', _submitOrder),

          // Dovoljno prostora za safe area na dnu
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item, CartProvider cart) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.imageUrl.isNotEmpty
                ? Image.network(
                    item.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.white.withValues(alpha: 0.1),
                      child: Icon(Icons.restaurant, color: Colors.white.withValues(alpha: 0.4), size: 24),
                    ),
                  )
                : Container(
                    width: 60,
                    height: 60,
                    color: Colors.white.withValues(alpha: 0.1),
                    child: Icon(Icons.restaurant, color: Colors.white.withValues(alpha: 0.4), size: 24),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.price.toStringAsFixed(0)} EUR',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => cart.decreaseQuantity(item.id),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.remove, size: 16, color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${item.quantity}',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
                GestureDetector(
                  onTap: () => cart.increaseQuantity(item.id),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.add, size: 16, color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 14, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _buildSubmitButton(String text, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1C1917),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Color(0xFF1C1917), strokeWidth: 2),
              )
            : Text(
                text,
                style: const TextStyle(
                  letterSpacing: 3,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
      ),
    );
  }

  Future<void> _submitOrder() async {
    if (_nameController.text.isEmpty) {
      _showError('Molimo unesite ime i prezime');
      return;
    }
    if (_phoneController.text.isEmpty) {
      _showError('Molimo unesite broj telefona');
      return;
    }
    if (_addressController.text.isEmpty) {
      _showError('Molimo unesite adresu dostave');
      return;
    }

    final cart = context.read<CartProvider>();

    setState(() => _isLoading = true);

    // Pripremi stavke za API
    final items = cart.items.map((item) => {
      'menuItemId': int.tryParse(item.id) ?? 0,
      'quantity': item.quantity,
      'notes': '',
    }).toList();

    // Pošalji narudžbu na backend
    final response = await ApiService.createGuestOrder(
      customerName: _nameController.text,
      phone: _phoneController.text,
      deliveryAddress: _addressController.text,
      notes: _noteController.text,
      items: items,
    );

    setState(() => _isLoading = false);

    if (response.success) {
      if (mounted) {
        Navigator.pop(context);
        _showOrderSuccessDialog();
        cart.clear();
      }
    } else {
      _showError(response.error ?? 'Greška pri slanju narudžbe');
    }
  }

  void _showOrderSuccessDialog() {
    final name = _nameController.text;
    final address = _addressController.text;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[400]!, Colors.green[600]!],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                'USPJEŠNO',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 4,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Narudžba zaprimljena!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Hvala $name!\n\nVaša narudžba će biti dostavljena na:\n$address',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1C1917),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'U REDU',
                    style: TextStyle(
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

}

// ============================================
// MODEL - Struktura podataka za jelo
// ============================================
class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageUrl;

  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
  });
}
