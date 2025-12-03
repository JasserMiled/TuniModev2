import 'package:flutter/material.dart';

class ReviewFormResult {
  final int rating;
  final String? comment;

  ReviewFormResult({required this.rating, this.comment});
}

class ReviewDialog extends StatefulWidget {
  const ReviewDialog({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  int _selectedRating = 5;
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildStar(int value) {
    final isSelected = value <= _selectedRating;
    return IconButton(
      icon: Icon(
        Icons.star,
        color: isSelected ? Colors.amber : Colors.grey.shade400,
        size: 28,
      ),
      onPressed: () {
        setState(() {
          _selectedRating = value;
        });
      },
    );
  }

  void _submit() {
    Navigator.of(context).pop(
      ReviewFormResult(
        rating: _selectedRating,
        comment: _controller.text.trim().isEmpty ? null : _controller.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.subtitle != null) ...[
              Text(widget.subtitle!),
              const SizedBox(height: 12),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => _buildStar(index + 1)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Commentaire (optionnel)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Envoyer'),
        ),
      ],
    );
  }
}
