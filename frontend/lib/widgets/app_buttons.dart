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
      child: HoverShadow(
        borderRadius: BorderRadius.circular(5),
        normalShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        hoverShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 16, // ✅ augmente au hover
            offset: const Offset(0, 10),
          ),
        ],
        child: Container(
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
      child: HoverShadow(
        borderRadius: BorderRadius.circular(5),
        normalShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        hoverShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(5),
            onTap: onPressed,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: const Color(0xFF0B5ED7).withOpacity(0.35),
                  width: 1.2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF0B5ED7),
                  fontWeight: FontWeight.w600,
                ),
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
    this.height = 32,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: HoverShadow(
        borderRadius: BorderRadius.circular(5),
        normalShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        hoverShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 12,
            offset: const Offset(0, 7),
          ),
        ],
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            side: const BorderSide(
              color: Color(0xFFFF8A00),
              width: 1.5,
            ),
            backgroundColor: const Color(0xFFF2F4F7),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFFF8A00),
              fontSize: 15,
            ),
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
      child: HoverShadow(
        borderRadius: BorderRadius.circular(5),
        normalShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.30),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        hoverShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.50),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
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
      ),
    );
  }
}


class HoverShadow extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final List<BoxShadow> normalShadow;
  final List<BoxShadow> hoverShadow;

  const HoverShadow({
    super.key,
    required this.child,
    required this.borderRadius,
    required this.normalShadow,
    required this.hoverShadow,
  });

  @override
  State<HoverShadow> createState() => _HoverShadowState();
}

class _HoverShadowState extends State<HoverShadow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          boxShadow: _hovered
              ? widget.hoverShadow
              : widget.normalShadow,
        ),
        child: widget.child,
      ),
    );
  }
}

