import 'package:flutter/material.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final String image;
  final String? size;
  final String? color;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    this.size,
    this.color,
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
    String? size,
    String? color,
    int quantity = 1,
  }) {
    // Treat different variations as different cart items by combining id with variations
    final compositeId = '${id}_${size ?? 'na'}_${color ?? 'na'}';
    final index = _items.indexWhere((item) => '${item.id}_${item.size ?? 'na'}_${item.color ?? 'na'}' == compositeId);
    
    if (index >= 0) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(
        id: id,
        name: name,
        price: price,
        image: image,
        size: size,
        color: color,
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
