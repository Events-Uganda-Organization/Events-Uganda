import 'dart:ui';
import 'package:events_uganda/Users/Customers/Customer_Profile_Screen.dart';
import 'package:flutter/material.dart';
import 'package:events_uganda/components/Bottom_Navbar.dart';
import 'package:events_uganda/Auth/auth_service.dart';
import 'package:events_uganda/Users/Booking_Details_Screen.dart';

class DateOfBookingScreen extends StatefulWidget {
  final int? categoryIndex;

  const DateOfBookingScreen({super.key , this.categoryIndex});
  @override
  State<DateOfBookingScreen> createState() => _DateOfBookingScreenState();
}

class _DateOfBookingScreenState extends State<DateOfBookingScreen>
    with SingleTickerProviderStateMixin {
  int _currentNavIndex = 0;
  String _userFullName = '';
  bool _canForwardReturn = false;
  late DateTime _currentMonth;
  Set<DateTime> _unavailableDates = {};
  TimeOfDay? _fromTime;
  TimeOfDay? _toTime;
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  final List<String> _dayHeaders = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  
  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    final today = DateTime.now();
    _unavailableDates = {
      DateTime(today.year, today.month, today.day + 2),
      DateTime(today.year, today.month, today.day + 5),
      DateTime(today.year, today.month, today.day + 7),
      DateTime(today.year, today.month, today.day + 10),
      DateTime(today.year, today.month, today.day + 12),
    };
    AuthService.getUser().then((userData) {
      if (mounted) {
        setState(() {
          _userFullName = userData?['fullName'] as String? ?? 'User';
        });
      }
    });
  }

  String get _greetingText {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  Widget _buildTimeColumn(double screenWidth, String label, TimeOfDay? selectedTime, {required VoidCallback onTap}) {
    final displayTime = selectedTime != null
        ? _formatTimeOfDay(selectedTime)
        : label == 'From' ? '09:00 AM' : '10:00 AM';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            fontSize: screenWidth * 0.03,
          ),
        ),
        SizedBox(height: screenWidth * 0.015),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.03,
              vertical: screenWidth * 0.025,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  displayTime,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: screenWidth * 0.035,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  Icons.access_time_rounded,
                  color: const Color(0xFFCB471B),
                  size: screenWidth * 0.04,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final hour = t.hourOfPeriod.toString().padLeft(2, '0');
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _formatTimeRange() {
    if (_fromTime != null && _toTime != null) {
      return '${_formatTimeOfDay(_fromTime!)} - ${_formatTimeOfDay(_toTime!)}';
    } else if (_fromTime != null) {
      return 'From: ${_formatTimeOfDay(_fromTime!)}';
    }
    return 'Select your time range';
  }

  Future<void> _pickTime(bool isFrom) async {
    final initial = isFrom ? (_fromTime ?? const TimeOfDay(hour: 9, minute: 0)) : (_toTime ?? const TimeOfDay(hour: 10, minute: 0));
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: isFrom ? 'Select From Time' : 'Select To Time',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFCB471B),
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          ),
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromTime = picked;
        } else {
          _toTime = picked;
        }
      });
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isUnavailable(DateTime day) {
    return _unavailableDates.any((d) => _isSameDay(d, day));
  }

  bool _isToday(DateTime day) {
    return _isSameDay(day, DateTime.now());
  }

  Widget _buildCalendar(double screenWidth, double screenHeight) {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final startWeekday = firstDay.weekday % 7;
    final daysInMonth = lastDay.day;
    final today = DateTime.now();

    final now = DateTime.now();
    List<Widget> dayWidgets = [];

    for (int i = 0; i < startWeekday; i++) {
      dayWidgets.add(const SizedBox(width: 1, height: 1));
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final isPast = date.isBefore(DateTime(now.year, now.month, now.day));
      final unavailable = _isUnavailable(date);
      final todayDate = _isToday(date);

      final isRangeStart = _startDate != null && _isSameDay(date, _startDate!);
      final isRangeEnd = _endDate != null && _isSameDay(date, _endDate!);
      final inRange = _startDate != null && _endDate != null &&
          date.isAfter(_startDate!) && date.isBefore(_endDate!);
      final isRangeEdge = isRangeStart || isRangeEnd;

      final brandColor = const Color(0xFFCB471B);

      Color? bgColor;
      Color? borderColor;
      Color textColor;
      FontWeight fontWeight;

      if (unavailable) {
        bgColor = Colors.red.shade50;
        borderColor = Colors.red.shade200;
        textColor = Colors.red;
        fontWeight = FontWeight.bold;
      } else if (isRangeEdge) {
        bgColor = brandColor;
        textColor = Colors.white;
        fontWeight = FontWeight.bold;
      } else if (inRange) {
        bgColor = brandColor.withOpacity(0.12);
        textColor = brandColor;
        fontWeight = FontWeight.w600;
      } else if (todayDate) {
        bgColor = Colors.green;
        borderColor = Colors.green.shade700;
        textColor = Colors.white;
        fontWeight = FontWeight.bold;
      } else if (isPast) {
        bgColor = null;
        textColor = Colors.grey.shade300;
        fontWeight = FontWeight.w400;
      } else {
        bgColor = null;
        textColor = Colors.black87;
        fontWeight = FontWeight.w400;
      }

      dayWidgets.add(
        GestureDetector(
          onTap: unavailable || isPast ? null : () {
            setState(() {
              if (_startDate == null || (_startDate != null && _endDate != null)) {
                _startDate = date;
                _endDate = null;
              } else if (date.isBefore(_startDate!)) {
                _startDate = date;
              } else {
                _endDate = date;
              }
            });
          },
          child: Container(
            width: (screenWidth * 0.92 - screenWidth * 0.08) / 7,
            height: (screenWidth * 0.92 - screenWidth * 0.08) / 7,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
              border: borderColor != null
                  ? Border.all(color: borderColor, width: 2)
                  : null,
            ),
            child: Text(
              '$day',
              style: TextStyle(
                fontWeight: fontWeight,
                color: textColor,
                fontSize: screenWidth * 0.032,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _prevMonth,
                child: Container(
                  padding: EdgeInsets.all(screenWidth * 0.015),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade100,
                  ),
                  child: Icon(Icons.chevron_left, color: Colors.black87, size: screenWidth * 0.045),
                ),
              ),
              Text(
                '${_monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.04,
                  fontFamily: 'Montserrat',
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: _nextMonth,
                child: Container(
                  padding: EdgeInsets.all(screenWidth * 0.015),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade100,
                  ),
                  child: Icon(Icons.chevron_right, color: Colors.black87, size: screenWidth * 0.045),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: screenHeight * 0.015),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _dayHeaders.map((day) {
              return SizedBox(
                width: (screenWidth * 0.92 - screenWidth * 0.08) / 7,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: screenWidth * 0.028,
                    fontFamily: 'Montserrat',
                    color: Colors.grey.shade600,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: screenHeight * 0.008),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
          child: Wrap(
            spacing: 0,
            runSpacing: screenHeight * 0.004,
            children: dayWidgets,
          ),
        ),
        SizedBox(height: screenHeight * 0.01),
        _buildLegend(screenWidth),
      ],
    );
  }

  Widget _buildLegend(double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem(screenWidth, Colors.green, 'Today'),
          SizedBox(width: screenWidth * 0.04),
          _legendItem(screenWidth, Colors.red, 'Unavailable'),
          SizedBox(width: screenWidth * 0.04),
          _legendItem(screenWidth, const Color(0xFFCB471B), 'Range'),
        ],
      ),
    );
  }

  Widget _legendItem(double screenWidth, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: screenWidth * 0.025,
          height: screenWidth * 0.025,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        SizedBox(width: screenWidth * 0.01),
        Text(
          label,
          style: TextStyle(
            fontSize: screenWidth * 0.028,
            fontFamily: 'Montserrat',
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildStepCircle(double screenWidth, double screenHeight, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: screenWidth * 0.035,
          height: screenWidth * 0.035,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFFCB471B) : Colors.grey.shade300,
          ),
        ),
        SizedBox(height: screenHeight * 0.006),
        Text(
          label,
          style: TextStyle(
            fontSize: screenWidth * 0.028,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w500,
            color: isActive ? const Color(0xFFCB471B) : Colors.grey,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 1.45,
            child: Stack(
          children: [
            Positioned(
              top: 0,
              bottom: 0,
              right:
                  (MediaQuery.of(context).size.width +
                      MediaQuery.of(context).size.width * 1) /
                  300,
              child: Image.asset(
                'assets/backgroundcolors/normalscreen.png',
                width: MediaQuery.of(context).size.width * 1.08,
                height: MediaQuery.of(context).size.height * 0.9,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: screenHeight * 0.03,
              left: screenWidth * 0.04,
              child: Container(
                width: screenWidth * 0.128,
                height: screenWidth * 0.128,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/vectors/menu.png',
                    width: screenWidth * 0.07,
                    height: screenWidth * 0.07,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // Greeting and user name to the right of the menu circle
            Positioned(
              top: screenHeight * 0.03 + screenWidth * 0.015,
              left:
                  screenWidth * 0.04 + screenWidth * 0.128 + screenWidth * 0.03,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greetingText,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w700,
                      fontSize: screenWidth * 0.045,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.005),
                  Text(
                    _userFullName,
                    style: TextStyle(
                      fontFamily: 'Abril Fatface',
                      fontWeight: FontWeight.w600,
                      fontSize: screenWidth * 0.038,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: screenHeight * 0.03,
              right: screenWidth * 0.2,
              child: Container(
                width: screenWidth * 0.128,
                height: screenWidth * 0.128,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.person,
                    color: Colors.black,
                    size: screenWidth * 0.07,
                  ),
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.03,
              right: screenWidth * 0.04,
              child: Container(
                width: screenWidth * 0.128,
                height: screenWidth * 0.128,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.black,
                    size: screenWidth * 0.07,
                  ),
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.11,
              left: screenWidth * 0.04,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: screenWidth * 0.12,
                  height: screenWidth * 0.12,
                  decoration: BoxDecoration(
                    color: const Color(0XFFF3CA9B),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.chevron_left,
                      color: Colors.black,
                      size: screenWidth * 0.10,
                    ),
                  ),
                ),
              ),
            ),
            // Forward/inactive return button (mirrors back button)
            Positioned(
              top: screenHeight * 0.11,
              left: screenWidth * 0.27,
              right: screenWidth * 0.04,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Choose Date',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w700,
                      fontSize: screenWidth * 0.045,
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: _canForwardReturn
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BookingDetailsScreen(),
                              ),
                            ).then((_) {
                              if (mounted) setState(() {});
                            });
                          }
                        : null,
                    child: Opacity(
                      opacity: _canForwardReturn ? 1.0 : 0.35,
                      child: Container(
                        width: screenWidth * 0.12,
                        height: screenWidth * 0.12,
                        decoration: BoxDecoration(
                          color: const Color(0XFFF3CA9B),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.chevron_right,
                            color: Colors.black,
                            size: screenWidth * 0.10,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: screenHeight * 0.19,
              left: screenWidth * 0.08,
              right: screenWidth * 0.08,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: screenWidth * 0.09,
                    right: screenWidth * 0.15,
                    top: screenWidth * 0.015,
                    child: CustomPaint(
                      size: Size(double.infinity, 2),
                      painter: _DottedLinePainter(),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStepCircle(screenWidth, screenHeight, 'Choose Date', true),
                      _buildStepCircle(screenWidth, screenHeight, 'Booking Details', false),
                      _buildStepCircle(screenWidth, screenHeight, 'Payment Details', false),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: screenHeight * 0.25,
              left: screenWidth * 0.04,
              right: screenWidth * 0.04,
              child: SizedBox(
                height: screenHeight * 0.05,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.black,
                        size: screenWidth * 0.04,
                      ),
                      SizedBox(width: screenWidth * 0.025),
                      Flexible(
                        child: Text(
                          _startDate != null && _endDate != null
                              ? '${_monthNames[_startDate!.month - 1]} ${_startDate!.day} - ${_monthNames[_endDate!.month - 1]} ${_endDate!.day}, ${_endDate!.year}'
                              : _startDate != null
                                  ? '${_monthNames[_startDate!.month - 1]} ${_startDate!.day}, ${_startDate!.year}'
                                  : 'Select a date from the calendar',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth * 0.032,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.31,
              left: screenWidth * 0.04,
              right: screenWidth * 0.04,
              child: SizedBox(
                height: screenHeight * 0.4,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _buildCalendar(screenWidth, screenHeight),
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.72,
              left: screenWidth * 0.04,
              right: screenWidth * 0.04,
              child: SizedBox(
                height: screenHeight * 0.05,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: Colors.black,
                        size: screenWidth * 0.04,
                      ),
                      SizedBox(width: screenWidth * 0.025),
                      Flexible(
                        child: Text(
                          _formatTimeRange(),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth * 0.032,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.78,
              left: screenWidth * 0.04,
              right: screenWidth * 0.04,
              child: SizedBox(
                height: screenHeight * 0.20,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.015,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Choose Your Time',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: screenWidth * 0.038,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.012),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTimeColumn(screenWidth, 'From', _fromTime, onTap: () => _pickTime(true)),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                            child: Text(
                              'To',
                              style: TextStyle(
                                color: Colors.black,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w600,
                                fontSize: screenWidth * 0.032,
                              ),
                            ),
                          ),
                          Expanded(
                            child: _buildTimeColumn(screenWidth, 'To', _toTime, onTap: () => _pickTime(false)),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      SizedBox(
                        width: double.infinity,
                        height: screenHeight * 0.045,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFE0E7FF),
                                Color(0xFFCD7C20),
                              ],
                              stops: [0.0, 0.47],
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const BookingDetailsScreen(),
                                ),
                              ).then((_) {
                                if (mounted) {
                                  setState(() {
                                    _canForwardReturn = true;
                                  });
                                }
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              'Continue',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w700,
                                fontSize: screenWidth * 0.035,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: screenHeight * 0.02,
              left: 0,
              right: 0,
              child: Center(
                child: BottomNavbar(
                  activeIndex: _currentNavIndex,
                  onItemSelected: (index) {
                    setState(() {
                      _currentNavIndex = index;
                    });
                    if (index == 3) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerProfileScreen(),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset((startX + dashWidth).clamp(0, size.width), 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
