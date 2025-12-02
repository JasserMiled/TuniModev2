import 'package:flutter/material.dart';
import '../models/listing.dart';
import '../services/api_service.dart';

class OrderForm extends StatefulWidget {
  final Listing listing;
  const OrderForm({super.key, required this.listing});

  @override
  State<OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  final _formKey = GlobalKey<FormState>();
  int _quantity = 1;
  String _receptionMode = 'retrait';
  String? _selectedColor;
  String? _selectedSize;
  String? _buyerNote;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _phoneCtrl;
  String? _errorMessage;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _addressCtrl = TextEditingController(text: ApiService.currentUser?.address ?? '');
    _phoneCtrl = TextEditingController(text: ApiService.currentUser?.phone ?? '');

    if (widget.listing.colors.isNotEmpty) {
      _selectedColor = widget.listing.colors.first;
    }
    if (widget.listing.sizes.isNotEmpty) {
      _selectedSize = widget.listing.sizes.first;
    }
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await ApiService.createOrder(
        listingId: widget.listing.id,
        quantity: _quantity,
        receptionMode: _receptionMode,
        color: _selectedColor,
        size: _selectedSize,
        shippingAddress: _receptionMode == 'livraison' ? _addressCtrl.text.trim() : null,
        phone: _receptionMode == 'livraison' ? _phoneCtrl.text.trim() : null,
        buyerNote: _buyerNote,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commande envoyée avec succès.')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Nouvelle commande', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Stock: ${widget.listing.stock}')
                ],
              ),
              const SizedBox(height: 12),
              if (widget.listing.colors.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedColor,
                  decoration: const InputDecoration(labelText: 'Couleur'),
                  items: widget.listing.colors
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedColor = v),
                  validator: (v) => (v == null || v.isEmpty) ? 'Choisissez une couleur' : null,
                ),
              if (widget.listing.sizes.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedSize,
                  decoration: const InputDecoration(labelText: 'Taille'),
                  items: widget.listing.sizes
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedSize = v),
                  validator: (v) => (v == null || v.isEmpty) ? 'Choisissez une taille' : null,
                ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: '1',
                decoration: const InputDecoration(labelText: 'Quantité'),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final parsed = int.tryParse(v) ?? 1;
                  setState(() {
                    _quantity = parsed > 0 ? parsed : 1;
                  });
                },
                validator: (v) {
                  final parsed = int.tryParse(v ?? '');
                  if (parsed == null || parsed < 1) {
                    return 'Quantité minimale : 1';
                  }
                  if (parsed > widget.listing.stock && widget.listing.stock > 0) {
                    return 'Stock disponible insuffisant';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              const Text('Mode de réception'),
              RadioListTile<String>(
                value: 'retrait',
                groupValue: _receptionMode,
                onChanged: (v) => setState(() => _receptionMode = v ?? 'retrait'),
                title: const Text('Retrait'),
              ),
              RadioListTile<String>(
                value: 'livraison',
                groupValue: _receptionMode,
                onChanged: (v) => setState(() => _receptionMode = v ?? 'livraison'),
                title: const Text('Livraison'),
              ),
              if (_receptionMode == 'livraison') ...[
                TextFormField(
                  controller: _addressCtrl,
                  decoration: InputDecoration(
                    labelText: 'Adresse complète',
                    suffixIcon: ApiService.currentUser?.address?.isNotEmpty == true
                        ? TextButton(
                            onPressed: () => setState(() {
                              _addressCtrl.text = ApiService.currentUser!.address!;
                            }),
                            child: const Text('Utiliser profil'),
                          )
                        : null,
                  ),
                  maxLines: 2,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Adresse obligatoire pour une livraison'
                      : null,
                ),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: InputDecoration(
                    labelText: 'Téléphone',
                    suffixIcon: ApiService.currentUser?.phone?.isNotEmpty == true
                        ? TextButton(
                            onPressed: () => setState(() {
                              _phoneCtrl.text = ApiService.currentUser!.phone!;
                            }),
                            child: const Text('Utiliser profil'),
                          )
                        : null,
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Téléphone obligatoire pour la livraison'
                      : null,
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Note au vendeur (optionnel)'),
                maxLines: 2,
                onSaved: (v) => _buyerNote = v?.trim(),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 12),
              _submitting
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.shopping_cart_checkout),
                      label: const Text('Valider la commande'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
