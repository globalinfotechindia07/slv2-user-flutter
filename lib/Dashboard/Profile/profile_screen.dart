import 'dart:io';
import 'dart:ui'; // [ADDED] for ImageFilter.blur on header
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_theme.dart';

// ─── FormSection Widget ────────────────────────────────────────────────────────

class FormSection extends StatelessWidget {
  final Widget child;
  final String title;
  final String subtitle;
  final IconData? icon;

  const FormSection({
    super.key,
    required this.child,
    required this.title,
    required this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}

// ─── InputField Widget ─────────────────────────────────────────────────────────

class InputField extends StatelessWidget {
  final String label;
  final String value;
  final bool readOnly;

  const InputField({
    super.key,
    required this.label,
    required this.value,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            // Gradient blur decoration (opacity: 10%)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFF3B82F6)],
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ),
            TextFormField(
              key: ValueKey(value),
              initialValue: value,
              readOnly: readOnly,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF1E293B),
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── UserInfo Model ────────────────────────────────────────────────────────────

class UserInfo {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String profileImage;
  final String aadhaarNumber;
  final String panNumber;
  final String address;
  final String dob;
  final String gender;

  const UserInfo({
    this.id = '',
    this.name = '',
    this.email = '',
    this.phoneNumber = '',
    this.profileImage = '',
    this.aadhaarNumber = '',
    this.panNumber = '',
    this.address = '',
    this.dob = '',
    this.gender = '',
  });

  UserInfo copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? profileImage,
    String? aadhaarNumber,
    String? panNumber,
    String? address,
    String? dob,
    String? gender,
  }) {
    return UserInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImage: profileImage ?? this.profileImage,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      panNumber: panNumber ?? this.panNumber,
      address: address ?? this.address,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
    );
  }
}

// ─── ProfileScreen ─────────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  const ProfileScreen({super.key, required this.userProfile});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>{
  String _profileImage = '';
  bool _loading = false;
  String _error = '';
  UserInfo _userInfo = const UserInfo();

  // Blob animation controllers
  // late AnimationController _blobController;
  // late Animation<double> _blobAnimation;

  // [ADDED] Allowed image extensions — mirrors React's validTypes list
  static const List<String> _allowedExtensions = ['jpg', 'jpeg', 'png', 'gif'];

  @override
  void initState() {
    super.initState();
    debugPrint('DEBUG ProfileScreen userProfile: ${widget.userProfile}');
    debugPrint('DEBUG ProfileScreen id: ${widget.userProfile['id']}');

    // _blobController = AnimationController(
    //   vsync: this,
    //   duration: const Duration(seconds: 8),
    // )..repeat(reverse: true);

    // _blobAnimation = Tween<double>(begin: 0.25, end: 0.40).animate(
    //   CurvedAnimation(parent: _blobController, curve: Curves.easeInOut),
    // );

    _fetchUserData();
  }

  @override
  void dispose() {
    // _blobController.dispose();
    super.dispose();
  }

  // ── Data Fetching ──────────────────────────────────────────────────────────

  Future<void> _fetchUserData() async {
    try {
      String id = widget.userProfile['id']?.toString() ?? '';
      if (id.isEmpty) {
        id = await AuthService.getUserId();
      }
      debugPrint('DEBUG fetching user id: $id');
      if (id.isEmpty) {
        setState(() => _error = 'User not found. Please log in again.');
        return;
      }
      final data = await ApiService.getUserById(id);
      debugPrint('DEBUG user data: $data');
      setState(() {
        _userInfo = UserInfo(
          id: data['id']?.toString() ?? '',
          name: data['name']?.toString() ?? '',
          email: data['email']?.toString() ?? '',
          phoneNumber: data['phone_number']?.toString() ?? '',
          profileImage: data['profile_image']?.toString() ?? '',
          aadhaarNumber: data['aadhaar_number']?.toString() ?? '',
          panNumber: data['pan_number']?.toString() ?? '',
          address: data['address']?.toString() ?? '',
          dob: data['dob']?.toString() ?? '',
          gender: data['gender']?.toString() ?? '',
        );
        if (data['profile_image'] != null &&
            data['profile_image'].toString().isNotEmpty) {
          _profileImage =
              '${ApiConstants.userBaseUrl}/${data['profile_image']}';
        }
      });
    } catch (err) {
      debugPrint('DEBUG fetch error: $err');
      setState(() => _error = 'Failed to fetch user data');
    }
  }

  // ── Image Upload ───────────────────────────────────────────────────────────

  Future<void> _handleImageUpload(File file) async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final data =
          await ApiService.uploadProfileImage(file.path, _userInfo.id);
      debugPrint('Upload response: $data');    

      if (data['success'] == true) {
        final imageUrl =
    '${ApiConstants.userBaseUrl}/${data['image_path']}';
        setState(() {
          _profileImage = imageUrl;
          _userInfo = _userInfo.copyWith(profileImage: data['image_path']);
        });
      } else {
        throw Exception(data['message'] ?? 'Image upload failed');
      }
    } catch (err) {
      debugPrint('Upload error: $err');
      setState(() => _error = err.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

Future<void> _handleImageChange() async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 90,
  );

  if (picked == null) return;
  debugPrint('Picked path: ${picked.path}');
  debugPrint('Picked mimeType: ${picked.mimeType}');

  final pathExt = picked.path.split('.').last.toLowerCase();
  final mimeType = picked.mimeType?.toLowerCase() ?? '';

  final hasValidExt = _allowedExtensions.contains(pathExt);
  final hasValidMime = ['image/jpeg', 'image/png', 'image/gif'].contains(mimeType);
  final hasNoUsableExt = !RegExp(r'^(jpg|jpeg|png|gif)$').hasMatch(pathExt);

  // Reject only if we have a clearly bad extension AND mime doesn't confirm it's an image
  if (!hasValidExt && !hasValidMime && !hasNoUsableExt) {
    setState(() =>
        _error = 'Invalid file type. Only JPG, PNG and GIF are allowed.');
    return;
  }

  final file = File(picked.path);
  final bytes = await file.length();

  const maxSize = 5 * 1024 * 1024;
  if (bytes > maxSize) {
    setState(() => _error = 'File too large. Maximum size is 5MB.');
    return;
  }

  await _handleImageUpload(file);
}

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatDob(String? dob) {
    if (dob == null || dob.isEmpty) return 'Not provided';
    try {
      final date = DateTime.parse(dob);
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return dob;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          _buildBackground(),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FormSection(
                          title: 'Profile Picture',
                          subtitle: 'Update your profile picture',
                          child: _buildProfileImageSection(),
                        ),
                        const SizedBox(height: 32),
                        FormSection(
                          title: 'Personal Information',
                          subtitle: 'Your personal details',
                          child: _buildPersonalInfoSection(),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Background with animated blobs ────────────────────────────────────────

  Widget _buildBackground() {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFF1F2),
          Colors.white,
          Color(0xFFEFF6FF),
        ],
      ),
    ),
    child: CustomPaint(
      painter: _GridPainter(),
      size: Size.infinite,
    ),
  );
}

  // ── Sticky Header ──────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    // [ADDED] ClipRect + BackdropFilter to replicate React's backdrop-blur-sm
    // React: className="sticky top-0 bg-white/80 backdrop-blur-sm border-b"
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            border: const Border(
              bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Row(
                  children: const [
                    Icon(Icons.arrow_back,
                        size: 18, color: Color(0xFF475569)),
                    SizedBox(width: 6),
                    Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),

              // Title
              const Text(
                'My Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),

              // [ADDED] Help button — shows a SnackBar placeholder,
              // matching React's UI button that is also not yet wired up
              IconButton(
                onPressed: () {
                  // TODO: wire up to help/FAQ screen when ready
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Help & Support coming soon'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.help_outline,
                  size: 24,
                  color: Color(0xFF475569),
                ),
                style: IconButton.styleFrom(
                  shape: const CircleBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Profile Image Section ──────────────────────────────────────────────────

  Widget _buildProfileImageSection() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            // Profile image
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: ClipOval(
                child: _profileImage.isNotEmpty
                    ? Image.network(
                        _profileImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildPlaceholderAvatar(),
                      )
                    : _buildPlaceholderAvatar(),
              ),
            ),

            // [ADDED] Upload spinner overlay on the avatar while loading —
            // React's loading state disables the button + shows "Uploading..."
            // text; Flutter additionally dims the avatar with a centered spinner
            // so the user sees clear feedback on the image itself.
            if (_loading)
              Positioned.fill(
                child: ClipOval(
                  child: Container(
                    width: 128,
                    height: 128,
                    color: Colors.black.withOpacity(0.35),
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

            // Camera button — hidden while uploading to prevent double-tap
            if (!_loading)
              GestureDetector(
                onTap: _handleImageChange,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x26000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 20,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
          ],
        ),

        // Error message
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 16, color: Color(0xFFEF4444)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  _error,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: const Icon(Icons.person, size: 64, color: Color(0xFF94A3B8)),
    );
  }

  // ── Personal Info Section ──────────────────────────────────────────────────

  Widget _buildPersonalInfoSection() {
    return Column(
      children: [
        InputField(label: 'Name', value: _userInfo.name, readOnly: true),
        const SizedBox(height: 24),
        InputField(label: 'Email', value: _userInfo.email, readOnly: true),
        const SizedBox(height: 24),
        InputField(
            label: 'Phone', value: _userInfo.phoneNumber, readOnly: true),
        const SizedBox(height: 24),
        InputField(
          label: 'Aadhaar Number',
          value: _userInfo.aadhaarNumber.isNotEmpty
              ? _userInfo.aadhaarNumber
              : 'Not provided',
          readOnly: true,
        ),
        const SizedBox(height: 24),
        InputField(
          label: 'Pan Number',
          value: _userInfo.panNumber.isNotEmpty
              ? _userInfo.panNumber
              : 'Not provided',
          readOnly: true,
        ),
        const SizedBox(height: 24),
        InputField(
          label: 'Address',
          value: _userInfo.address.isNotEmpty
              ? _userInfo.address
              : 'Not provided',
          readOnly: true,
        ),
        const SizedBox(height: 24),
        InputField(
          label: 'Date of Birth',
          value: _formatDob(_userInfo.dob),
          readOnly: true,
        ),
        const SizedBox(height: 24),
        InputField(
          label: 'Gender',
          value: _userInfo.gender.isNotEmpty
              ? _userInfo.gender
              : 'Not provided',
          readOnly: true,
        ),
        const SizedBox(height: 24),
        _buildUpdateButton(),
      ],
    );
  }

  Widget _buildUpdateButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(2),
      child: ElevatedButton(
        onPressed: _loading ? null : _handleImageChange,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDC2626),
          disabledBackgroundColor:
              const Color(0xFFDC2626).withOpacity(0.5),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          _loading ? 'Uploading...' : 'Update Profile Picture',
          style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ─── Grid Painter ──────────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.02)
      ..strokeWidth = 1;

    const step = 32.0;

    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}