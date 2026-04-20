import 'package:flutter/material.dart';
import '../data/product_repository.dart';
import '../domain/product_model.dart';
import 'dart:developer' as dev; // Untuk log yang lebih detail

class ProductScreen extends StatefulWidget {
  final String storeId;

  const ProductScreen({super.key, required this.storeId});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final _repo = ProductRepository();
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      dev.log("Memuat produk untuk storeId: ${widget.storeId}");
      final data = await _repo.getProducts(widget.storeId);
      setState(() => _products = data);
    } catch (e) {
      dev.log("Error load produk: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat produk: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final sizeController = TextEditingController();
    final priceController = TextEditingController();
    bool isLoyalty = false;
    bool isSaving = false; // State loading di dalam dialog

    showDialog(
      context: context,
      barrierDismissible: false, // User tidak bisa klik luar saat simpan
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Tambah Jenis Galon"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Nama Produk"),
                ),
                TextField(
                  controller: sizeController,
                  decoration: const InputDecoration(labelText: "Ukuran (Liter)"),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: "Harga (Rp)"),
                  keyboardType: TextInputType.number,
                ),
                SwitchListTile(
                  title: const Text("Gunakan Sistem Kupon?"),
                  value: isLoyalty,
                  onChanged: (val) => setDialogState(() => isLoyalty = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                // --- VALIDASI AWAL ---
                if (nameController.text.isEmpty || sizeController.text.isEmpty || priceController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Semua kolom wajib diisi!")),
                  );
                  return;
                }

                setDialogState(() => isSaving = true);

                try {
                  dev.log("Mencoba menyimpan produk baru...");
                  
                  final newProd = ProductModel(
                    storeId: widget.storeId,
                    name: nameController.text,
                    size: double.tryParse(sizeController.text) ?? 0,
                    price: double.tryParse(priceController.text) ?? 0,
                    isLoyalty: isLoyalty,
                  );

                  await _repo.addProduct(newProd);
                  
                  dev.log("Produk berhasil disimpan ke Supabase.");
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    _loadProducts(); // Refresh list
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Produk berhasil ditambah!"), backgroundColor: Colors.green),
                    );
                  }
                } catch (e, stacktrace) {
                  // --- DETEKSI ERROR DI TERMINAL ---
                  debugPrint("========= ERROR SAVE PRODUCT =========");
                  debugPrint("Pesan: $e");
                  debugPrint("Stacktrace: $stacktrace");
                  debugPrint("======================================");

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Gagal simpan: $e"), backgroundColor: Colors.red),
                    );
                  }
                } finally {
                  setDialogState(() => isSaving = false);
                }
              },
              child: Text(isSaving ? "Proses..." : "Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... Bagian build tetap sama ...
    return Scaffold(
      appBar: AppBar(title: const Text("Manajemen Produk")),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
          ? const Center(child: Text("Belum ada produk. Tambahkan satu!"))
          : ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final p = _products[index];
                return ListTile(
                  leading: CircleAvatar(child: Text("${p['size'].toInt()}L")),
                  title: Text(p['name']),
                  subtitle: Text("Rp ${p['price']}"),
                  trailing: p['is_loyalty']
                      ? const Icon(Icons.confirmation_num, color: Colors.red)
                      : null,
                );
              },
            ),
    );
  }
}