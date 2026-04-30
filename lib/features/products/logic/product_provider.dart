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
      // Kita tidak tampilkan snackbar di sini agar tidak mengganggu UI utama,
      // cukup list kosong atau error widget di UI.
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveProduct(
    String nama,
    String ukuran,
    String harga,
    bool isCoupon,
  ) async {
    if (nama.isEmpty || harga.isEmpty) return false;

    try {
      await _repo.addProduct(nama, ukuran, int.parse(harga), isCoupon);
      await fetchProducts();
      return true;
    } catch (e) {
      print("Error save: $e");
      return false;
    }
  }

  Future<bool> editProduct(
    String id,
    String nama,
    String ukuran,
    String harga,
    bool isCoupon,
  ) async {
    try {
      await _repo.updateProduct(id, nama, ukuran, int.parse(harga), isCoupon);
      await fetchProducts(); // Refresh data
      return true;
    } catch (e) {
      print("Error edit: $e");
      return false;
    }
  }

  // Ubah menjadi mengembalikan Future<bool>
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
