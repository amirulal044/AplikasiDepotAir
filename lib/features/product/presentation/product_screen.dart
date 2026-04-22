import 'package:flutter/material.dart';
import '../data/product_repository.dart';
import '../domain/product_model.dart';

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
      final data = await _repo.getProducts(widget.storeId);
      setState(() => _products = data);
    } catch (e) {
      _showSnackBar("Gagal memuat produk: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- DIALOG FORM (CREATE & UPDATE) ---
  void _openProductForm([Map<String, dynamic>? existingProduct]) {
    final bool isEdit = existingProduct != null;
    
    final nameController = TextEditingController(text: isEdit ? existingProduct['name'] : "");
    final sizeController = TextEditingController(text: isEdit ? existingProduct['size'].toString() : "");
    final priceController = TextEditingController(text: isEdit ? existingProduct['price'].toString() : "");
    bool isLoyalty = isEdit ? (existingProduct['is_loyalty'] ?? false) : false;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? "Edit Jenis Galon" : "Tambah Jenis Galon"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nama Produk")),
                TextField(
                  controller: sizeController,
                  decoration: const InputDecoration(labelText: "Ukuran (Liter)", hintText: "Gunakan titik untuk desimal"),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: "Harga (Rp)"),
                  keyboardType: TextInputType.number,
                ),
                SwitchListTile(
                  title: const Text("Sistem Kupon?"),
                  value: isLoyalty,
                  onChanged: (val) => setDialogState(() => isLoyalty = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: isSaving ? null : () => Navigator.pop(context), child: const Text("Batal")),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (nameController.text.isEmpty || sizeController.text.isEmpty || priceController.text.isEmpty) {
                  _showSnackBar("Semua kolom wajib diisi!", Colors.orange);
                  return;
                }

                setDialogState(() => isSaving = true);
                try {
                  // Penanganan desimal agar support titik atau koma
                  String sizeInput = sizeController.text.replaceAll(',', '.');

                  final model = ProductModel(
                    id: isEdit ? existingProduct['id'] : null,
                    storeId: widget.storeId,
                    name: nameController.text,
                    size: double.tryParse(sizeInput) ?? 0.0,
                    price: double.tryParse(priceController.text) ?? 0.0,
                    isLoyalty: isLoyalty,
                  );

                  if (isEdit) {
                    await _repo.updateProduct(model);
                  } else {
                    await _repo.addProduct(model);
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    _loadProducts();
                    _showSnackBar(isEdit ? "Produk diperbarui!" : "Produk ditambahkan!", Colors.green);
                  }
                } catch (e) {
                  _showSnackBar("Gagal simpan: $e", Colors.red);
                } finally {
                  setDialogState(() => isSaving = false);
                }
              },
              child: Text(isSaving ? "..." : "Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  // --- DIALOG HAPUS (DELETE) ---
  void _confirmDelete(String productId, String productName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Produk?"),
        content: Text("Yakin ingin menghapus $productName?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _repo.deleteProduct(productId);
                if (mounted) {
                  Navigator.pop(context);
                  _loadProducts();
                  _showSnackBar("Produk berhasil dihapus", Colors.orange);
                }
              } catch (e) {
                _showSnackBar("Gagal hapus: $e", Colors.red);
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manajemen Produk")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openProductForm(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(child: Text("Belum ada produk."))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final p = _products[index];
                    
                    // Casting tipe data agar aman dari NoSuchMethodError
                    final num size = p['size'] ?? 0;
                    final num price = p['price'] ?? 0;

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            size % 1 == 0 ? "${size.toInt()}L" : "${size}L",
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                        title: Text(p['name'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Rp ${price.toLocaleString()}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (p['is_loyalty'] == true) 
                              const Icon(Icons.confirmation_num, color: Colors.red, size: 20),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _openProductForm(p),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(p['id'].toString(), p['name'].toString()),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// --- EXTENSION UNTUK FORMAT RIBUAN ---
extension FormatNumber on num {
  String toLocaleString() {
    return toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}