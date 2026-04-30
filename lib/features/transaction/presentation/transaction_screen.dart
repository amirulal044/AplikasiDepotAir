import 'package:flutter/material.dart';
import '../data/transaction_repository.dart';
import 'kasir_form_screen.dart';

class TransactionScreen extends StatefulWidget {
  final String storeId;
  const TransactionScreen({super.key, required this.storeId});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final _repo = TransactionRepository();
  List<Map<String, dynamic>> _data = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final res = await _repo.getTransactions(widget.storeId);
    setState(() { _data = res; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Riwayat Kasir")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => KasirFormScreen(storeId: widget.storeId))).then((_) => _load()),
        child: const Icon(Icons.add_shopping_cart),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _data.length,
            itemBuilder: (c, i) {
              final t = _data[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(t['customers']?['name'] ?? "Umum", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${t['custom_description']} (${t['qty']} Galon)"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Rp ${t['total_price']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => KasirFormScreen(storeId: widget.storeId, existingData: t))).then((_) => _load())),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(t['id'])),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("Hapus?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text("Batal")),
        ElevatedButton(onPressed: () async { await _repo.delete(id); Navigator.pop(c); _load(); }, child: const Text("Hapus")),
      ],
    ));
  }
}