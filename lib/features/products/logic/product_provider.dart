import 'package:flutter/material.dart';
import '../data/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  final _repo = ProductRepository();
  List<Map<String, dynamic>> products = [];
  bool isLoading = false;

  Future<void> fetchProducts() async {
    isLoading = true;
    notifyListeners();
    try {
      products = await _repo.getProducts();
    } catch (e) {
      print("Error fetch: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> saveProduct(
    String nama,
    String ukuran,
    String harga,
    bool isCoupon,
    int lastCoupon,
    bool isRedemption, // <--- Tambahan
  ) async {
    try {
      final newProd = await _repo.addProduct(
        nama,
        ukuran,
        int.parse(harga),
        isCoupon,
        lastCoupon,
        isRedemption,
      );
      await fetchProducts();
      return newProd;
    } catch (e) {
      return null;
    }
  }

  Future<bool> editProduct(
    String id,
    String nama,
    String ukuran,
    String harga,
    bool isCoupon,
    int lastCoupon,
    bool isRedemption, // <--- Tambahan
  ) async {
    try {
      await _repo.updateProduct(
        id,
        nama,
        ukuran,
        int.parse(harga),
        isCoupon,
        lastCoupon,
        isRedemption,
      );
      await fetchProducts();
      return true;
    } catch (e) {
      print("Error edit: $e");
      return false;
    }
  }

  Future<bool> removeProduct(String id) async {
    try {
      await _repo.deleteProduct(id);
      await fetchProducts();
      return true;
    } catch (e) {
      print("Error delete: $e");
      return false;
    }
  }
}
