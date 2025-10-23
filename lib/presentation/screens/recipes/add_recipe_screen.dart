import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// import 'package:image_picker/image_picker.dart'; // Disabled for macOS compatibility
import 'package:shoply/core/constants/app_colors.dart';
import 'package:shoply/core/constants/app_dimensions.dart';
import 'package:shoply/core/constants/app_text_styles.dart';
import 'package:shoply/data/models/recipe.dart';
import 'package:shoply/data/services/recipe_service.dart';

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipeService = RecipeService();
  // final _imagePicker = ImagePicker(); // Disabled for macOS compatibility

  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _cookTimeController = TextEditingController();
  final _servingsController = TextEditingController(text: '4');

  File? _selectedImage;
  String? _imageUrl;
  bool _isLoading = false;

  final List<_IngredientInput> _ingredients = [_IngredientInput()];
  final List<TextEditingController> _instructionControllers = [TextEditingController()];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _servingsController.dispose();
    for (var controller in _instructionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Recipe'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveRecipe,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          children: [
            // Image Picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  image: _selectedImage != null
                      ? DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _selectedImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text('Add Photo', style: TextStyle(color: Colors.grey[600])),
                        ],
                      )
                    : null,
              ),
            ),

            const SizedBox(height: AppDimensions.spacingLarge),

            // Recipe Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Recipe Name *',
                hintText: 'e.g., Spaghetti Carbonara',
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),

            const SizedBox(height: AppDimensions.spacingMedium),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Brief description of your recipe',
              ),
              maxLines: 3,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),

            const SizedBox(height: AppDimensions.spacingMedium),

            // Time & Servings Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _prepTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Prep Time (min) *',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cookTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Cook Time (min) *',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _servingsController,
                    decoration: const InputDecoration(
                      labelText: 'Servings *',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.spacingLarge),

            // Ingredients Section
            Row(
              children: [
                Text('Ingredients', style: AppTextStyles.h3),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => _ingredients.add(_IngredientInput())),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingSmall),
            ..._ingredients.asMap().entries.map((entry) {
              final index = entry.key;
              final ingredient = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: ingredient.nameController,
                        decoration: const InputDecoration(
                          hintText: 'Ingredient',
                          isDense: true,
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: ingredient.amountController,
                        decoration: const InputDecoration(
                          hintText: 'Amount',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: ingredient.unitController,
                        decoration: const InputDecoration(
                          hintText: 'Unit',
                          isDense: true,
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                    if (_ingredients.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () => setState(() => _ingredients.removeAt(index)),
                      ),
                  ],
                ),
              );
            }),

            const SizedBox(height: AppDimensions.spacingLarge),

            // Instructions Section
            Row(
              children: [
                Text('Instructions', style: AppTextStyles.h3),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => _instructionControllers.add(TextEditingController())),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingSmall),
            ..._instructionControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controller = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: AppColors.info,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: 'Instruction step',
                        ),
                        maxLines: 2,
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                    if (_instructionControllers.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () => setState(() => _instructionControllers.removeAt(index)),
                      ),
                  ],
                ),
              );
            }),

            const SizedBox(height: AppDimensions.spacingLarge),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    // Image picker disabled for macOS compatibility
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image picker not available on macOS')),
    );
    // final XFile? image = await _imagePicker.pickImage(
    //   source: ImageSource.gallery,
    //   maxWidth: 1920,
    //   maxHeight: 1080,
    //   imageQuality: 85,
    // );
    //
    // if (image != null) {
    //   setState(() => _selectedImage = File(image.path));
    // }
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a photo')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Validate numbers
      final prepTime = int.tryParse(_prepTimeController.text.trim());
      final cookTime = int.tryParse(_cookTimeController.text.trim());
      final servings = int.tryParse(_servingsController.text.trim());

      if (prepTime == null || cookTime == null || servings == null) {
        throw Exception('Please enter valid numbers for time and servings');
      }

      // Validate ingredients
      final ingredients = <Ingredient>[];
      for (var ing in _ingredients) {
        final name = ing.nameController.text.trim();
        final amountStr = ing.amountController.text.trim();
        final unit = ing.unitController.text.trim();
        
        if (name.isEmpty || amountStr.isEmpty || unit.isEmpty) {
          throw Exception('Please fill all ingredient fields');
        }
        
        final amount = double.tryParse(amountStr);
        if (amount == null) {
          throw Exception('Invalid amount for ingredient: $name');
        }
        
        ingredients.add(Ingredient(
          name: name,
          amount: amount,
          unit: unit,
        ));
      }

      // Validate instructions
      final instructions = _instructionControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();
      
      if (instructions.isEmpty) {
        throw Exception('Please add at least one instruction');
      }

      // Upload image
      final imageUrl = await _recipeService.uploadRecipeImage(
        _selectedImage!.path,
        'recipe_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Create recipe
      final recipe = Recipe(
        id: '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: imageUrl,
        prepTimeMinutes: prepTime,
        cookTimeMinutes: cookTime,
        defaultServings: servings,
        ingredients: ingredients,
        instructions: instructions,
        authorId: '',
        authorName: '',
        createdAt: DateTime.now(),
      );

      await _recipeService.createRecipe(recipe);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe added successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}

class _IngredientInput {
  final nameController = TextEditingController();
  final amountController = TextEditingController();
  final unitController = TextEditingController();

  void dispose() {
    nameController.dispose();
    amountController.dispose();
    unitController.dispose();
  }
}
