class CustomerModel {
  final String? id;
  final String storeId;
  final String name;
  final String? phone;
  final String? address;

  CustomerModel({
    this.id,
    required this.storeId,
    required this.name,
    this.phone,
    this.address,
  });

  // Untuk konversi dari Map Supabase ke Object Flutter
  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'],
      storeId: map['store_id'],
      name: map['name'],
      phone: map['phone'],
      address: map['address'],
    );
  }

  // Untuk konversi dari Object ke Map Supabase
  Map<String, dynamic> toMap() {
    return {
      'store_id': storeId,
      'name': name,
      'phone': phone,
      'address': address,
    };
  }
}