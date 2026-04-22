import 'package:flutter/material.dart';
import '../data/customer_repository.dart';
import '../domain/customer_model.dart';

class CustomerScreen extends StatefulWidget {
  final String storeId;
  const CustomerScreen({super.key, required this.storeId});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final _repo = CustomerRepository();
  final _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _allCustomers = [];
  List<Map<String, dynamic>> _filteredCustomers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  // --- 1. Ambil Data dari Database ---
  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repo.getCustomers(widget.storeId);
      setState(() {
        _allCustomers = data;
        _filteredCustomers = data; // Awalnya filtered sama dengan all
      });
    } catch (e) {
      _showSnackBar("Gagal memuat: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. Logika Pencarian Real-time ---
  void _runFilter(String enteredKeyword) {
    List<Map<String, dynamic>> results = [];
    if (enteredKeyword.isEmpty) {
      results = _allCustomers;
    } else {
      results = _allCustomers
          .where((user) =>
              user["name"].toLowerCase().contains(enteredKeyword.toLowerCase()) ||
              (user["phone"] ?? "").contains(enteredKeyword))
          .toList();
    }

    setState(() {
      _filteredCustomers = results;
    });
  }

  // --- 3. Dialog Form (Tambah & Edit) ---
  void _openCustomerForm([Map<String, dynamic>? existingCustomer]) {
    final bool isEdit = existingCustomer != null;
    final nameController = TextEditingController(text: isEdit ? existingCustomer['name'] : "");
    final phoneController = TextEditingController(text: isEdit ? existingCustomer['phone'] : "");
    final addressController = TextEditingController(text: isEdit ? existingCustomer['address'] : "");
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? "Edit Pelanggan" : "Tambah Pelanggan Baru"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nama Lengkap")),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: "No. WhatsApp"), keyboardType: TextInputType.phone),
                TextField(controller: addressController, decoration: const InputDecoration(labelText: "Alamat (Opsional)")),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (nameController.text.isEmpty) {
                  _showSnackBar("Nama wajib diisi!", Colors.orange);
                  return;
                }
                setDialogState(() => isSaving = true);
                try {
                  final model = CustomerModel(
                    id: isEdit ? existingCustomer['id'] : null,
                    storeId: widget.storeId,
                    name: nameController.text,
                    phone: phoneController.text,
                    address: addressController.text,
                  );

                  if (isEdit) {
                    await _repo.updateCustomer(model);
                  } else {
                    await _repo.addCustomer(model);
                  }

                  Navigator.pop(context);
                  _loadCustomers();
                  _showSnackBar("Berhasil!", Colors.green);
                } catch (e) {
                  _showSnackBar("Error: $e", Colors.red);
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

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Pelanggan?"),
        content: Text("Hapus data $name? Semua histori transaksinya akan menjadi 'Tanpa Nama'."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              await _repo.deleteCustomer(id);
              Navigator.pop(context);
              _loadCustomers();
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          )
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
      appBar: AppBar(title: const Text("Data Pelanggan")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCustomerForm(),
        child: const Icon(Icons.person_add),
      ),
      body: Column(
        children: [
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _runFilter(value),
              decoration: InputDecoration(
                labelText: 'Cari Nama atau No. HP...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _runFilter('');
                  },
                ),
              ),
            ),
          ),

          // LIST PELANGGAN
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCustomers.isEmpty
                    ? const Center(child: Text("Pelanggan tidak ditemukan."))
                    : ListView.builder(
                        itemCount: _filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final c = _filteredCustomers[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: const CircleAvatar(
                                backgroundColor: Colors.blueAccent,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              title: Text(
                                c['name'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              // MENAMPILKAN NO HP DAN ALAMAT
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone, size: 14, color: Colors.grey),
                                      const SizedBox(width: 5),
                                      Text(c['phone'] ?? "No HP Kosong", style: const TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          c['address'] ?? "Alamat belum diisi",
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                          maxLines: 2, // Agar tidak terlalu panjang jika alamat detail
                                          overflow: TextOverflow.ellipsis, // Memberi titik-titik jika teks terpotong
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _openCustomerForm(c),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _confirmDelete(c['id'], c['name']),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}