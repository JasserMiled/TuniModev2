import 'package:flutter/material.dart';

/// ✅ BOUTON PRINCIPAL (Appliquer, Continuer, Valider)
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A7CFF),
              Color(0xFF0B5ED7),
            ],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(5),
            onTap: onPressed,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ✅ BOUTON SECONDAIRE (Annuler, Retour)
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double height;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(5),
          onTap: onPressed,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEFF3F8),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: const Color(0xFF1A7CFF).withOpacity(0.35),
                width: 1.2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1A7CFF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class OutlinedActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double height;

  const OutlinedActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 32, // ✅ même hauteur que ton bouton Réinitialiser
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5), // ✅ ultra arrondi
          ),
          side: const BorderSide(
            color: Color(0xFFFF8A00), // ✅ contour ORANGE
            width: 1.5,
          ),
          backgroundColor: const Color(0xFFF2F4F7), // ✅ fond GRIS CLAIR
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFFF8A00), // ✅ texte ORANGE
            fontSize: 15,
            
          ),
        ),
      ),
    );
  }
}


/// ✅ BOUTON DANGEREUX (Supprimer, Bloquer)
class DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double height;

  const DangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(5),
          onTap: onPressed,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F),
              borderRadius: BorderRadius.circular(5),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
