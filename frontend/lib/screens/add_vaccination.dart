import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VaccinationFormDialog extends StatefulWidget {
  const VaccinationFormDialog({super.key});

  @override
  State<VaccinationFormDialog> createState() => _VaccinationFormDialogState();
}

class _VaccinationFormDialogState extends State<VaccinationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  DateTime? _dateGiven;
  bool _hasNextDue = false;
  DateTime? _nextDue;

  Future<void> _pickDate(BuildContext context, bool isNextDue) async {
    const Color customColor = Color(0xFF7496B3);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),

      // 👇 Custom theme for calendar color
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: customColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.pink,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isNextDue) {
          _nextDue = picked;
        } else {
          _dateGiven = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Vaccination"),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Vaccine Name"),
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter a name" : null,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _dateGiven == null
                          ? "Date Given: Not selected"
                          : "Date Given: ${DateFormat.yMMMd().format(_dateGiven!)}",
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _pickDate(context, false),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _hasNextDue,
                    onChanged: (val) =>
                        setState(() => _hasNextDue = val ?? false),
                  ),
                  const Text("Has next due date"),
                ],
              ),
              if (_hasNextDue)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _nextDue == null
                            ? "Next Due: Not selected"
                            : "Next Due: ${DateFormat.yMMMd().format(_nextDue!)}",
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _pickDate(context, true),
                    ),
                  ],
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
            if (_formKey.currentState!.validate() && _dateGiven != null) {
              Navigator.pop(context, {
                "name": _nameController.text,
                "dateGiven": DateFormat.yMMMd().format(_dateGiven!),
                "nextDue": _hasNextDue && _nextDue != null
                    ? DateFormat.yMMMd().format(_nextDue!)
                    : null,
              });
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
