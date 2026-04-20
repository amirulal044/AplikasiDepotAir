class ProductModel {
  final String? id;
  final String storeId;
  final String name;
  final double size;
  final double price;
  final bool isLoyalty;

  ProductModel({
    this.id,
    required this.storeId,
    required this.name,
    required this.size,
    required this.price,
    required this.isLoyalty,
  });

  Map<String, dynamic> toMap() {
    return {
      'store_id': storeId,
      'name': name,
      'size': size,
      'price': price,
      'is_loyalty': isLoyalty,
    };
  }
}
