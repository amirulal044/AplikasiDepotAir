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

  // Mengubah ke Map untuk disimpan di Supabase
  Map<String, dynamic> toMap() {
    return {
      'store_id': storeId,
      'name': name,
      'size': size,
      'price': price,
      'is_loyalty': isLoyalty,
    };
  }

  // Digunakan saat proses EDIT (Update)
  ProductModel copyWith({
    String? name,
    double? size,
    double? price,
    bool? isLoyalty,
  }) {
    return ProductModel(
      id: this.id,
      storeId: this.storeId,
      name: name ?? this.name,
      size: size ?? this.size,
      price: price ?? this.price,
      isLoyalty: isLoyalty ?? this.isLoyalty,
    );
  }
}