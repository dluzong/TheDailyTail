import 'package:flutter/material.dart';

class MedicationFormDialog extends StatefulWidget {
  const MedicationFormDialog({super.key});

  @override
  State<MedicationFormDialog> createState() => _MedicationFormDialogState();
}

class _MedicationFormDialogState extends State<MedicationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();

  final List<String> _frequencyOptions = [
    "1x daily",
    "2x daily",
    "3x daily",
    "1x weekly",
    "2x weekly",
    "Custom"
  ];

  String? _selectedFrequency;
  final TextEditingController _customFrequencyController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Medication"),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Medication Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Medication Name"),
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter a name" : null,
              ),
              const SizedBox(height: 16),

              // Dosage Field
              TextFormField(
                controller: _dosageController,
                decoration:
                    const InputDecoration(labelText: "Dosage (e.g., 500mg)"),
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter dosage" : null,
              ),
              const SizedBox(height: 16),

              // Frequency Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Frequency"),
                value: _selectedFrequency,
                items: _frequencyOptions
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (val) {
                  setState(() => _selectedFrequency = val);
                },
                validator: (val) => val == null ? "Select frequency" : null,
              ),
              const SizedBox(height: 8),

              // Custom frequency text field
              if (_selectedFrequency == "Custom")
                TextFormField(
                  controller: _customFrequencyController,
                  decoration: const InputDecoration(
                      labelText: "Enter custom frequency"),
                  validator: (value) => _selectedFrequency == "Custom" &&
                          (value == null || value.isEmpty)
                      ? "Enter custom frequency"
                      : null,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                "name": _nameController.text,
                "dosage": _dosageController.text,
                "frequency": _selectedFrequency == "Custom"
                    ? _customFrequencyController.text
                    : _selectedFrequency,
              });
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
