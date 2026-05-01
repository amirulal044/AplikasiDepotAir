import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/product_provider.dart';

class ProductFormScreen extends StatefulWidget {
  final Map<String, dynamic>? product; // Tambahkan parameter ini

  const ProductFormScreen({Key? key, this.product}) : super(key: key);

  @override
  _ProductFormScreenState createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController ukuranController;
  late TextEditingController kuponController;
  late bool isCouponEnabled;

  final List<String> rekomendasiUkuran = ['19L', '15L', '12.5L', '10L'];

  @override
  void initState() {
    super.initState();
    // Inisialisasi data: Jika edit, ambil dari widget.product. Jika tambah, kosongkan.
    nameController = TextEditingController(
      text: widget.product?['nama_produk'] ?? '',
    );
    priceController = TextEditingController(
      text: widget.product?['harga']?.toString() ?? '',
    );
    ukuranController = TextEditingController(
      text: widget.product?['ukuran'] ?? '19L',
    );
    kuponController = TextEditingController(
      text: widget.product?['last_coupon_number']?.toString() ?? '0',
    );
    isCouponEnabled = widget.product?['is_coupon_enabled'] ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? "Edit Produk" : "Tambah Produk")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Nama Produk",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Ukuran Galon / Botol",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ukuranController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.straighten),
                ),
                onChanged: (val) {
                  setState(() {
                    isCouponEnabled = (val.toUpperCase() == '19L');
                  });
                },
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8.0,
                children: rekomendasiUkuran.map((ukuran) {
                  return ActionChip(
                    label: Text(ukuran),
                    onPressed: () {
                      setState(() {
                        ukuranController.text = ukuran;
                        isCouponEnabled = (ukuran == '19L');
                      });
                    },
                    backgroundColor: ukuranController.text == ukuran
                        ? Colors.blue.shade100
                        : null,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: "Harga",
                  prefixText: "Rp ",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),
              SwitchListTile(
                title: const Text("Aktifkan Sistem Kupon"),
                value: isCouponEnabled,
                onChanged: (val) {
                  setState(() => isCouponEnabled = val);
                },
              ),
              if (isCouponEnabled) ...[
                const SizedBox(height: 15),
                TextField(
                  controller: kuponController,
                  decoration: const InputDecoration(
                    labelText: "Nomor Kupon Terakhir (Sekarang)",
                    hintText: "Contoh: 100",
                    helperText:
                        "Nomor ini akan bertambah otomatis saat transaksi",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (nameController.text.isEmpty ||
                        priceController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Nama dan Harga wajib diisi"),
                        ),
                      );
                      return;
                    }

                    // Kita gunakan tipe 'dynamic' karena:
                    // editProduct mengembalikan bool
                    // saveProduct mengembalikan Map?
                    dynamic result;

                    if (isEdit) {
                      result = await context
                          .read<ProductProvider>()
                          .editProduct(
                            widget.product!['id'],
                            nameController.text,
                            ukuranController.text,
                            priceController.text,
                            isCouponEnabled,
                            int.tryParse(kuponController.text) ??
                                0, // <--- Kirim data kupon
                          );
                    } else {
                      result = await context
                          .read<ProductProvider>()
                          .saveProduct(
                            nameController.text,
                            ukuranController.text,
                            priceController.text,
                            isCouponEnabled,
                            int.tryParse(kuponController.text) ??
                                0, // <--- Kirim data kupon
                          );
                    }

                    // Logika pengecekan sukses:
                    // Jika Edit: result harus true
                    // Jika Tambah Baru: result tidak boleh null
                    bool isSuccess = isEdit
                        ? (result == true)
                        : (result != null);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isSuccess ? "Berhasil disimpan" : "Gagal menyimpan",
                          ),
                          backgroundColor: isSuccess
                              ? Colors.green
                              : Colors.red,
                        ),
                      );
                      if (isSuccess) Navigator.pop(context);
                    }
                  },
                  child: Text(isEdit ? "PERBARUI PRODUK" : "SIMPAN PRODUK"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
