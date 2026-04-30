class TransactionModel {
  final String? id;
  final String storeId;
  final String? customerId;
  final String? productId;
  final int qty;
  final double sizeAtTime;
  final double priceAtTime;
  final double totalPrice;
  final String status;
  final String? couponSerial;
  final String? customDescription;

  TransactionModel({
    this.id,
    required this.storeId,
    this.customerId,
    this.productId,
    required this.qty,
    required this.sizeAtTime,
    required this.priceAtTime,
    required this.totalPrice,
    required this.status,
    this.couponSerial,
    this.customDescription,
  });

  Map<String, dynamic> toMap() {
    return {
      'store_id': storeId,
      'customer_id': customerId,
      'product_id': productId,
      'qty': qty,
      'size_at_time': sizeAtTime,
      'price_at_time': priceAtTime,
      'total_price': totalPrice,
      'status': status,
      'coupon_serial': couponSerial,
      'custom_description': customDescription,
    };
  }
}