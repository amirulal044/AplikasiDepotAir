import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/product_provider.dart';

class ProductFormScreen extends StatefulWidget {
  final Map<String, dynamic>? product;

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
  late bool isRedemptionItem; // <--- State baru

  final List<String> rekomendasiUkuran = ['19L', '15L', '12.5L', '10L'];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    nameController = TextEditingController(text: p?['nama_produk'] ?? '');
    priceController = TextEditingController(
      text: p?['harga']?.toString() ?? '',
    );
    ukuranController = TextEditingController(text: p?['ukuran'] ?? '19L');
    kuponController = TextEditingController(
      text: p?['last_coupon_number']?.toString() ?? '0',
    );

    // Inisialisasi status awal
    isRedemptionItem = p?['is_redemption_item'] ?? false;
    isCouponEnabled =
        p?['is_coupon_enabled'] ?? (isRedemptionItem ? false : true);
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
                  hintText: "Contoh: Air Mineral",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              // --- SEKSI REDEMPTION (POIN 3) ---
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isRedemptionItem ? Colors.orange.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isRedemptionItem ? Colors.orange : Colors.blue.shade200),
                ),
                child: SwitchListTile(
                  title: const Text("Ini Produk Hadiah (Tukar Kupon)?"),
                  subtitle: const Text("Jika ON: Harga Rp 0 & Memotong Saldo Kupon Pelanggan"),
                  value: isRedemptionItem,
                  activeColor: Colors.orange,
                  onChanged: (val) {
                    setState(() {
                      isRedemptionItem = val;
                      if (val) {
                        priceController.text = "0";
                        isCouponEnabled = false; // Hadiah tidak dapat kupon baru
                      } else {
                        if (ukuranController.text.toUpperCase() == '19L') isCouponEnabled = true;
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
              const Text("Ukuran Galon", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: ukuranController,
                decoration: const InputDecoration(
                  hintText: "Contoh: 19L atau 15L",
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.straighten),
                ),
                onChanged: (val) {
                  setState(() {
                    // Hanya otomatis ON jika ukuran 19L dan BUKAN produk hadiah
                    if (!isRedemptionItem) {
                      isCouponEnabled = (val.toUpperCase().trim() == '19L');
                    }
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
                        if (!isRedemptionItem) isCouponEnabled = (ukuran == '19L');
                      });
                    },
                    backgroundColor: ukuranController.text == ukuran ? Colors.blue.shade100 : null,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: priceController,
                enabled: !isRedemptionItem, // Kunci jika hadiah
                decoration: InputDecoration(
                  labelText: "Harga Jual",
                  prefixText: "Rp ",
                  border: const OutlineInputBorder(),
                  filled: isRedemptionItem,
                  fillColor: isRedemptionItem ? Colors.grey.shade200 : null,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),

              // --- FITUR KUPON FISIK (Hanya muncul jika berbayar) ---
              if (!isRedemptionItem) ...[
                SwitchListTile(
                  title: const Text("Gunakan Penomoran Kupon Fisik"),
                  subtitle: const Text("Hanya untuk galon berbayar (Poin)"),
                  value: isCouponEnabled,
                  onChanged: (val) => setState(() => isCouponEnabled = val),
                ),
                if (isCouponEnabled)
                  TextField(
                    controller: kuponController,
                    decoration: const InputDecoration(
                      labelText: "Nomor Kupon Fisik Terakhir",
                      border: OutlineInputBorder(),
                      helperText: "Input nomor terakhir di buku fisik Anda",
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
                    backgroundColor: isRedemptionItem
                        ? Colors.orange
                        : Colors.blue,
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
                            int.tryParse(kuponController.text) ?? 0,
                            isRedemptionItem, // <--- Kirim parameter baru
                          );
                    } else {
                      result = await context
                          .read<ProductProvider>()
                          .saveProduct(
                            nameController.text,
                            ukuranController.text,
                            priceController.text,
                            isCouponEnabled,
                            int.tryParse(kuponController.text) ?? 0,
                            isRedemptionItem, // <--- Kirim parameter baru
                          );
                    }

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
                  child: Text(
                    isEdit ? "PERBARUI PRODUK" : "SIMPAN PRODUK",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
