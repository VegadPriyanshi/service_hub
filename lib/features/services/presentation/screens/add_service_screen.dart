
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/service_repository.dart';
import '../../domain/service_model.dart';

class AddServiceScreen extends StatefulWidget {
  const AddServiceScreen({
    super.key,
    this.service,
  });

  final ServiceModel? service;

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  final ServiceRepository _repository = ServiceRepository();

  String _selectedCategory = 'Cleaning';
  int _selectedDuration = 60;
  bool _isLoading = false;
  bool _isActive = true;

  final List<String> _categories = const [
    'Cleaning',
    'Plumbing',
    'Electrical',
    'Painting',
    'Carpentry',
    'Appliance Repair',
    'Other',
  ];

  bool get _isEditing => widget.service != null;

  @override
  void initState() {
    super.initState();

    final service = widget.service;

    if (service != null) {
      _nameController.text = service.name;
      _descriptionController.text = service.description;
      _priceController.text = service.price.toString();
      _selectedCategory = service.category;
      _selectedDuration = service.durationMinutes;
      _isActive = service.isActive;

      // Ensure an existing category remains selectable.
      if (!_categories.contains(_selectedCategory)) {
        _categories.add(_selectedCategory);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveService() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please login before saving a service.');
      return;
    }

    final existingService = widget.service;

    // Do not allow editing another provider's service.
    if (existingService != null &&
        existingService.providerId != user.uid) {
      _showMessage('You can only edit your own services.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = ServiceModel(
        id: existingService?.id ?? '',
        providerId: existingService?.providerId ?? user.uid,
        name: _nameController.text.trim(),
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        durationMinutes: _selectedDuration,
        isActive: _isActive,
      );

      if (_isEditing) {
        await _repository.updateService(service);
      } else {
        await _repository.addService(service);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Service updated successfully!'
                : 'Service added successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('permission-denied')
                ? 'Permission denied. Please check Firestore rules.'
                : _isEditing
                ? 'Unable to update service. Please try again.'
                : 'Unable to add service. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E5EF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E5EF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Service' : 'Add a Service'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.primary,
                      Color(0xFF8174F5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.home_repair_service_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isEditing
                          ? 'Update Your Service'
                          : 'Showcase Your Service',
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isEditing
                          ? 'Keep your service information accurate and up to date.'
                          : 'Add clear details so customers know exactly what you offer.',
                      style: const TextStyle(
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Service Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration(
                  label: 'Service Name',
                  hint: 'e.g. Deep Home Cleaning',
                  icon: Icons.home_repair_service_outlined,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a service name.';
                  }

                  if (value.trim().length < 3) {
                    return 'Name must contain at least 3 characters.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                isExpanded: true,
                decoration: _inputDecoration(
                  label: 'Category',
                  icon: Icons.category_outlined,
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDecoration(
                  label: 'Description',
                  hint: 'Describe what your service includes...',
                  icon: Icons.description_outlined,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description.';
                  }

                  if (value.trim().length < 10) {
                    return 'Description must contain at least 10 characters.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _inputDecoration(
                  label: 'Price (₹)',
                  hint: 'e.g. 499',
                  icon: Icons.currency_rupee_rounded,
                ),
                validator: (value) {
                  final price = double.tryParse(value?.trim() ?? '');

                  if (price == null ||
                      !price.isFinite ||
                      price <= 0) {
                    return 'Enter a valid price greater than ₹0.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 22),

              const Text(
                'Estimated Duration',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [30, 60, 90, 120].map((minutes) {
                  final selected = _selectedDuration == minutes;

                  return ChoiceChip(
                    label: Text(
                      minutes < 60
                          ? '$minutes min'
                          : '${minutes ~/ 60} hr${minutes >= 120 ? 's' : ''}',
                    ),
                    selected: selected,
                    onSelected: _isLoading
                        ? null
                        : (_) {
                      setState(() => _selectedDuration = minutes);
                    },
                    selectedColor:
                    AppColors.primary.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.primary,
                  );
                }).toList(),
              ),

              if (_isEditing) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Service Active',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      _isActive
                          ? 'Customers can book this service.'
                          : 'Customers cannot book this service.',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    value: _isActive,
                    activeThumbColor: AppColors.primary,
                    onChanged: _isLoading
                        ? null
                        : (value) {
                      setState(() => _isActive = value);
                    },
                  ),
                ),
              ],

              const SizedBox(height: 30),

              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveService,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 23,
                    height: 23,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    _isEditing
                        ? 'Update Service'
                        : 'Save Service',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
