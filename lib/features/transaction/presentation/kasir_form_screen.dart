import 'package:flutter/material.dart';
import '../data/transaction_repository.dart';
import '../../product/data/product_repository.dart';
import '../../customer/data/customer_repository.dart';
import '../../customer/domain/customer_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KasirFormScreen extends StatefulWidget {
  final String storeId;
  final Map<String, dynamic>? existingData;

  const KasirFormScreen({super.key, required this.storeId, this.existingData});

  @override
  State<KasirFormScreen> createState() => _KasirFormScreenState();
}

class _KasirFormScreenState extends State<KasirFormScreen> {
  final _transRepo = TransactionRepository();
  final _prodRepo = ProductRepository();
  final _custRepo = CustomerRepository();

  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _products = [];
  
  Map<String, dynamic>? _selectedCustomer;
  Map<String, dynamic>? _selectedProduct;
  
  final _qtyController = TextEditingController(text: "1");
  final _couponController = TextEditingController();
  final _manualDescController = TextEditingController();
  final _manualPriceController = TextEditingController();
  final _manualSizeController = TextEditingController();

  // State Pelanggan
  bool _isManualCustomer = false; 
  final _manualCustNameController = TextEditingController();
  final _manualCustPhoneController = TextEditingController();
  final _manualCustAddressController = TextEditingController();
  
  String _paymentStatus = "PAID";
  bool _isManualProduct = false;
  bool _isLoading = false; 
  bool _isPageLoading = true; 

  int _nextCouponFromDb = 1; // Untuk menampung angka urutan dari tabel stores

  @override
  void initState() {
    super.initState();
    _initData();
  }

  // --- LOGIKA PENDETEKSI UKURAN (SMART GUARD) ---
  double get _currentSize {
    if (_isManualProduct) {
      return double.tryParse(_manualSizeController.text) ?? 0;
    }
    return (_selectedProduct?['size'] ?? 0).toDouble();
  }

  Future<void> _initData() async {
  try {
    // Ambil data customer & produk
    final c = await _custRepo.getCustomers(widget.storeId);
    final p = await _prodRepo.getProducts(widget.storeId);

    // Ambil data store (untuk nomor kupon terakhir)
    final storeRes = await Supabase.instance.client
        .from('stores')
        .select('next_coupon_number')
        .eq('id', widget.storeId)
        .single();

    if (mounted) {
      setState(() {
        _customers = c;
        _products = p;

        // Ambil nomor kupon dari DB
        _nextCouponFromDb = storeRes['next_coupon_number'] ?? 1;

        // ===============================
        // LOGIC EXISTING DATA (EDIT / NEW)
        // ===============================
        if (widget.existingData != null) {
          final t = widget.existingData!;

          // Data transaksi lama
          _paymentStatus = t['status'];
          _qtyController.text = t['qty'].toString();
          _couponController.text = t['coupon_serial'] ?? "";
          _manualDescController.text = t['custom_description'] ?? "";
          _manualSizeController.text = t['size_at_time'].toString();
          _manualPriceController.text = t['price_at_time'].toString();

          // Produk
          if (t['product_id'] != null) {
            _selectedProduct = _products.firstWhere(
              (e) => e['id'] == t['product_id'],
              orElse: () => {},
            );
            _isManualProduct = false;
          } else {
            _isManualProduct = true;
          }

          // Customer
          if (t['customer_id'] != null) {
            _selectedCustomer = _customers.firstWhere(
              (e) => e['id'] == t['customer_id'],
              orElse: () => {},
            );
          }

        } else {
          // ===============================
          // TRANSAKSI BARU
          // ===============================
          _couponController.text = _nextCouponFromDb.toString();
        }

        _isPageLoading = false;
      });
    }
  } catch (e) {
    debugPrint("Error Init Form: $e");
  }
}
  double get _totalHarga => _paymentStatus == "FREE" ? 0 : 
      ((_isManualProduct ? double.tryParse(_manualPriceController.text) : _selectedProduct?['price']) ?? 0).toDouble() * 
      (int.tryParse(_qtyController.text) ?? 1);

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.existingData != null;

    if (_isPageLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? "Edit Transaksi" : "Kasir Baru")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. SEKSI PELANGGAN ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Informasi Pelanggan", style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => setState(() { _isManualCustomer = !_isManualCustomer; _selectedCustomer = null; }),
                  icon: Icon(_isManualCustomer ? Icons.search : Icons.person_add),
                  label: Text(_isManualCustomer ? "Cari Lama" : "Daftar Baru"),
                ),
              ],
            ),
            if (!_isManualCustomer)
              Autocomplete<Map<String, dynamic>>(
                displayStringForOption: (option) => option['name'],
                initialValue: TextEditingValue(text: _selectedCustomer?['name'] ?? ""),
                optionsBuilder: (v) => _customers.where((c) => c['name'].toLowerCase().contains(v.text.toLowerCase())),
                onSelected: (s) => setState(() => _selectedCustomer = s),
                fieldViewBuilder: (ctx, ctrl, node, onSub) => TextField(controller: ctrl, focusNode: node, decoration: const InputDecoration(labelText: "Cari Nama...", border: OutlineInputBorder())),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
                child: Column(
                  children: [
                    TextField(controller: _manualCustNameController, decoration: const InputDecoration(labelText: "Nama Lengkap")),
                    TextField(controller: _manualCustPhoneController, decoration: const InputDecoration(labelText: "WhatsApp")),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // --- 2. SEKSI PRODUK ---
            const Text("Pilih Galon", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _isManualProduct ? "manual" : _selectedProduct?['id'],
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: [
                ..._products.map((p) => DropdownMenuItem(value: p['id'].toString(), child: Text("${p['name']} (${p['size']}L)"))),
                const DropdownMenuItem(value: "manual", child: Text("+ Ukuran Lain (Manual)", style: TextStyle(color: Colors.blue))),
              ],
              onChanged: (v) => setState(() {
                if (v == "manual") {
                  _isManualProduct = true;
                  _selectedProduct = null;
                } else {
                  _isManualProduct = false;
                  _selectedProduct = _products.firstWhere((p) => p['id'] == v);
                  _manualSizeController.text = _selectedProduct?['size'].toString() ?? "";
                  _manualPriceController.text = _selectedProduct?['price'].toString() ?? "";
                }
                // Reset status ke PAID jika ukuran bukan 19L
                if (_currentSize != 19) _paymentStatus = "PAID";
              }),
            ),

            if (_isManualProduct) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _manualSizeController, 
                decoration: const InputDecoration(labelText: "Liter (Isi 19 untuk Kupon)"), 
                keyboardType: TextInputType.number,
                onChanged: (v) => setState(() {
                   // Memicu rebuild agar logic pembayaran & kupon mendeteksi angka 19
                   if (_currentSize != 19) _paymentStatus = "PAID";
                }),
              ),
              TextField(controller: _manualPriceController, decoration: const InputDecoration(labelText: "Harga Satuan"), keyboardType: TextInputType.number, onChanged: (v) => setState((){})),
              TextField(controller: _manualDescController, decoration: const InputDecoration(labelText: "Keterangan")),
            ],

            const SizedBox(height: 16),

            // --- 3. JUMLAH & STATUS PEMBAYARAN (DINAMIS) ---
            Row(
              children: [
                Expanded(child: TextField(controller: _qtyController, decoration: const InputDecoration(labelText: "Jumlah", border: OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v)=>setState((){}))),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _paymentStatus,
                    decoration: const InputDecoration(labelText: "Tipe", border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(value: "PAID", child: Text("Tunai")),
                      // OPSI GRATIS HANYA MUNCUL JIKA UKURAN 19 LITER
                      if (_currentSize == 19)
                        const DropdownMenuItem(value: "FREE", child: Text("Gratis (10+1)")),
                    ],
                    onChanged: (v) => setState(() => _paymentStatus = v!),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

           // --- 4. INPUT KUPON (HANYA JIKA 19L & PAID) ---
            if (_currentSize == 19 && _paymentStatus == "PAID")
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "NOMOR SERI KUPON (19L)",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _couponController,
                      keyboardType: TextInputType.number, // Keyboard angka
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
                      decoration: const InputDecoration(
                        hintText: "Contoh: 101",
                        prefixIcon: Icon(Icons.confirmation_num, color: Colors.red),
                        helperText: "Nomor otomatis urut. Bisa diedit manual.",
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            
            // TOTAL DISPLAY
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text("TOTAL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text("Rp ${_totalHarga.toStringAsFixed(0)}", style: const TextStyle(color: Colors.greenAccent, fontSize: 22, fontWeight: FontWeight.bold)),
              ]),
            ),

            const SizedBox(height: 20),

            // BUTTON SIMPAN
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
              onPressed: _isLoading ? null : () async {
                setState(() => _isLoading = true);
                try {
                  String? finalCustomerId = _selectedCustomer?['id'];

                  // Logic daftar pelanggan baru otomatis
                  if (_isManualCustomer) {
                    if (_manualCustNameController.text.isEmpty) throw "Nama wajib diisi!";
                    final newCustomer = await _custRepo.addCustomer(CustomerModel(
                      storeId: widget.storeId,
                      name: _manualCustNameController.text,
                      phone: _manualCustPhoneController.text,
                    ));
                    finalCustomerId = newCustomer.id;
                  }

                  if (finalCustomerId == null) throw "Tentukan Pelanggan!";

                  final payload = {
                    'store_id': widget.storeId,
                    'customer_id': finalCustomerId,
                    'product_id': _isManualProduct ? null : _selectedProduct?['id'],
                    'qty': int.parse(_qtyController.text),
                    'total_price': _totalHarga,
                    'status': _paymentStatus,
                    'size_at_time': _currentSize,
                    'price_at_time': _isManualProduct ? double.parse(_manualPriceController.text) : _selectedProduct?['price'],
                    'custom_description': _isManualProduct ? _manualDescController.text : _selectedProduct?['name'],
                    'coupon_serial': _paymentStatus == "FREE" ? null : _couponController.text,
                  };
                  
                  // ... di dalam ElevatedButton (onPressed) ...
                  if (isEdit) {
                    await _transRepo.update(widget.existingData!['id'], payload);
                  } else {
                    await _transRepo.create(payload);

                    // BARU: Jika galon 19L & Tunai, naikkan urutan nomor kupon di tabel stores
                    if (_currentSize == 19 && _paymentStatus == "PAID") {
                      int currentInput = int.tryParse(_couponController.text) ?? _nextCouponFromDb;
                      await Supabase.instance.client
                          .from('stores')
                          .update({'next_coupon_number': currentInput + 1})
                          .eq('id', widget.storeId);
                    }
                  }
                  if(mounted) Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
                } finally {
                  if(mounted) setState(() => _isLoading = false);
                }
              },
              child: Text(isEdit ? "PERBARUI" : "SIMPAN TRANSAKSI"),
            )),
          ],
        ),
      ),
    );
  }
}