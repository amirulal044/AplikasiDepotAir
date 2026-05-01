import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/customer_provider.dart';

class CustomerFormScreen extends StatefulWidget {
  final Map<String, dynamic>? customer;
  const CustomerFormScreen({Key? key, this.customer}) : super(key: key);

  @override
  _CustomerFormScreenState createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  late TextEditingController namaController;
  late TextEditingController tlpController;
  late TextEditingController alamatController;

  @override
  void initState() {
    super.initState();
    namaController = TextEditingController(
      text: widget.customer?['nama'] ?? '',
    );
    tlpController = TextEditingController(
      text: widget.customer?['telepon'] ?? '',
    );
    alamatController = TextEditingController(
      text: widget.customer?['alamat'] ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.customer != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Pelanggan" : "Tambah Pelanggan"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: namaController,
              decoration: const InputDecoration(
                labelText: "Nama Pelanggan",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: tlpController,
              decoration: const InputDecoration(
                labelText: "No. HP / WhatsApp",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: alamatController,
              decoration: const InputDecoration(
                labelText: "Alamat",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (namaController.text.isEmpty) return;
                  final result = await context
                      .read<CustomerProvider>()
                      .saveCustomer(
                        namaController.text,
                        tlpController.text,
                        alamatController.text,
                        id: widget.customer?['id'],
                      );

                  // SEBELUMNYA: if (success)
                  // SESUDAHNYA:
                  if (context.mounted && result != null) {
                    // Jika result tidak null, berarti sukses
                    Navigator.pop(context);
                  }
                },
                child: Text(isEdit ? "PERBARUI" : "SIMPAN"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
