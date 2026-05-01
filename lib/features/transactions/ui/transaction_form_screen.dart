import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/transaction_provider.dart';
import 'package:depot_air_app/features/customers/logic/customer_provider.dart';
import 'package:depot_air_app/features/products/logic/product_provider.dart';

class TransactionFormScreen extends StatefulWidget {
  @override
  _TransactionFormScreenState createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  // Controller untuk input manual / terpilih
  final pelangganController = TextEditingController();
  final produkController = TextEditingController();
  final ukuranController = TextEditingController();
  final kuponController = TextEditingController();
  final hargaController = TextEditingController();
  final qtyController = TextEditingController(text: "1");
  final kuponAwalController = TextEditingController();
  // Default 1
  int unitPrice = 0; // Menyimpan harga satuan produk yang dipilih
  String? selectedCustomerId;
  String? selectedProductId;
  int currentCustomerCouponBalance = 0;
  bool isCouponEnabled = false;
  bool useRedemption = false;
  String get couponRangeDisplay {
    int start = int.tryParse(kuponAwalController.text) ?? 0;
    int qty = int.tryParse(qtyController.text) ?? 1;
    if (qty <= 1) return start.toString();
    int end = start + qty - 1;
    return "$start - $end";
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<TransactionProvider>().initForm();
      // Set nomor kupon otomatis (last + 1)
      kuponController.text =
          (context.read<TransactionProvider>().lastCouponNumber + 1).toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TransactionProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Transaksi Baru")),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- BAGIAN PELANGGAN ---
                  const Text(
                    "Pelanggan",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // 1. Kolom Pencarian / Autocomplete
                      Expanded(
                        child: Autocomplete<Map<String, dynamic>>(
                          displayStringForOption: (option) => option['nama'],
                          optionsBuilder: (textEditingValue) {
                            if (textEditingValue.text == '')
                              return const Iterable.empty();
                            // Mencari di master data pelanggan
                            return prov.masterCustomers.where(
                              (c) => c['nama'].toLowerCase().contains(
                                textEditingValue.text.toLowerCase(),
                              ),
                            );
                          },
                          onSelected: (selection) {
                            // KETIKA PELANGGAN DIPILIH DARI REKOMENDASI
                            setState(() {
                              selectedCustomerId = selection['id'];
                              pelangganController.text = selection['nama'];
                              currentCustomerCouponBalance =
                                  selection['coupon_balance'] ?? 0;
                            });
                          },
                          fieldViewBuilder:
                              (
                                context,
                                controller,
                                focusNode,
                                onFieldSubmitted,
                              ) {
                                return TextField(
                                  controller: controller
                                    ..text = pelangganController.text,
                                  focusNode: focusNode,
                                  decoration: const InputDecoration(
                                    hintText: "Cari pelanggan...",
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.search),
                                  ),
                                  onChanged: (val) {
                                    // LOGIKA PENTING:
                                    // Simpan teks yang diketik ke controller utama
                                    pelangganController.text = val;

                                    // Jika user mulai mengetik ulang, hapus koneksi dengan ID lama
                                    // Ini menandakan input berubah menjadi "Manual"
                                    if (selectedCustomerId != null) {
                                      setState(() {
                                        selectedCustomerId = null;
                                        currentCustomerCouponBalance = 0;
                                      });
                                    }
                                  },
                                );
                              },
                        ),
                      ),
                      const SizedBox(width: 10),

                      // 2. Tombol Tambah Pelanggan Baru (Data Lengkap)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.person_add,
                            color: Colors.white,
                          ),
                          tooltip: "Daftar Pelanggan Baru",
                          onPressed: () =>
                              _showAddCustomerSheet(context), // Munculkan Modal
                        ),
                      ),
                    ],
                  ),

                  // 3. Info Status Pelanggan
                  if (selectedCustomerId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Pelanggan Terdaftar (Kupon: $currentCustomerCouponBalance/10)",
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    )
                  else if (pelangganController.text.isNotEmpty)
                    const Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Mode Input Manual (Pelanggan Umum)",
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // --- BAGIAN PRODUK ---
                  const Text(
                    "Produk",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedProductId,
                          decoration: const InputDecoration(
                            hintText: "Pilih Produk",
                            border: OutlineInputBorder(),
                          ),
                          items: prov.masterProducts.map((p) {
                            return DropdownMenuItem<String>(
                              value: p['id'].toString(),
                              child: Text(
                                "${p['nama_produk']} (${p['ukuran']})",
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            final p = prov.masterProducts.firstWhere(
                              (item) => item['id'] == val,
                            );
                            setState(() {
                              selectedProductId = val;
                              produkController.text = p['nama_produk'];
                              ukuranController.text = p['ukuran'];

                              // SIMPAN HARGA SATUAN
                              unitPrice = p['harga'];

                              // HITUNG TOTAL: Harga Satuan * QTY
                              int qty = int.tryParse(qtyController.text) ?? 1;
                              hargaController.text = (unitPrice * qty)
                                  .toString();

                              // AMBIL NOMOR DARI PRODUK YANG DIPILIH
                              int lastNum = p['last_coupon_number'] ?? 0;
                              kuponAwalController.text = (lastNum + 1)
                                  .toString();

                              isCouponEnabled =
                                  (p['ukuran'] == '19L' ||
                                  p['is_coupon_enabled'] == true);
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add_box, color: Colors.white),
                          onPressed: () => _showAddProductSheet(context),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // FIELD QTY, UKURAN, DAN HARGA TOTAL
                  Row(
                    children: [
                      // --- INPUT QTY ---
                      Expanded(
                        flex: 1, // Lebih kecil
                        child: TextField(
                          controller: qtyController,
                          decoration: const InputDecoration(
                            labelText: "QTY",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            setState(() {
                              int qty = int.tryParse(val) ?? 0;
                              // Jika tidak sedang tukar kupon, update harga total
                              if (!useRedemption) {
                                hargaController.text = (unitPrice * qty)
                                    .toString();
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      // --- UKURAN ---
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: ukuranController,
                          decoration: const InputDecoration(
                            labelText: "Ukuran",
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) {
                            setState(() {
                              isCouponEnabled = (val.toUpperCase() == '19L');
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // --- HARGA TOTAL (OTOMATIS) ---
                  TextField(
                    controller: hargaController,
                    decoration: const InputDecoration(
                      labelText: "Total Harga",
                      border: OutlineInputBorder(),
                      prefixText: "Rp ",
                      filled: true,
                      fillColor: Color(
                        0xFFF5F5F5,
                      ), // Beri warna sedikit berbeda karena otomatis
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      // Jika admin ingin mengubah harga total secara manual (override)
                      // kita tetap izinkan, tapi unitPrice tidak berubah.
                    },
                  ),

                  const SizedBox(height: 20),

                  // --- BAGIAN KUPON ---
                  if (isCouponEnabled) ...[
                    const Text(
                      "Sistem Kupon (19L)",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // INPUT NOMOR AWAL
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: kuponAwalController,
                            decoration: const InputDecoration(
                              labelText: "No. Kupon",
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (val) => setState(
                              () {},
                            ), // Refresh UI untuk update rentang
                          ),
                        ),
                        const SizedBox(width: 10),

                        // TAMPILAN RENTANG (Otomatis menyesuaikan QTY)
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Kupon Fisik:",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  couponRangeDisplay, // Memanggil fungsi hitung tadi
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Switch Tukar Kupon tetap di bawahnya
                    if (currentCustomerCouponBalance >= 10)
                      SwitchListTile(
                        title: const Text("Tukar 10 Kupon (Gratis)"),
                        value: useRedemption,
                        onChanged: (val) {
                          setState(() {
                            useRedemption = val;
                            if (val)
                              hargaController.text = "0";
                            else {
                              int qty = int.tryParse(qtyController.text) ?? 1;
                              hargaController.text = (unitPrice * qty)
                                  .toString();
                            }
                          });
                        },
                      ),
                  ],
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        int startNum =
                            int.tryParse(kuponAwalController.text) ?? 0;
                        int qty = int.tryParse(qtyController.text) ?? 1;
                        int lastNumUsed = startNum + qty - 1;

                        final success = await prov.checkout(
                          customerId: selectedCustomerId,
                          productId: selectedProductId,
                          namaPelanggan: pelangganController.text,
                          namaProduk: produkController.text,
                          ukuran: ukuranController.text,
                          nomorKupon: lastNumUsed,
                          qty: qty, // <--- KIRIM QTY NYA
                          isRedemption: useRedemption,
                          totalHarga: int.tryParse(hargaController.text) ?? 0,
                        );

                        if (context.mounted) {
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Transaksi Berhasil!"),
                              ),
                            );
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Transaksi Gagal!"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text(
                        "SIMPAN TRANSAKSI",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showAddCustomerSheet(BuildContext context) {
    // Gunakan nama yang sudah diketik di kolom cari sebagai nama awal di form
    final nameSheetController = TextEditingController(
      text: pelangganController.text,
    );
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Agar form tidak tertutup keyboard
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Daftar Pelanggan Cepat",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: nameSheetController,
              decoration: const InputDecoration(labelText: "Nama Pelanggan"),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "No. HP / WA"),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: "Alamat"),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameSheetController.text.isEmpty) return;

                  // 1. Simpan ke Database
                  final newCust = await context
                      .read<CustomerProvider>()
                      .saveCustomer(
                        nameSheetController.text,
                        phoneController.text,
                        addressController.text,
                      );

                  if (newCust != null) {
                    // 2. Perbarui list master di transaksi
                    await context
                        .read<TransactionProvider>()
                        .refreshCustomerList();

                    // 3. Otomatis "Tempel" ke form transaksi
                    setState(() {
                      pelangganController.text = newCust['nama'];
                      selectedCustomerId = newCust['id'];
                      currentCustomerCouponBalance = 0;
                    });

                    Navigator.pop(context); // Tutup modal
                  }
                },
                child: const Text("SIMPAN & PILIH"),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showAddProductSheet(BuildContext context) {
    final nameSheetController = TextEditingController();
    final priceSheetController = TextEditingController();
    final ukuranSheetController = TextEditingController();
    // TAMBAHAN: Controller untuk nomor kupon awal produk baru
    final kuponSheetController = TextEditingController(text: '0');

    bool couponSheet = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Tambah Produk Baru",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: nameSheetController,
                decoration: const InputDecoration(
                  labelText: "Nama Produk",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: ukuranSheetController,
                decoration: const InputDecoration(
                  labelText: "Ukuran",
                  hintText: "Contoh: 19L",
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.straighten),
                ),
                onChanged: (val) {
                  setModalState(() {
                    couponSheet = (val.toUpperCase() == '19L');
                  });
                },
              ),
              const SizedBox(height: 10),

              TextField(
                controller: priceSheetController,
                decoration: const InputDecoration(
                  labelText: "Harga",
                  hintText: "Contoh: 5000",
                  border: OutlineInputBorder(),
                  prefixText: "Rp ",
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),

              CheckboxListTile(
                title: const Text("Aktifkan Kupon"),
                subtitle: const Text("Beli 10 Gratis 1"),
                value: couponSheet,
                onChanged: (val) {
                  setModalState(() => couponSheet = val!);
                },
              ),

              // TAMBAHAN: Input nomor kupon awal jika kupon aktif
              if (couponSheet)
                TextField(
                  controller: kuponSheetController,
                  decoration: const InputDecoration(
                    labelText: "Nomor Kupon Terakhir Saat Ini",
                    helperText: "Input 0 jika baru mulai buku kupon",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (nameSheetController.text.isEmpty ||
                        priceSheetController.text.isEmpty ||
                        ukuranSheetController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Harap isi semua kolom")),
                      );
                      return;
                    }

                    // PENYESUAIAN: Tambahkan parameter nomor kupon terakhir (int)
                    final newProd = await context
                        .read<ProductProvider>()
                        .saveProduct(
                          nameSheetController.text,
                          ukuranSheetController.text,
                          priceSheetController.text,
                          couponSheet,
                          int.tryParse(kuponSheetController.text) ??
                              0, // <--- Parameter baru
                        );

                    if (newProd != null) {
                      await context.read<TransactionProvider>().initForm();

                      setState(() {
                        selectedProductId = newProd['id'];
                        produkController.text = newProd['nama_produk'];
                        ukuranController.text = newProd['ukuran'];
                        unitPrice = newProd['harga'];

                        // PENYESUAIAN: Set nomor kupon awal di form transaksi
                        int lastKupon = newProd['last_coupon_number'] ?? 0;
                        kuponAwalController.text = (lastKupon + 1).toString();

                        int qty = int.tryParse(qtyController.text) ?? 1;
                        hargaController.text = (unitPrice * qty).toString();

                        isCouponEnabled =
                            (newProd['ukuran'] == '19L' ||
                            newProd['is_coupon_enabled'] == true);
                      });

                      Navigator.pop(context);
                    }
                  },
                  child: const Text("SIMPAN & PILIH"),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
