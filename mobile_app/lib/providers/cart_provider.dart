import 'package:flutter/material.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final String image;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    this.quantity = 1,
  });
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  double get subtotal => _items.fold(0, (sum, item) => sum + (item.price * item.quantity));

  void addItem({
    required String id,
    required String name,
    required double price,
    required String image,
    int quantity = 1,
  }) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(
        id: id,
        name: name,
        price: price,
        image: image,
        quantity: quantity,
      ));
    }
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void updateQuantity(String id, int quantity) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0 && quantity > 0) {
      _items[index].quantity = quantity;
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
