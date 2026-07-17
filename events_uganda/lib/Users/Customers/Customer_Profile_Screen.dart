import 'dart:io';
import 'package:events_uganda/Auth/auth_service.dart';
import 'package:events_uganda/Services/user_service.dart';
import 'package:events_uganda/Users/Customers/Customer_Home_Screen.dart';
import 'package:flutter/material.dart';
import 'package:events_uganda/components/Bottom_Navbar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:events_uganda/Users/NotificationScreen.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen>
    with TickerProviderStateMixin {
  int _currentNavIndex = 3;
  String _userFullName = '';
  String _userEmail = '';
  String _userPhone = '';
  String? _profilePicUrl;
  int? _expandedIndex;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _toggleSection(int index) {
    setState(() {
      _expandedIndex = _expandedIndex == index ? null : index;
    });
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    if (user != null) {
      setState(() {
        _userFullName = user['fullName'] as String? ?? 'User';
        _userEmail = user['email'] as String? ?? '';
        _userPhone = user['phone'] as String? ?? '';
        _profilePicUrl = user['photoUrl'] as String?;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    setState(() {
      _profilePicUrl = pickedFile.path;
    });
  }

  Widget _defaultProfileIcon(double screenWidth) {
    return Icon(
      Icons.person,
      color: Colors.black,
      size: screenWidth * 0.18,
    );
  }

  void _showEditProfileSheet() {
    final w = MediaQuery.of(context).size.width;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final nameCtrl = TextEditingController(text: _userFullName);
        final emailCtrl = TextEditingController(text: _userEmail);
        final phoneCtrl = TextEditingController(text: _userPhone);
        String? photoPath = _profilePicUrl;
        bool saving = false;

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: w * 0.05,
                right: w * 0.05,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    // Title
                    Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: w * 0.06,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    SizedBox(height: w * 0.04),
                    // Profile Avatar
                    GestureDetector(
                      onTap: () async {
                        final picked = await _picker.pickImage(source: ImageSource.gallery);
                        if (picked != null) {
                          setSheetState(() => photoPath = picked.path);
                        }
                      },
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: w * 0.1,
                            backgroundImage: photoPath != null
                                ? (photoPath!.startsWith('http')
                                    ? NetworkImage(photoPath!) as ImageProvider
                                    : FileImage(File(photoPath!)))
                                : null,
                            child: photoPath == null
                                ? Icon(Icons.person, size: w * 0.09, color: Colors.grey.shade400)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.all(w * 0.015),
                              decoration: BoxDecoration(
                                color: const Color(0xFFCC471B),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Icon(Icons.camera_alt, size: w * 0.035, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: w * 0.045),
                    // Full Name
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(fontFamily: 'Montserrat', fontSize: w * 0.038, color: Colors.black),
                      decoration: _sheetInputDecoration(w, 'Full Name', Icons.person_outline),
                    ),
                    SizedBox(height: w * 0.03),
                    // Email
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(fontFamily: 'Montserrat', fontSize: w * 0.038, color: Colors.black),
                      decoration: _sheetInputDecoration(w, 'Email', Icons.email_outlined),
                    ),
                    SizedBox(height: w * 0.03),
                    // Phone
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(fontFamily: 'Montserrat', fontSize: w * 0.038, color: Colors.black),
                      decoration: _sheetInputDecoration(w, 'Phone Number', Icons.phone_outlined),
                    ),
                    SizedBox(height: w * 0.05),
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: saving
                            ? null
                            : () async {
                                final navigator = Navigator.of(ctx);
                                setSheetState(() => saving = true);
                                final name = nameCtrl.text.trim();
                                final email = emailCtrl.text.trim();
                                final phone = phoneCtrl.text.trim();
                                String? photoUrl = photoPath;
                                try {
                                  final res = await AuthService.updateProfile(
                                    fullName: name,
                                    email: email,
                                    phone: phone,
                                  );
                                  if (photoPath != null && !photoPath!.startsWith('http')) {
                                    photoUrl = await AuthService.uploadProfilePhoto(photoPath!);
                                  }
                                  if (res.containsKey('user')) {
                                    var user = Map<String, dynamic>.from(res['user']);
                                    user['photoUrl'] = photoUrl;
                                    await AuthService.saveUser(user);
                                  }
                                } catch (_) {
                                  final local = {
                                    'fullName': name,
                                    'email': email,
                                    'phone': phone,
                                    'photoUrl': photoUrl,
                                  };
                                  final existing = await AuthService.getUser();
                                  if (existing != null) {
                                    existing.addAll(local);
                                    await AuthService.saveUser(existing);
                                  } else {
                                    await AuthService.saveUser(local);
                                  }
                                }
                                setState(() {
                                  _userFullName = name;
                                  _userEmail = email;
                                  _userPhone = phone;
                                  _profilePicUrl = photoUrl;
                                });
                                navigator.pop();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCC471B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 0,
                        ),
                        child: saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: w * 0.04,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _sheetInputDecoration(double w, String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontFamily: 'Montserrat', fontSize: w * 0.035, color: Colors.grey.shade600),
      prefixIcon: Icon(icon, color: const Color(0xFFCC471B), size: w * 0.045),
      contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: const Color(0xFFCC471B), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: const Color(0xFFCC471B), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: const Color(0xFFCC471B), width: 1),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message, style: const TextStyle(fontFamily: 'Montserrat'))));
  }

  void _showAddPaymentSheet(double w) {
    final typeCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: w * 0.05,
                right: w * 0.05,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 44, height: 5, margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3))),
                    Text('Add Payment Method', style: TextStyle(fontFamily: 'PlayfairDisplay', fontSize: w * 0.06, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A2E))),
                    SizedBox(height: w * 0.04),
                    TextField(controller: nameCtrl, style: TextStyle(fontFamily: 'Montserrat', fontSize: w * 0.038, color: Colors.black),
                      decoration: _sheetInputDecoration(w, 'Account Name', Icons.person_outline)),
                    SizedBox(height: w * 0.025),
                    TextField(controller: typeCtrl, style: TextStyle(fontFamily: 'Montserrat', fontSize: w * 0.038, color: Colors.black),
                      decoration: _sheetInputDecoration(w, 'Type (e.g. MTN, Airtel)', Icons.phone_android_outlined)),
                    SizedBox(height: w * 0.025),
                    TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, style: TextStyle(fontFamily: 'Montserrat', fontSize: w * 0.038, color: Colors.black),
                      decoration: _sheetInputDecoration(w, 'Phone Number', Icons.phone_outlined)),
                    SizedBox(height: w * 0.04),
                    SizedBox(
                      width: double.infinity, height: 44,
                      child: ElevatedButton(
                        onPressed: saving ? null : () async {
                          setSheetState(() => saving = true);
                          try {
                            await UserService.addPaymentMethod(
                              type: typeCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              name: nameCtrl.text.trim(),
                            );
                            Navigator.pop(ctx);
                            _showSnackBar('Payment method added');
                          } catch (e) {
                            setSheetState(() => saving = false);
                            _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5F0593),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 0,
                        ),
                        child: saving
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text('Add', style: TextStyle(fontFamily: 'Montserrat', fontSize: w * 0.04, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── Menu Sections ────────────────────────────────────────────────

  Widget _buildMenuSection(Size screen, double w, double h) {
    final sections = [
      _SectionData(Icons.person_outline, 'My Profile', const Color(0xFF027AC1), const Color(0xFFCAE8FA), _buildProfileContent(w, h)),
      _SectionData(Icons.shopping_bag_outlined, 'My Orders', const Color(0xFFF19124), const Color(0xFFFFE0B2), _buildOrdersContent(w, h)),
      _SectionData(Icons.attach_money, 'Refund', const Color(0xFFE24B19), const Color(0xFFF7A083), _buildRefundContent(w, h)),
      _SectionData(Icons.password_rounded, 'Change Password', const Color(0xFF238E05), const Color(0xFF98EE81), _buildPasswordContent(w, h)),
      _SectionData(Icons.payment_outlined, 'Payment Methods', const Color(0xFF5F0593), const Color(0xFFC491E2), _buildPaymentContent(w, h)),
      _SectionData(Icons.help_outline_rounded, 'Help & Support', const Color(0xFFD76005), const Color(0xFFF3D8C4), _buildHelpContent(w, h)),
      _SectionData(Icons.logout_rounded, 'Logout', const Color(0xFF009465), const Color(0xFF89E0C4), _buildLogoutContent(w, h), isLogout: true),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: w * 0.01),
          child: Text(
            'Account Overview',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w800,
              color: Colors.black,
              fontSize: w * 0.045,
            ),
          ),
        ),
        SizedBox(height: h * 0.02),
        ...List.generate(sections.length, (i) => _buildDropdownItem(screen, w, h, sections[i], i)),
      ],
    );
  }

  Widget _buildDropdownItem(Size screen, double w, double h, _SectionData section, int index) {
    final isExpanded = _expandedIndex == index;
    final iconSize = w * (28 / 375);
    final indent = w * (45 / 375) + w * 0.06;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _toggleSection(index),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: h * 0.006),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: w * (45 / 375),
                      height: w * (45 / 375),
                      decoration: BoxDecoration(
                        color: section.bgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(section.icon, color: section.color, size: iconSize),
                      ),
                    ),
                    SizedBox(width: w * 0.06),
                    Expanded(
                      child: Text(
                        section.label,
                        style: TextStyle(
                          fontFamily: 'Abril Fatface',
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          fontSize: w * 0.045,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: Icon(
                        section.isLogout ? Icons.logout : Icons.keyboard_arrow_down_rounded,
                        color: Colors.black,
                        size: w * 0.06,
                      ),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: isExpanded
                      ? Padding(
                          padding: EdgeInsets.only(left: indent, top: h * 0.012, bottom: h * 0.006),
                          child: section.content,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: indent),
          child: Divider(color: Colors.black.withValues(alpha: 0.6), thickness: 1, height: 1),
        ),
        if (!isExpanded) SizedBox(height: h * 0.024),
      ],
    );
  }

  // ─── Dropdown Content Builders ─────────────────────────────────────

  Widget _buildProfileContent(double w, double h) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow(Icons.person_outline, 'Full Name', _userFullName, w),
        SizedBox(height: h * 0.01),
        _infoRow(Icons.email_outlined, 'Email', _userEmail, w),
        SizedBox(height: h * 0.014),
        SizedBox(
          width: double.infinity,
          height: 30,
          child: ElevatedButton(
            onPressed: _showEditProfileSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF027AC1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Edit Profile', style: TextStyle(color: Colors.white, fontFamily: 'Montserrat', fontWeight: FontWeight.w600)),
          ),
        ),
        SizedBox(height: h * 0.012),
      ],
    );
  }

  Widget _buildOrdersContent(double w, double h) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: UserService.getOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)));
        }
        final orders = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (orders.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: h * 0.01),
                child: Text('No orders yet', style: TextStyle(fontFamily: 'Montserrat', fontSize: w * 0.03, color: Colors.grey)),
              )
            else
              ...orders.take(3).map((o) => Padding(
                    padding: EdgeInsets.only(bottom: h * 0.008),
                    child: _orderTile(
                      o['serviceName'] as String? ?? 'Event',
                      o['date'] as String? ?? '',
                      o['status'] as String? ?? 'Pending',
                      w,
                    ),
                  )),
            SizedBox(height: h * 0.014),
            SizedBox(
              width: double.infinity,
              height: 30,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Orders page coming soon')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF19124),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('View All Orders', style: TextStyle(color: Colors.white, fontFamily: 'Montserrat', fontWeight: FontWeight.w600)),
              ),
            ),
            SizedBox(height: h * 0.012),
          ],
        );
      },
    );
  }

  Widget _orderTile(String title, String date, String status, double w) {
    final isCompleted = status == 'Completed';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.03, vertical: w * 0.025),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700, fontSize: w * 0.036)),
                SizedBox(height: 2),
                Text(date, style: TextStyle(fontFamily: 'Montserrat', fontSize: w * 0.028, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontFamily: 'Montserrat', fontSize: w * 0.026,
                color: isCompleted ? Colors.green.shade700 : Colors.orange.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundContent(double w, double h) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Refunds are processed within 5-7 business days after approval.',
          style: TextStyle(fontFamily: 'Montserrat', fontSize: w * 0.03, color: Colors.grey.shade700, height: 1.4),
        ),
        SizedBox(height: h * 0.012),
        Container(
          padding: EdgeInsets.all(w * 0.03),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.shade100),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade700, size: w * 0.04),
              SizedBox(width: w * 0.025),
              Expanded(
                child: Text(
                  'Contact support to initiate a refund request.',
                  style: TextStyle(fontFamily: 'Montserrat', fontSize: w * 0.028, color: Colors.orange.shade800),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: h * 0.012),
      ],
    );
  }

  Widget _buildPasswordContent(double w, double h) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _passwordField('Current Password', w, controller: currentCtrl),
        SizedBox(height: h * 0.01),
        _passwordField('New Password', w, controller: newCtrl),
        SizedBox(height: h * 0.01),
        _passwordField('Confirm Password', w, controller: confirmCtrl),
        SizedBox(height: h * 0.014),
        SizedBox(
          width: double.infinity,
          height: 30,
          child: ElevatedButton(
            onPressed: () async {
              final current = currentCtrl.text.trim();
              final newPw = newCtrl.text.trim();
              final confirm = confirmCtrl.text.trim();

              if (current.isEmpty || newPw.isEmpty || confirm.isEmpty) {
                _showSnackBar('Please fill in all fields');
                return;
              }
              if (newPw != confirm) {
                _showSnackBar('New passwords do not match');
                return;
              }
              if (newPw.length < 6) {
                _showSnackBar('Password must be at least 6 characters');
                return;
              }

              try {
                await AuthService.changePassword(
                  currentPassword: current,
                  newPassword: newPw,
                );
                currentCtrl.clear();
                newCtrl.clear();
                confirmCtrl.clear();
                if (!context.mounted) return;
                _showSnackBar('Password updated successfully');
              } catch (e) {
                if (!context.mounted) return;
                _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF238E05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Update Password', style: TextStyle(color: Colors.white, fontFamily: 'Montserrat', fontWeight: FontWeight.w600)),
          ),
        ),
        SizedBox(height: h * 0.012),
      ],
    );
  }

  Widget _passwordField(String hint, double w, {TextEditingController? controller}) {
    final obscure = ValueNotifier<bool>(true);
    return ListenableBuilder(
      listenable: obscure,
      builder: (ctx, _) => SizedBox(
        width: double.infinity,
        height: 36,
        child: TextField(
          controller: controller,
          obscureText: obscure.value,
          style: TextStyle(fontFamily: 'Montserrat', fontSize: w * 0.032, color: Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontFamily: 'Montserrat', fontSize: w * 0.03, color: Colors.grey.shade500),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 14),
            suffixIcon: Padding(
              padding: EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap: () => obscure.value = !obscure.value,
                child: Icon(
                  obscure.value ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF238E05),
                  size: w * 0.035,
                ),
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: const Color(0xFF238E05), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: const Color(0xFF238E05), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: const Color(0xFF238E05), width: 1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentContent(double w, double h) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _paymentMethod(Image.asset('assets/images/visa.png', width: w * 0.04, height: w * 0.04, fit: BoxFit.contain), 'Visa ending in 4242', Icons.check_circle, Colors.green, w),
        SizedBox(height: h * 0.008),
        _paymentMethod(Image.asset('assets/images/mtn.png', width: w * 0.04, height: w * 0.04, fit: BoxFit.contain), 'MTN Mobile Money', Icons.radio_button_unchecked, Colors.grey, w),
        SizedBox(height: h * 0.008),
        _paymentMethod(Image.asset('assets/images/airtel.png', width: w * 0.04, height: w * 0.04, fit: BoxFit.contain), 'Airtel Money', Icons.radio_button_unchecked, Colors.grey, w),
        SizedBox(height: h * 0.012),
        SizedBox(
          width: double.infinity,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showAddPaymentSheet(w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, size: 16, color: Colors.white),
                    SizedBox(width: w * 0.01),
                    Flexible(
                      child: Text('Add Payment Method', overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontFamily: 'Montserrat', fontWeight: FontWeight.w600, fontSize: w * 0.028)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: h * 0.012),
      ],
    );
  }

  Widget _paymentMethod(Widget leading, String label, IconData trailingIcon, Color trailingColor, double w) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.02, vertical: w * 0.012),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          SizedBox(width: w * 0.035, child: leading),
          SizedBox(width: w * 0.01),
          Expanded(child: Text(label, style: TextStyle(fontFamily: 'Montserrat', fontSize: w * 0.028))),
          SizedBox(width: w * 0.015),
          Icon(trailingIcon, size: w * 0.03, color: trailingColor),
        ],
      ),
    );
  }

  Widget _buildHelpContent(double w, double h) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _helpTile(Icons.chat_outlined, 'Live Chat', 'Chat with our support team', w),
        SizedBox(height: h * 0.008),
        _helpTile(Icons.email_outlined, 'Email Us', 'support@eventsuganda.com', w),
        SizedBox(height: h * 0.008),
        _helpTile(Icons.phone_outlined, 'Call Us', '+256 700 123 456', w),
        SizedBox(height: h * 0.012),
      ],
    );
  }

  Widget _helpTile(IconData icon, String title, String subtitle, double w) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.025, vertical: w * 0.02),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: w * 0.09,
            height: w * 0.09,
            decoration: BoxDecoration(
              color: const Color(0xFFD76005).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFD76005), size: w * 0.04),
          ),
          SizedBox(width: w * 0.025),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600, fontSize: w * 0.034)),
                Text(subtitle, style: TextStyle(fontFamily: 'Montserrat', fontSize: w * 0.026, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400, size: w * 0.04),
        ],
      ),
    );
  }

  Widget _buildLogoutContent(double w, double h) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(w * 0.03),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.red.shade100),
          ),
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.red.shade600, size: w * 0.04),
              SizedBox(width: w * 0.025),
              Expanded(
                child: Text(
                  'You will be signed out of your account.',
                  style: TextStyle(fontFamily: 'Montserrat', fontSize: w * 0.028, color: Colors.red.shade800),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: h * 0.014),
        SizedBox(
          width: double.infinity,
          height: 30,
          child: ElevatedButton.icon(
            onPressed: () async {
              await AuthService.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout, size: 16),
            label: const Text('Sign Out', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
        SizedBox(height: h * 0.012),
      ],
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────

  Widget _infoRow(IconData icon, String label, String value, double w) {
    return Row(
      children: [
        Icon(icon, size: w * 0.035, color: Colors.grey.shade600),
        SizedBox(width: w * 0.02),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontFamily: 'Montserrat', fontSize: w * 0.024, color: Colors.grey.shade500)),
            Text(value, style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600, fontSize: w * 0.032)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final screen = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: MediaQuery.of(context).size.height * 0.0,
              bottom: MediaQuery.of(context).size.height * 0.0,
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
              top: screenHeight * 0.20,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _userFullName,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w900,
                        fontSize: screenWidth * 0.048,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.009),
                    Text(
                      _userEmail,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w500,
                        fontSize: screenWidth * 0.035,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.05,
              right: screenWidth * 0.2,
              left: screenWidth * 0.2,
              child: Container(
                width: screenWidth * 0.3,
                height: screenWidth * 0.3,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Color(0XFFF19124), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_profilePicUrl != null && _profilePicUrl!.isNotEmpty)
                      ClipOval(
                        child: _profilePicUrl!.startsWith('http')
                            ? Image.network(
                                _profilePicUrl!,
                                width: screenWidth * 0.3,
                                height: screenWidth * 0.3,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _defaultProfileIcon(screenWidth);
                                },
                              )
                            : Image.file(
                                File(_profilePicUrl!),
                                width: screenWidth * 0.3,
                                height: screenWidth * 0.3,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _defaultProfileIcon(screenWidth);
                                },
                              ),
                      )
                    else
                      _defaultProfileIcon(screenWidth),
                    // Upload icon square at bottom right
                    Positioned(
                      bottom: screenWidth * 0.02,
                      right: screenWidth * 0.13,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: screenWidth * 0.08,
                          height: screenWidth * 0.08,
                          decoration: BoxDecoration(
                            color: Color(0xFFFFC107),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Center(
                            child: Icon(
                                    Icons.upload,
                                    color: Colors.black,
                                    size: screenWidth * 0.045,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.03,
              right: screenWidth * 0.04,
  child: GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const NotificationScreen(),
        ),
      );
    },
    child: Container(
      width: screenWidth * 0.128,
      height: screenWidth * 0.128,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
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
            ),

            Positioned(
              top: MediaQuery.of(context).size.height * 0.04,
              left: MediaQuery.of(context).size.width * 0.04,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.13,
                  height: MediaQuery.of(context).size.width * 0.13,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8C2B0),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.chevron_left,
                      color: Colors.black,
                      size: MediaQuery.of(context).size.width * 0.10,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top:
                  MediaQuery.of(context).size.height * 0.10 +
                  MediaQuery.of(context).size.width * 0.22 +
                  MediaQuery.of(context).size.height * 0.015 +
                  MediaQuery.of(context).size.width * 0.13,
              left: MediaQuery.of(context).size.width * 0.03,
              right: MediaQuery.of(context).size.width * 0.03,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screen.width * 0.08,
                  vertical: screen.height * 0.03,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(36),
                    topRight: Radius.circular(36),
                  ),
                  border: Border.all(color: const Color(0xFFDE7A07), width: 1),
                ),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          MediaQuery.of(context).size.height *
                          1.2, // 120% of screen height
                    ),
                    child: Column(
                      children: [
                        _buildMenuSection(screen, screenWidth, screenHeight),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Bottom Navigation Bar - Floating
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
                    if (index == 0) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerHomeScreen(),
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
    );
  }
}

class _SectionData {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final Widget content;
  final bool isLogout;

  const _SectionData(this.icon, this.label, this.color, this.bgColor, this.content, {this.isLogout = false});
}
