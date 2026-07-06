import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class CategorySelector extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: AppConstants.categories.where((c) => c != 'All').length,
      itemBuilder: (context, index) {
        final categories = AppConstants.categories.where((c) => c != 'All').toList();
        final category = categories[index];
        final isSelected = category == selectedCategory;
        final color = AppConstants.categoryColors[category] ?? 
                      AppConstants.categoryColors['Other']!;
        final icon = AppConstants.categoryIcons[category] ?? 
                     AppConstants.categoryIcons['Other']!;

        return GestureDetector(
          onTap: () => onCategorySelected(category),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? color : color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : color.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : color,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? Colors.white : color,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
