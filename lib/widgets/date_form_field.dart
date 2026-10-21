import 'package:flutter/material.dart';

import '../utils/formatters.dart';

/// Date picker that works with Form validation (Section 17: valid dates).
class DateFormField extends FormField<DateTime> {
  DateFormField({
    super.key,
    required String label,
    required DateTime? initialDate,
    required ValueChanged<DateTime> onChanged,
    bool allowFuture = false,
  }) : super(
          initialValue: initialDate,
          validator: (value) {
            if (value == null) return 'Please select a date';
            if (!allowFuture && value.isAfter(dateOnly(DateTime.now()))) {
              return 'Date cannot be in the future';
            }
            return null;
          },
          builder: (field) {
            Future<void> pick() async {
              final today = dateOnly(DateTime.now());
              final first = DateTime(2000);
              final last = allowFuture ? DateTime(2100) : today;
              var initial = field.value ?? today;
              if (initial.isAfter(last)) initial = last;
              if (initial.isBefore(first)) initial = first;
              final picked = await showDatePicker(
                context: field.context,
                initialDate: initial,
                firstDate: first,
                lastDate: last,
              );
              if (picked != null) {
                field.didChange(picked);
                onChanged(picked);
              }
            }

            return InkWell(
              onTap: pick,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: label,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  errorText: field.errorText,
                ),
                child: Text(field.value == null
                    ? 'Select a date'
                    : longDate(field.value!)),
              ),
            );
          },
        );
}
