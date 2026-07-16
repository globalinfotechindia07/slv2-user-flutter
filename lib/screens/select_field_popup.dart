import 'package:flutter/material.dart';

// - Trigger input showing selected value or "Select {label}"
// - Red border on error with AlertCircle + error message
// - Bottom sheet popup sliding up from bottom (slideUp animation)
// - Dark overlay (bg-black/40) with fade-in
// - Options list with red highlight + checkmark on selected
// - Close button (X) in popup header
// - Closes on outside tap

class SelectFieldPopup extends StatefulWidget {
  final String label;
  final List<SelectOption> options;
  final String? value;
  final String? error;
  final ValueChanged<String?> onChange;

  const SelectFieldPopup({
    super.key,
    required this.label,
    required this.options,
    required this.onChange,
    this.value,
    this.error,
  });

  @override
  State<SelectFieldPopup> createState() => _SelectFieldPopupState();
}

class _SelectFieldPopupState extends State<SelectFieldPopup> {
  String? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.value;
  }

  @override
  void didUpdateWidget(SelectFieldPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      setState(() => _selectedValue = widget.value);
    }
  }

  String get _displayText {
    if (_selectedValue == null) return 'Select ${widget.label}';
    return widget.options
            .firstWhere(
              (o) => o.value == _selectedValue,
              orElse: () => SelectOption(value: '', label: 'Select ${widget.label}'),
            )
            .label;
  }

  void _openPopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.40), // bg-black/40
      builder: (_) => _SelectPopupSheet(
        label: widget.label,
        options: widget.options,
        selectedValue: _selectedValue,
        onSelect: (val) {
          setState(() => _selectedValue = val);
          widget.onChange(val);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null && widget.error!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label — text-sm font-medium text-slate-700
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),

        // Trigger input
        GestureDetector(
          onTap: _openPopup,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                // error → red-500, default → slate-200
                color: hasError
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFE2E8F0),
                width: 2,
              ),
              boxShadow: hasError
                  ? [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withOpacity(0.10),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _displayText,
                  style: TextStyle(
                    fontSize: 15,
                    color: _selectedValue == null
                        ? const Color(0xFF94A3B8) // placeholder
                        : const Color(0xFF0F172A), // selected
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),

        // Error message — flex items-center text-red-500
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline,
                  size: 16, color: Color(0xFFEF4444)),
              const SizedBox(width: 4),
              Text(
                widget.error!,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Bottom Sheet Popup ────────────────────────────────────────────────────────
// rounded-t-2xl bg-white shadow-2xl p-6 max-h-[80vh] overflow-y-auto
// slideUp 0.4s ease-out animation (handled by showModalBottomSheet)

class _SelectPopupSheet extends StatelessWidget {
  final String label;
  final List<SelectOption> options;
  final String? selectedValue;
  final ValueChanged<String> onSelect;

  const _SelectPopupSheet({
    required this.label,
    required this.options,
    required this.selectedValue,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80, // max-h-[80vh]
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)), // rounded-t-2xl
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header — flex justify-between items-center mb-4
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A), // text-slate-900
                  ),
                ),
                // Close button — X icon
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.close,
                      size: 24,
                      color: Color(0xFF64748B), // text-slate-500
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Options list — space-y-2, scrollable
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (_, i) {
                final opt = options[i];
                final isSelected = selectedValue == opt.value;
                return GestureDetector(
                  onTap: () => onSelect(opt.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12), // p-3
                    decoration: BoxDecoration(
                      // selected → bg-red-50, default → white hover:bg-slate-50
                      color: isSelected
                          ? const Color(0xFFFEF2F2) // bg-red-50
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12), // rounded-xl
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          opt.label,
                          style: TextStyle(
                            fontSize: 15,
                            color: isSelected
                                ? const Color(0xFFDC2626) // text-red-600
                                : const Color(0xFF0F172A),
                            fontWeight: isSelected
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                        // Checkmark on selected
                        if (isSelected)
                          const Icon(
                            Icons.check,
                            size: 20,
                            color: Color(0xFFDC2626), // text-red-600
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── SelectOption model ────────────────────────────────────────────────────────

class SelectOption {
  final String value;
  final String label;
  const SelectOption({required this.value, required this.label});
}