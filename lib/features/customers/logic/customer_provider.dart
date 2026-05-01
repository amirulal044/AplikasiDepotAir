import 'package:flutter/material.dart';
import '../data/customer_repository.dart';

class CustomerProvider extends ChangeNotifier {
  final _repo = CustomerRepository();
  List<Map<String, dynamic>> customers = [];
  bool isLoading = false;

  Future<void> fetchCustomers() async {
    isLoading = true;
    notifyListeners();
    try {
      customers = await _repo.getCustomers();
    } catch (e) {
      print("Error fetch customers: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> saveCustomer(
    String nama,
    String telepon,
    String alamat, {
    String? id,
  }) async {
    try {
      Map<String, dynamic> result;
      if (id == null) {
        result = await _repo.addCustomer(nama, telepon, alamat);
      } else {
        await _repo.updateCustomer(id, nama, telepon, alamat);
        result = {'id': id, 'nama': nama};
      }
      await fetchCustomers();
      return result; // <--- SEKARANG MENGEMBALIKAN DATA, BUKAN TRUE/FALSE
    } catch (e) {
      return null; // <--- JIKA GAGAL KEMBALIKAN NULL
    }
  }

  Future<bool> removeCustomer(String id) async {
    try {
      await _repo.deleteCustomer(id);
      await fetchCustomers();
      return true;
    } catch (e) {
      return false;
    }
  }
}
