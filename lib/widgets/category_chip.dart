import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E1F22) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? const Color(0xFF1E1F22) : Colors.grey.shade200,
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF1E1F22).withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
