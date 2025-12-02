import 'package:flutter/material.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes commandes')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Vos commandes récentes apparaîtront ici. Cette section sera bientôt disponible.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
