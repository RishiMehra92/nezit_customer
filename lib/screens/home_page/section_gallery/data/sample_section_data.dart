import 'package:flutter/foundation.dart' show VoidCallback;

// Static sample data for the home-section style gallery.
//
// These plain models stand in for the future unified home API. When the API is
// ready, the widgets keep their constructors and only this data source is
// swapped for parsed API models — no widget code needs to change.

class SampleProduct {
  final String name;
  final String imageUrl;
  final double price;
  final double mrp;
  final String unit;
  final int discountPercent;

  const SampleProduct({
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.mrp,
    required this.unit,
    required this.discountPercent,
  });
}

class SampleTile {
  final String name;
  final String imageUrl;

  /// Tap handler — wired by the server-driven layout to navigate (e.g. category
  /// → product listing). Null in the static gallery, where tiles are inert.
  final VoidCallback? onTap;

  const SampleTile({required this.name, required this.imageUrl, this.onTap});
}

/// Deterministic placeholder images (picsum seeds give a stable picture per id).
String _img(String seed, {int w = 300, int h = 300}) =>
    'https://picsum.photos/seed/$seed/$w/$h';

class SampleSectionData {
  const SampleSectionData._();

  static const List<SampleProduct> featuredProducts = [
    SampleProduct(
      name: 'Fresh Bananas',
      imageUrl: 'https://picsum.photos/seed/banana/300/300',
      price: 49,
      mrp: 70,
      unit: '1 dozen',
      discountPercent: 30,
    ),
    SampleProduct(
      name: 'Amul Gold Milk',
      imageUrl: 'https://picsum.photos/seed/milk/300/300',
      price: 33,
      mrp: 35,
      unit: '500 ml',
      discountPercent: 6,
    ),
    SampleProduct(
      name: 'Brown Bread',
      imageUrl: 'https://picsum.photos/seed/bread/300/300',
      price: 45,
      mrp: 55,
      unit: '400 g',
      discountPercent: 18,
    ),
    SampleProduct(
      name: 'Farm Eggs',
      imageUrl: 'https://picsum.photos/seed/eggs/300/300',
      price: 84,
      mrp: 99,
      unit: '6 pcs',
      discountPercent: 15,
    ),
    SampleProduct(
      name: 'Tomatoes',
      imageUrl: 'https://picsum.photos/seed/tomato/300/300',
      price: 28,
      mrp: 40,
      unit: '1 kg',
      discountPercent: 30,
    ),
    SampleProduct(
      name: 'Potato Chips',
      imageUrl: 'https://picsum.photos/seed/chips/300/300',
      price: 20,
      mrp: 20,
      unit: '52 g',
      discountPercent: 0,
    ),
  ];

  static const List<SampleTile> categories = [
    SampleTile(name: 'Fresh Vegetables', imageUrl: 'https://picsum.photos/seed/veg/300/300'),
    SampleTile(name: 'Fresh Fruits', imageUrl: 'https://picsum.photos/seed/fruit/300/300'),
    SampleTile(name: 'Dairy Products', imageUrl: 'https://picsum.photos/seed/dairy/300/300'),
    SampleTile(name: 'Snacks', imageUrl: 'https://picsum.photos/seed/snacks/300/300'),
    SampleTile(name: 'Beverages', imageUrl: 'https://picsum.photos/seed/drinks/300/300'),
    SampleTile(name: 'Bakery', imageUrl: 'https://picsum.photos/seed/bakery/300/300'),
    SampleTile(name: 'Personal Care', imageUrl: 'https://picsum.photos/seed/care/300/300'),
    SampleTile(name: 'Home', imageUrl: 'https://picsum.photos/seed/home/300/300'),
  ];

  static const List<SampleTile> brands = [
    SampleTile(name: 'Amul', imageUrl: 'https://picsum.photos/seed/amul/300/300'),
    SampleTile(name: 'Nestle', imageUrl: 'https://picsum.photos/seed/nestle/300/300'),
    SampleTile(name: 'Britannia', imageUrl: 'https://picsum.photos/seed/britannia/300/300'),
    SampleTile(name: 'Tata', imageUrl: 'https://picsum.photos/seed/tata/300/300'),
    SampleTile(name: 'Coca-Cola', imageUrl: 'https://picsum.photos/seed/coke/300/300'),
    SampleTile(name: 'Lays', imageUrl: 'https://picsum.photos/seed/lays/300/300'),
  ];

  static String wide(String seed) => _img(seed, w: 800, h: 400);
}
