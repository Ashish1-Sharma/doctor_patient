import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/patient_model.dart';
import '../providers/patient_provider.dart';
import '../theme/app_theme.dart';

/// Screen to create or edit a Patient profile.
class AddPatientScreen extends StatefulWidget {
  final PatientModel? patientToEdit;

  const AddPatientScreen({super.key, this.patientToEdit});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _genderController;
  late TextEditingController _dobController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;

  final List<String> _availableConditions = [
    'Diabetes',
    'Hypertension',
    'Thyroid',
    'Heart Disease',
    'Allergy',
    'Asthma',
  ];

  final Map<String, bool> _selectedConditions = {};
  int _parentId = 1;
  int _doctorId = 1;

  @override
  void initState() {
    super.initState();

    // Map selection map
    for (final condition in _availableConditions) {
      _selectedConditions[condition] = false;
    }

    final p = widget.patientToEdit;

    // Initialize text controllers pre-filling edit fields or setting defaults
    _codeController = TextEditingController(
      text: p?.patientCode ?? 'PAT${DateTime.now().millisecondsSinceEpoch ~/ 1000000}',
    );
    _nameController = TextEditingController(text: p?.fullName ?? '');
    _ageController = TextEditingController(text: p?.age != null ? p!.age.toString() : '');
    _genderController = TextEditingController(text: p?.gender ?? 'Male');
    _dobController = TextEditingController(text: p?.dateOfBirth ?? '');
    _phoneController = TextEditingController(
      text: p?.phone != null ? p!.phone.replaceFirst('+91 ', '') : '',
    );
    _emailController = TextEditingController(text: p?.email ?? '');
    _addressController = TextEditingController(text: p?.address ?? '');
    _emergencyNameController = TextEditingController(text: p?.emergencyContactName ?? '');
    _emergencyPhoneController = TextEditingController(text: p?.emergencyContactPhone ?? '');

    // Pre-populate medical conditions in edit mode
    if (p != null) {
      for (final condition in p.medicalConditions) {
        if (_availableConditions.contains(condition)) {
          _selectedConditions[condition] = true;
        }
      }
    }

    _loadDoctorId();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileStr = prefs.getString('user_profile');
      if (profileStr != null) {
        final profile = jsonDecode(profileStr);
        final rawId = profile['id'];
        final loggedInUserId = rawId is int ? rawId : (rawId != null ? int.tryParse(rawId.toString()) : null);
        final isSubUser = profile['isSubUser'] == true;
        
        final rawParentId = isSubUser 
            ? (profile['parentId'] ?? profile['mainAccountId'] ?? loggedInUserId)
            : loggedInUserId;
        final parentId = rawParentId is int ? rawParentId : (rawParentId != null ? int.tryParse(rawParentId.toString()) : null);

        if (loggedInUserId != null) {
          setState(() {
            _doctorId = loggedInUserId;
          });
        }
        if (parentId != null) {
          setState(() {
            _parentId = parentId;
          });
        }
      }
    } catch (_) {}
  }

  bool _hasUnsavedChanges() {
    final name = _nameController.text.trim();
    final ageStr = _ageController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final code = _codeController.text.trim();
    final email = _emailController.text.trim();
    final dob = _dobController.text.trim();
    final emName = _emergencyNameController.text.trim();
    final emPhone = _emergencyPhoneController.text.trim();

    final conditions = _availableConditions
        .where((condition) => _selectedConditions[condition] == true)
        .toList();

    if (widget.patientToEdit != null) {
      final p = widget.patientToEdit!;
      final nameChanged = name != p.fullName;
      final ageChanged = ageStr != p.age.toString();
      final phoneChanged = (phone.startsWith('+91') ? phone : "+91 $phone") != p.phone;
      final addressChanged = address != p.address;
      final codeChanged = code != p.patientCode;
      final emailChanged = email != p.email;
      final dobChanged = dob != p.dateOfBirth;
      final emNameChanged = emName != p.emergencyContactName;
      final emPhoneChanged = emPhone != p.emergencyContactPhone;

      final conditionsChanged = conditions.length != p.medicalConditions.length ||
          !conditions.every((c) => p.medicalConditions.contains(c));

      return nameChanged ||
          ageChanged ||
          phoneChanged ||
          addressChanged ||
          codeChanged ||
          emailChanged ||
          dobChanged ||
          emNameChanged ||
          emPhoneChanged ||
          conditionsChanged;
    } else {
      // Create mode: verify if any field has been filled out
      return name.isNotEmpty ||
          ageStr.isNotEmpty ||
          phone.isNotEmpty ||
          address.isNotEmpty ||
          email.isNotEmpty ||
          dob.isNotEmpty ||
          emName.isNotEmpty ||
          emPhone.isNotEmpty ||
          conditions.isNotEmpty;
    }
  }

  Future<bool> _showExitWarningDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Leaving this screen will discard your edits.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard', style: TextStyle(color: AppTheme.redDestructive)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<PatientProvider>(context, listen: false);
    if (provider.isLoading) return; // Prevent duplicate API requests

    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim()) ?? 0;
    final gender = _genderController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final code = _codeController.text.trim();
    final email = _emailController.text.trim();
    final dob = _dobController.text.trim();
    final emName = _emergencyNameController.text.trim();
    final emPhone = _emergencyPhoneController.text.trim();

    final conditions = _availableConditions
        .where((condition) => _selectedConditions[condition] == true)
        .toList();

    final phoneWithCode = phone.startsWith('+91') ? phone : "+91 $phone";

    final isEditMode = widget.patientToEdit != null;

    final Map<String, dynamic> payload = {
      if (isEditMode) "id": widget.patientToEdit!.id,
      "parentId": _parentId,
      "patientCode": code,
      "profileImage": "",
      "fullName": name,
      "age": age,
      "gender": gender,
      "dateOfBirth": dob.isEmpty ? "${DateTime.now().year - age}-01-01" : dob,
      "phone": phoneWithCode,
      "email": email,
      "address": address,
      "medicalConditions": conditions,
      "emergencyContactName": emName,
      "emergencyContactPhone": emPhone,
      "doctorId": _doctorId,
      if (!isEditMode) "createdBy": _doctorId,
      if (isEditMode) "status": 1,
    };

    bool success = false;
    if (isEditMode) {
      success = await provider.updatePatient(payload);
    } else {
      success = await provider.createPatient(payload);
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isEditMode ? 'Patient profile updated successfully!' : 'Patient created successfully!',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.emeraldSuccess,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.of(context).pop(true); // Return success to reload registry
    } else {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  provider.errorMessage ?? 'An error occurred during submission.',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.redDestructive,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.tealAccent,
              onPrimary: Colors.white,
              onSurface: AppTheme.primarySlate,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() {
        _dobController.text = formatted;
        // Auto calculate age
        final calculatedAge = DateTime.now().year - picked.year;
        _ageController.text = calculatedAge.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isEditMode = widget.patientToEdit != null;
    final provider = Provider.of<PatientProvider>(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!_hasUnsavedChanges()) {
          Navigator.of(context).pop();
          return;
        }
        final navigator = Navigator.of(context);
        final shouldLeave = await _showExitWarningDialog();
        if (shouldLeave == true) {
          navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            isEditMode ? 'Edit Patient Profile' : 'Add New Patient',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primarySlate),
            onPressed: () async {
              if (!_hasUnsavedChanges()) {
                Navigator.of(context).pop();
                return;
              }
              final navigator = Navigator.of(context);
              final shouldLeave = await _showExitWarningDialog();
              if (shouldLeave == true) {
                navigator.pop();
              }
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton(
                onPressed: provider.isLoading ? null : _submitForm,
                child: Text(
                  isEditMode ? 'Save' : 'Submit',
                  style: TextStyle(
                    color: provider.isLoading ? AppTheme.secondarySlate : AppTheme.tealAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [


                      // Patient Code (required)
                      Row(
                        children: [
                          Text('Patient Code', style: textTheme.labelLarge),
                          const SizedBox(width: 4),
                          const Text('*', style: TextStyle(color: AppTheme.redDestructive, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. PAT0001',
                          prefixIcon: Icon(Icons.qr_code_scanner_outlined, color: AppTheme.secondarySlate),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Patient code is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Full Name (required, min 3 characters)
                      Row(
                        children: [
                          Text('Full Name', style: textTheme.labelLarge),
                          const SizedBox(width: 4),
                          const Text('*', style: TextStyle(color: AppTheme.redDestructive, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Enter patient full name',
                          prefixIcon: Icon(Icons.person_outline, color: AppTheme.secondarySlate),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Full name is required';
                          if (val.trim().length < 3) return 'Name must be at least 3 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Age (required, range 0-120)
                      Row(
                        children: [
                          Text('Age', style: textTheme.labelLarge),
                          const SizedBox(width: 4),
                          const Text('*', style: TextStyle(color: AppTheme.redDestructive, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Enter age (0-120)',
                          prefixIcon: Icon(Icons.cake_outlined, color: AppTheme.secondarySlate),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Age is required';
                          final ageVal = int.tryParse(val.trim());
                          if (ageVal == null) return 'Age must be numeric';
                          if (ageVal < 0 || ageVal > 120) return 'Age must be between 0 and 120';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Gender Dropdown (required)
                      Row(
                        children: [
                          Text('Gender', style: textTheme.labelLarge),
                          const SizedBox(width: 4),
                          const Text('*', style: TextStyle(color: AppTheme.redDestructive, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _genderController.text,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.wc_outlined, color: AppTheme.secondarySlate),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(value: 'Female', child: Text('Female')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _genderController.text = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Date of Birth (optional picker)
                      Text('Date of Birth (Optional)', style: textTheme.labelLarge),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _dobController,
                        readOnly: true,
                        onTap: _selectDateOfBirth,
                        decoration: const InputDecoration(
                          hintText: 'Select Date of Birth',
                          prefixIcon: Icon(Icons.calendar_month_outlined, color: AppTheme.secondarySlate),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Phone Number (required, min 10 digits)
                      Row(
                        children: [
                          Text('Phone Number', style: textTheme.labelLarge),
                          const SizedBox(width: 4),
                          const Text('*', style: TextStyle(color: AppTheme.redDestructive, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: '10-digit mobile number',
                          prefixIcon: Center(
                            widthFactor: 1.0,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('+91', style: TextStyle(color: AppTheme.secondarySlate, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Phone number is required';
                          final cleanVal = val.replaceAll(RegExp(r'\D'), '');
                          if (cleanVal.length < 10) return 'Must be at least 10 digits';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email (optional, format check)
                      Text('Email Address (Optional)', style: textTheme.labelLarge),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'e.g. patient@gmail.com',
                          prefixIcon: Icon(Icons.email_outlined, color: AppTheme.secondarySlate),
                        ),
                        validator: (val) {
                          if (val != null && val.trim().isNotEmpty) {
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                              return 'Enter a valid email address';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Address (optional)
                      Text('Address (Optional)', style: textTheme.labelLarge),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Meerut, Uttar Pradesh',
                          prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.secondarySlate),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Medical Conditions Card (Multi-select chips)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Medical Conditions',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primarySlate,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _availableConditions.map((condition) {
                                final isSelected = _selectedConditions[condition] ?? false;
                                return FilterChip(
                                  label: Text(condition),
                                  selected: isSelected,
                                  onSelected: (val) {
                                    setState(() {
                                      _selectedConditions[condition] = val;
                                    });
                                  },
                                  selectedColor: AppTheme.tealAccent.withValues(alpha: 0.12),
                                  checkmarkColor: AppTheme.tealAccent,
                                  labelStyle: TextStyle(
                                    color: isSelected ? AppTheme.tealAccent : AppTheme.primarySlate,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color: isSelected ? AppTheme.tealAccent : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Emergency Contact Name (optional)
                      Text('Emergency Contact Name (Optional)', style: textTheme.labelLarge),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emergencyNameController,
                        decoration: const InputDecoration(
                          hintText: 'Name of emergency contact person',
                          prefixIcon: Icon(Icons.contact_phone_outlined, color: AppTheme.secondarySlate),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Emergency Contact Phone (optional, numbers only)
                      Text('Emergency Contact Number (Optional)', style: textTheme.labelLarge),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emergencyPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: 'Phone number of contact person',
                          prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.secondarySlate),
                        ),
                        validator: (val) {
                          if (val != null && val.trim().isNotEmpty) {
                            final clean = val.replaceAll(RegExp(r'\D'), '');
                            if (clean.isEmpty) return 'Enter a valid numeric phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),

                      // Form Submit Button
                      ElevatedButton(
                        onPressed: provider.isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.tealAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Text(
                          isEditMode ? 'Save Patient Details' : 'Create Patient Record',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Loading Overlay Indicator
            if (provider.isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.2),
                alignment: Alignment.center,
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppTheme.tealAccent),
                        const SizedBox(height: 16),
                        Text(
                          isEditMode ? 'Saving Changes...' : 'Creating Patient...',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
