import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/transaction_provider.dart';
import '../../customers/logic/customer_provider.dart';
import '../../products/logic/product_provider.dart';

class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({Key? key}) : super(key: key);

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  // Controller Utama
  final pelangganController = TextEditingController();
  final produkController = TextEditingController();
  final ukuranController = TextEditingController();
  final qtyController = TextEditingController(text: "1");
  final kuponAwalController = TextEditingController();
  final hargaController = TextEditingController();

  // State Variables
  String? selectedCustomerId;
  String? selectedProductId;
  int unitPrice = 0;
  int currentCustomerCouponBalance = 0;
  bool isCouponEnabled = false;
  bool isRedemptionProduct = false; // Deteksi apakah produk ini tipe hadiah

  // Helper untuk hitung rentang kupon otomatis
  String get couponRangeDisplay {
    int start = int.tryParse(kuponAwalController.text) ?? 0;
    int qty = int.tryParse(qtyController.text) ?? 0;
    if (qty <= 1) return start.toString();
    return "$start - ${start + qty - 1}";
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().initForm();
    });
  }

  // --- LOGIKA PERHITUNGAN HARGA (Poin B) ---
  void updateSubtotal() {
    int qty = int.tryParse(qtyController.text) ?? 0;
    if (isRedemptionProduct) {
      hargaController.text = "0"; // Jika produk hadiah, harga mati di Rp 0
    } else {
      hargaController.text = (unitPrice * qty).toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TransactionProvider>();

    // Hitung Proyeksi Saldo Secara Real-time
    int projectedBalance = prov.calculateProjectedBalance(
      currentCustomerCouponBalance,
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Nota Transaksi Baru")),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPelangganSection(prov, projectedBalance),
                        const Divider(height: 30),
                        _buildProductInputSection(prov),
                        const SizedBox(height: 20),
                        const Text(
                          "Daftar Belanjaan:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildCartList(prov),
                      ],
                    ),
                  ),
                ),
                _buildFooter(prov),
              ],
            ),
    );
  }

  // --- 1. SEKSI PELANGGAN (DENGAN PROYEKSI SALDO) ---
Widget _buildPelangganSection(TransactionProvider prov, int projectedBalance) {
  // 1. Cari data pelanggan yang sedang dipilih secara dinamis dari master data
  Map<String, dynamic>? selectedCustData;
  try {
    if (selectedCustomerId != null) {
      selectedCustData = prov.masterCustomers.firstWhere(
        (c) => c['id'] == selectedCustomerId,
      );
    }
  } catch (e) {
    selectedCustData = null;
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text("Pelanggan", style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),

      // --- BARIS 1: INPUT PENCARIAN & TOMBOL TAMBAH ---
      Row(
        children: [
          Expanded(
            child: Autocomplete<Map<String, dynamic>>(
              displayStringForOption: (option) => option['nama'],
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) return const Iterable.empty();
                return prov.masterCustomers.where((c) =>
                    c['nama'].toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (selection) {
                setState(() {
                  selectedCustomerId = selection['id'];
                  pelangganController.text = selection['nama'];
                  // Sesuaikan dengan nama kolom di database Anda (coupon_balance_19l)
                  currentCustomerCouponBalance = selection['coupon_balance_19l'] ?? 0;
                });
              },
              fieldViewBuilder: (ctx, ctrl, focus, onSubmit) {
                return TextField(
                  controller: ctrl..text = pelangganController.text,
                  focusNode: focus,
                  decoration: const InputDecoration(
                    hintText: "Cari/Ketik Nama Pelanggan",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (val) {
                    pelangganController.text = val;
                    // Reset ID jika admin mengetik manual (bukan pilihan autocomplete)
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
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.blue),
            onPressed: () => _showAddCustomerSheet(context),
            tooltip: "Tambah Pelanggan Baru",
          ),
        ],
      ),

      // --- BARIS 2 & 3: TAMPILAN KHUSUS JIKA PELANGGAN TERDAFTAR ---
      if (selectedCustomerId != null && selectedCustData != null) ...[
        const SizedBox(height: 12),

        // A. Statistik Pengisian Seumur Hidup (Lifelong Stats)
        const Text("Riwayat Pengisian Galon (Total):", 
            style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: (selectedCustData['total_stats'] as Map<String, dynamic>).entries.map((e) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  "${e.key}: ${e.value}x",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
          ),
        ),

        // B. Kapsul Proyeksi Saldo Kupon 19L (Real-time)
        Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: projectedBalance < 0 ? Colors.red.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(20), // Pill Shape
            border: Border.all(
              color: projectedBalance < 0 ? Colors.red.shade200 : Colors.blue.shade200,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                projectedBalance < 0 ? Icons.warning_amber_rounded : Icons.stars_rounded,
                size: 20,
                color: projectedBalance < 0 ? Colors.red : Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(
                "Kupon 19L terkumpul: ",
                style: TextStyle(
                  fontSize: 14,
                  color: projectedBalance < 0 ? Colors.red.shade900 : Colors.blue.shade900,
                ),
              ),
              Text(
                "$projectedBalance",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: projectedBalance < 0 ? Colors.red : Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ],
    ],
  );
}
  // --- 2. SEKSI INPUT PRODUK (AUTO-RESPONSE UI) ---
  Widget _buildProductInputSection(TransactionProvider prov) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Input Produk",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedProductId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    hintText: "Pilih Produk",
                    border: OutlineInputBorder(),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  items: prov.masterProducts
                      .map(
                        (p) => DropdownMenuItem(
                          value: p['id'].toString(),
                          child: Text("${p['nama_produk']} (${p['ukuran']})"),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    final p = prov.masterProducts.firstWhere(
                      (item) => item['id'] == val,
                    );
                    setState(() {
                      selectedProductId = val;
                      produkController.text = p['nama_produk'];
                      ukuranController.text = p['ukuran'];
                      unitPrice = p['harga'];

                      // LOGIKA OTOMATIS: Deteksi Produk Hadiah atau Bayar
                      isRedemptionProduct = p['is_redemption_item'] ?? false;
                      isCouponEnabled =
                          (p['ukuran'] == '19L' ||
                          p['is_coupon_enabled'] == true);

                      int lastKupon = p['last_coupon_number'] ?? 0;
                      kuponAwalController.text = (lastKupon + 1).toString();
                      updateSubtotal();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_box, color: Colors.blue),
                onPressed: () => _showAddProductSheet(context),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: qtyController,
                  decoration: const InputDecoration(
                    labelText: "QTY",
                    border: OutlineInputBorder(),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => setState(() => updateSubtotal()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: ukuranController,
                  decoration: const InputDecoration(
                    labelText: "Ukuran",
                    border: OutlineInputBorder(),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: hargaController,
            readOnly:
                isRedemptionProduct, // Poin B: Harga mati 0 jika produk hadiah
            decoration: InputDecoration(
              labelText: "Subtotal Baris Ini",
              prefixText: "Rp ",
              fillColor: isRedemptionProduct
                  ? Colors.grey.shade200
                  : Colors.white,
              filled: true,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),

          // --- SEKSI KUPON FISIK (POIN B: HILANG JIKA HADIAH) ---
          if (isCouponEnabled && !isRedemptionProduct) ...[
            const SizedBox(height: 10),
            const Text(
              "Penomoran Kupon Fisik",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: kuponAwalController,
                    decoration: const InputDecoration(
                      labelText: "No. Kupon Awal",
                      border: OutlineInputBorder(),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      "Rentang: $couponRangeDisplay",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                if (produkController.text.isEmpty) return;
                int qty = int.tryParse(qtyController.text) ?? 0;
                if (qty <= 0) return;

                int start = int.tryParse(kuponAwalController.text) ?? 0;

                final error = prov.addToCart(
                  productId: selectedProductId,
                  namaProduk: produkController.text,
                  ukuran: ukuranController.text,
                  qty: qty,
                  unitPrice: unitPrice,
                  subtotal: int.tryParse(hargaController.text) ?? 0,
                  isRedemption: isRedemptionProduct, // Otomatis dari produk
                  isCouponEnabled: isCouponEnabled,
                  kuponAwal: isRedemptionProduct ? 0 : start,
                  kuponAkhir: isRedemptionProduct ? 0 : (start + qty - 1),
                  dbBalance: currentCustomerCouponBalance,
                );

                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error), backgroundColor: Colors.red),
                  );
                } else {
                  setState(() {
                    int lastUsed = isRedemptionProduct ? start : (start + qty);
                    qtyController.text = "1";
                    kuponAwalController.text = lastUsed.toString();
                    updateSubtotal();
                  });
                }
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text("TAMBAH KE DAFTAR"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList(TransactionProvider prov) {
  if (prov.cartItems.isEmpty)
    return const Center(
      child: Text("Daftar kosong", style: TextStyle(color: Colors.grey)),
    );
  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: prov.cartItems.length,
    itemBuilder: (ctx, index) {
      final item = prov.cartItems[index];
      bool isFree = item['isRedemption'];
      
      return Card(
        // Memberi warna latar berbeda untuk barang gratis agar mudah dibedakan
        color: isFree ? Colors.green.shade50 : Colors.white,
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: Icon(
            isFree ? Icons.redeem : Icons.shopping_bag,
            color: isFree ? Colors.green : Colors.blue,
          ),
          // --- PENYESUAIAN PADA NAMA PRODUK + UKURAN ---
          title: Text(
            "${item['namaProduk']} ${item['ukuran']} (${item['qty']}x)",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            isFree
                ? "TUKAR KUPON (GRATIS)"
                : "Rp ${item['subtotal']} | Kupon: ${item['kuponAwal']}-${item['kuponAkhir']}",
            style: TextStyle(
              color: isFree ? Colors.green.shade700 : Colors.grey.shade700,
              fontSize: 12,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => prov.removeFromCart(index),
          ),
        ),
      );
    },
  );
}

  Widget _buildFooter(TransactionProvider prov) {
    int finalProjected = prov.calculateProjectedBalance(
      currentCustomerCouponBalance,
    );
    bool isInvalid = finalProjected < 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Bayar:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Rp ${prov.totalHarga}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isInvalid ? Colors.grey : Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: (prov.cartItems.isEmpty || isInvalid)
                    ? null
                    : () async {
                        final success = await prov.checkout(
                          customerId: selectedCustomerId,
                          namaPelanggan: pelangganController.text,
                        );
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Transaksi Berhasil")),
                          );
                          Navigator.pop(context);
                        }
                      },
                child: Text(
                  isInvalid ? "SALDO TIDAK CUKUP" : "PROSES TRANSAKSI",
                  style: const TextStyle(
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
                          int.tryParse(kuponSheetController.text) ?? 0,
                          false,
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
