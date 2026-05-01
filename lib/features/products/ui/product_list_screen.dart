import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/product_provider.dart';
import 'product_form_screen.dart';

class ProductListScreen extends StatefulWidget {
  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  @override
  void initState() {
    super.initState();
    // Ambil data saat pertama kali buka tab
    Future.microtask(() => context.read<ProductProvider>().fetchProducts());
  }

  @override
  Widget build(BuildContext context) {
    final watchProd = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Daftar Produk")),
      body: watchProd.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: watchProd.products.length,
              itemBuilder: (context, index) {
                final item = watchProd.products[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: item['is_coupon_enabled']
                        ? Colors.blue
                        : Colors.grey,
                    child: const Icon(Icons.water_drop, color: Colors.white),
                  ),
                  title: Text("${item['nama_produk']} (${item['ukuran']})"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Rp ${item['harga']}"),
                      if (item['is_coupon_enabled'])
                        Text(
                          "Kupon Terakhir: #${item['last_coupon_number']}",
                          style: TextStyle(color: Colors.blue, fontSize: 12),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item['is_coupon_enabled'])
                        const Icon(
                          Icons.confirmation_number,
                          color: Colors.orange,
                          size: 20,
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductFormScreen(
                                product: item,
                              ), // Kirim data produk
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          // Konfirmasi Hapus
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Hapus Produk?"),
                              content: const Text(
                                "Data produk ini akan dihapus permanen.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text("Batal"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text(
                                    "Hapus",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            final success = await watchProd.removeProduct(
                              item['id'],
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? "Produk berhasil dihapus"
                                        : "Gagal menghapus produk",
                                  ),
                                  backgroundColor: success
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductFormScreen()),
        ),
      ),
    );
  }
}
