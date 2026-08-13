import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String _bookingEndpoint =
    'https://events-dashboard-26.onrender.com/api/bookings';

class _BookingSectionDef {
  const _BookingSectionDef({
    required this.key,
    required this.title,
    required this.icon,
    required this.options,
  });

  final String key;
  final String title;
  final IconData icon;
  final List<String> options;
}

const List<_BookingSectionDef> _bookingSections = [
  _BookingSectionDef(
    key: 'vehicle',
    title: 'Vehicle',
    icon: Icons.directions_car_filled_outlined,
    options: [
      'Toyota Hiace',
      'Nissan Urvan',
      'Coaster Bus',
      'Range Rover',
      'Prado TX',
    ],
  ),
  _BookingSectionDef(
    key: 'service',
    title: 'Service',
    icon: Icons.auto_awesome_outlined,
    options: [
      'Full Event Planning',
      'Decor & Setup',
      'Photography',
      'MC & Entertainment',
    ],
  ),
  _BookingSectionDef(
    key: 'event',
    title: 'Event',
    icon: Icons.celebration_outlined,
    options: [
      'Wedding',
      'Birthday Party',
      'Corporate Event',
      'Graduation',
      'Baby Shower',
    ],
  ),
  _BookingSectionDef(
    key: 'catering',
    title: 'Catering',
    icon: Icons.restaurant_outlined,
    options: [
      'Buffet (per person)',
      'Plated Course Meal',
      'BBQ & Grills',
      'Drinks & Snacks',
    ],
  ),
];

class BookingSheet extends StatefulWidget {
  const BookingSheet({super.key, this.contactName});

  final String? contactName;

  @override
  State<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<BookingSheet> {
  final Map<String, String> _selected = {};
  final Map<String, DateTime> _bookingDate = {};
  final Map<String, int> _adults = {};
  final Map<String, int> _children = {};

  bool _submitting = false;
  bool _success = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    for (final section in _bookingSections) {
      _adults[section.key] = 1;
      _children[section.key] = 0;
    }
  }

  Future<void> _pickDate(String sectionKey) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _bookingDate[sectionKey] ??
          now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFCC471B),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFCC471B)),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _bookingDate[sectionKey] = picked);
    }
  }

  String _dateLabel(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _fmtDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  bool get _allFilled =>
      _bookingSections.every(
        (s) => _selected[s.key] != null && _bookingDate[s.key] != null,
      );

  Future<void> _confirmAndSubmit() async {
    if (!_allFilled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an option and a date for every section'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Booking'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.contactName != null) ...[
                Text(
                  'Contact: ${widget.contactName}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
              ],
              for (final section in _bookingSections) ...[
                _buildConfirmRow(
                  section: section,
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFCC471B),
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _submitBooking();
  }

  Widget _buildConfirmRow({required _BookingSectionDef section}) {
    final date = _bookingDate[section.key];
    final option = _selected[section.key];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(section.icon, size: 18, color: const Color(0xFFCD7C20)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                option ?? '-',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                '${date != null ? _dateLabel(date) : '-'}'
                ' | Adults: ${_adults[section.key]}'
                ' | Children: ${_children[section.key]}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submitBooking() async {
    setState(() {
      _submitting = true;
      _errorMessage = '';
    });
    try {
      final payload = <String, dynamic>{
        'status': 'PENDING',
        'contactName': widget.contactName,
      };
      for (final section in _bookingSections) {
        payload[section.key] = _selected[section.key];
        payload['${section.key}Date'] = _bookingDate[section.key] != null
            ? _fmtDate(_bookingDate[section.key]!)
            : null;
        payload['${section.key}Adults'] = _adults[section.key];
        payload['${section.key}Children'] = _children[section.key];
      }
      final response = await http
          .post(
            Uri.parse(_bookingEndpoint),
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => _success = true);
      } else {
        setState(() {
          _errorMessage =
              'Booking failed (${response.statusCode}). Please try again.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Could not reach the server. Please check your connection.';
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (_success) {
      return _SuccessView(
        screenWidth: screenWidth,
        screenHeight: screenHeight,
        onDone: () => Navigator.of(context).pop(),
      );
    }

    return Container(
      height: screenHeight * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: screenHeight * 0.012),
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05,
              vertical: screenHeight * 0.012,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  color: Color(0xFFCC471B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Book with ${widget.contactName ?? 'vendor'}',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, color: Colors.black54),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0E4D4)),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(screenWidth * 0.04),
              itemCount: _bookingSections.length,
              itemBuilder: (context, index) {
                final section = _bookingSections[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: screenHeight * 0.012,
                  ),
                  child: _buildSectionCard(
                    section,
                    screenWidth,
                    screenHeight,
                  ),
                );
              },
            ),
          ),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 13),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: SizedBox(
              width: double.infinity,
              height: screenHeight * 0.058,
              child: FilledButton(
                onPressed: _submitting ? null : _confirmAndSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFCC471B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Set Booking',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    _BookingSectionDef section,
    double screenWidth,
    double screenHeight,
  ) {
    final selected = _selected[section.key];
    final date = _bookingDate[section.key];
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.035),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0E4D4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(section.icon, color: const Color(0xFFCD7C20), size: 20),
              const SizedBox(width: 8),
              Text(
                section.title,
                style: TextStyle(
                  fontSize: screenWidth * 0.038,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.008),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in section.options)
                GestureDetector(
                  onTap: () => setState(() => _selected[section.key] = option),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.03,
                      vertical: screenHeight * 0.006,
                    ),
                    decoration: BoxDecoration(
                      color: selected == option
                          ? const Color(0xFFCC471B)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected == option
                            ? const Color(0xFFCC471B)
                            : const Color(0xFFE3D3C0),
                      ),
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: screenWidth * 0.03,
                        fontWeight: FontWeight.w600,
                        color: selected == option
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: screenHeight * 0.01),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: GestureDetector(
                  onTap: () => _pickDate(section.key),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.025,
                      vertical: screenHeight * 0.008,
                    ),
                    decoration: BoxDecoration(
                      color: date != null
                          ? const Color(0xFFCC471B)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: date != null
                            ? const Color(0xFFCC471B)
                            : const Color(0xFFE3D3C0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 15,
                          color: date != null
                              ? Colors.white
                              : const Color(0xFFCD7C20),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            date != null ? _dateLabel(date) : 'Pick date',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: screenWidth * 0.028,
                              fontWeight: FontWeight.w600,
                              color: date != null
                                  ? Colors.white
                                  : Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: _buildStepper(
                  label: 'Adults',
                  value: _adults[section.key]!,
                  onChanged: (v) =>
                      setState(() => _adults[section.key] = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: _buildStepper(
                  label: 'Children',
                  value: _children[section.key]!,
                  onChanged: (v) =>
                      setState(() => _children[section.key] = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepper({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3D3C0)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _smallStepperButton(
                icon: Icons.remove,
                onTap: () {
                  if (value > 0) onChanged(value - 1);
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _smallStepperButton(
                icon: Icons.add,
                onTap: () => onChanged(value + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallStepperButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: Color(0xFFF8C2B0),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 14, color: const Color(0xFFCC471B)),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.screenWidth,
    required this.screenHeight,
    required this.onDone,
  });

  final double screenWidth;
  final double screenHeight;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: screenHeight * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: screenWidth * 0.24,
            height: screenWidth * 0.24,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F7E1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Color(0xFF4CAF50),
              size: 72,
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          const Text(
            'Booking Submitted!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: screenHeight * 0.008),
          Text(
            'Your booking has been sent to ${''}. '
            'You will be notified once it is confirmed.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: screenHeight * 0.03),
          SizedBox(
            width: double.infinity,
            height: screenHeight * 0.058,
            child: FilledButton(
              onPressed: onDone,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFCC471B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
