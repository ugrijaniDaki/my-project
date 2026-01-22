import 'package:flutter/foundation.dart';

// ============================================
// CART ITEM MODEL
// ============================================
class CartItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
  });

  double get totalPrice => price * quantity;
}

// ============================================
// CART PROVIDER - Upravljanje košaricom
// ============================================
class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  String? _deliveryAddress;
  String? _deliveryNote;

  // Getteri
  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => _items.isEmpty;
  String? get deliveryAddress => _deliveryAddress;
  String? get deliveryNote => _deliveryNote;

  double get totalPrice {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  String get formattedTotal {
    return '${totalPrice.toStringAsFixed(0)} EUR';
  }

  // Dodaj u košaricu
  void addItem({
    required String id,
    required String name,
    required String description,
    required double price,
    required String imageUrl,
  }) {
    final existingIndex = _items.indexWhere((item) => item.id == id);

    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(CartItem(
        id: id,
        name: name,
        description: description,
        price: price,
        imageUrl: imageUrl,
      ));
    }
    notifyListeners();
  }

  // Ukloni iz košarice
  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  // Smanji količinu
  void decreaseQuantity(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  // Povećaj količinu
  void increaseQuantity(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index].quantity++;
      notifyListeners();
    }
  }

  // Postavi adresu dostave
  void setDeliveryAddress(String address) {
    _deliveryAddress = address;
    notifyListeners();
  }

  // Postavi napomenu
  void setDeliveryNote(String note) {
    _deliveryNote = note;
    notifyListeners();
  }

  // Isprazni košaricu
  void clear() {
    _items.clear();
    _deliveryAddress = null;
    _deliveryNote = null;
    notifyListeners();
  }

  // Dohvati količinu za određeni proizvod
  int getQuantity(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    return index >= 0 ? _items[index].quantity : 0;
  }
}
