import 'package:flutter/material.dart';

class OrderRequestsScreen extends StatelessWidget {
  const OrderRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes demandes de commandes')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Gérez ici vos demandes de commandes reçues. Cette page sera enrichie prochainement.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
