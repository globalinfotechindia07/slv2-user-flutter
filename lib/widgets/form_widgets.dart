import 'package:flutter/material.dart';

// ─── Form Section ─────────────────────────────────────────────────────────────
/// Mirrors React's <FormSection> component

class FormSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const FormSection({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 20),
        ...children.map(
          (child) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: child,
          ),
        ),
      ],
    );
  }
}

// ─── Input Field ─────────────────────────────────────────────────────────────
/// Mirrors React's <InputField> component

class InputField extends StatelessWidget {
  final String label;
  final String? error;
  final String? placeholder;
  final TextInputType keyboardType;
  final String? value;
  final ValueChanged<String>? onChanged;
  final bool readOnly;

  const InputField({
    Key? key,
    required this.label,
    this.error,
    this.placeholder,
    this.keyboardType = TextInputType.text,
    this.value,
    this.onChanged,
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          keyboardType: keyboardType,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: error != null
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFE2E8F0),
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
          ),
        ),
        if (error != null && error!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    size: 14, color: Color(0xFFEF4444)),
                const SizedBox(width: 4),
                Text(
                  error!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Date Picker Field ────────────────────────────────────────────────────────
/// Renders a tap-to-pick date field (mirrors type="date" InputField in React)

class DatePickerField extends StatelessWidget {
  final String label;
  final String? error;
  final String? value;
  final ValueChanged<String>? onChanged;

  const DatePickerField({
    Key? key,
    required this.label,
    this.error,
    this.value,
    this.onChanged,
  }) : super(key: key);

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value != null && value!.isNotEmpty
          ? DateTime.tryParse(value!) ?? now
          : DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme:
                const ColorScheme.light(primary: Color(0xFFDC2626)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final formatted =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      onChanged?.call(formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _pickDate(context),
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: error != null
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFE2E8F0),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value != null && value!.isNotEmpty
                      ? value!
                      : 'Select date of birth',
                  style: TextStyle(
                    fontSize: 14,
                    color: value != null && value!.isNotEmpty
                        ? const Color(0xFF0F172A)
                        : Colors.grey.shade400,
                  ),
                ),
                Icon(Icons.calendar_today_outlined,
                    size: 18, color: Colors.grey.shade500),
              ],
            ),
          ),
        ),
        if (error != null && error!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    size: 14, color: Color(0xFFEF4444)),
                const SizedBox(width: 4),
                Text(
                  error!,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFFEF4444)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}