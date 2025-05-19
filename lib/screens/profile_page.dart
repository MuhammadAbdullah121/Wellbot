import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wellbotapp/screens/Login/login_screen.dart';
import 'package:wellbotapp/components/bottom_navigation_bar.dart';
import 'package:wellbotapp/components/background.dart';
import 'package:wellbotapp/responsive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends StatefulWidget {
  final String email;

  const ProfilePage({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _dateOfBirthController;
  bool _isEditing = false;
  bool _isLoading = false;
  String? _gender;
  String? _employmentStatus;
  String? _maritalStatus;
  XFile? _profileImage;
  int _currentIndex = 3;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _dateOfBirthController = TextEditingController();
    _loadSavedData();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fullNameController.text = prefs.getString('fullName') ?? '';
      _phoneNumberController.text = prefs.getString('phoneNumber') ?? '';
      _dateOfBirthController.text = prefs.getString('dateOfBirth') ?? '';
      _gender = prefs.getString('gender');
      _employmentStatus = prefs.getString('employmentStatus');
      _maritalStatus = prefs.getString('maritalStatus');
      String? imagePath = prefs.getString('profileImage');
      if (imagePath != null) {
        _profileImage = XFile(imagePath);
      }
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fullName', _fullNameController.text);
    await prefs.setString('phoneNumber', _phoneNumberController.text);
    await prefs.setString('dateOfBirth', _dateOfBirthController.text);
    if (_gender != null) await prefs.setString('gender', _gender!);
    if (_employmentStatus != null)
      await prefs.setString('employmentStatus', _employmentStatus!);
    if (_maritalStatus != null)
      await prefs.setString('maritalStatus', _maritalStatus!);
    if (_profileImage != null) {
      if (kIsWeb) {
        await prefs.setString('profileImage', _profileImage!.path);
      } else {
        await prefs.setString('profileImage', _profileImage!.path);
      }
    }
  }

  Future<void> _pickImage() async {
    if (!_isEditing) return;
    try {
      final picker = ImagePicker();
      final selectedImage = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (selectedImage != null) {
        setState(() {
          _profileImage = selectedImage;
        });
        await _saveData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Background(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.blueAccent,
          elevation: 0,
          title: Text(
            "Profile",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
            ),
          ],
        ),
        body: Responsive(
          mobile: _buildProfileContent(context, isMobile: true),
          tablet: _buildProfileContent(context),
          desktop: _buildProfileContent(context, isDesktop: true),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context,
      {bool isMobile = false, bool isDesktop = false}) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop
              ? 50.0
              : isMobile
                  ? 16.0
                  : 24.0,
          vertical: isMobile ? 20.0 : 30.0,
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Form(
              key: _formKey,
              child: Card(
                color: Colors.white.withOpacity(0.95),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _buildProfileImageSection(),
                      SizedBox(height: 30),
                      _buildAnimatedFormField(
                        label: "Email",
                        initialValue: widget.email,
                        icon: Icons.email,
                        readOnly: true,
                      ),
                      SizedBox(height: isMobile ? 20 : 15),
                      _buildAnimatedFormField(
                        label: "Full Name",
                        controller: _fullNameController,
                        icon: Icons.person,
                        readOnly: !_isEditing,
                        validator: (value) => value?.isEmpty ?? true
                            ? "Please enter your full name"
                            : null,
                      ),
                      SizedBox(height: isMobile ? 20 : 15),
                      _buildAnimatedFormField(
                        label: "Phone Number",
                        controller: _phoneNumberController,
                        icon: Icons.phone,
                        readOnly: !_isEditing,
                        keyboardType: TextInputType.phone,
                        validator: (value) => value?.isEmpty ?? true
                            ? "Please enter your phone number"
                            : null,
                      ),
                      SizedBox(height: isMobile ? 20 : 15),
                      _buildDateOfBirthField(),
                      SizedBox(height: isMobile ? 20 : 15),
                      _buildAnimatedDropdown(
                        label: "Gender",
                        value: _gender,
                        icon: Icons.people,
                        items: ["Male", "Female", "Other"],
                        onChanged: _isEditing
                            ? (value) => setState(() => _gender = value)
                            : null,
                        validator: (value) =>
                            value == null ? "Please select your gender" : null,
                      ),
                      SizedBox(height: isMobile ? 20 : 15),
                      _buildAnimatedDropdown(
                        label: "Employment Status",
                        value: _employmentStatus,
                        icon: Icons.work,
                        items: ["Employed", "Unemployed", "Student"],
                        onChanged: _isEditing
                            ? (value) =>
                                setState(() => _employmentStatus = value)
                            : null,
                        validator: (value) => value == null
                            ? "Please select employment status"
                            : null,
                      ),
                      SizedBox(height: isMobile ? 20 : 15),
                      _buildAnimatedDropdown(
                        label: "Marital Status",
                        value: _maritalStatus,
                        icon: Icons.favorite,
                        items: ["Single", "Married", "Divorced"],
                        onChanged: _isEditing
                            ? (value) => setState(() => _maritalStatus = value)
                            : null,
                        validator: (value) => value == null
                            ? "Please select marital status"
                            : null,
                      ),
                      SizedBox(height: 30),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: Hero(
        tag: 'profileImage',
        child: GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: _profileImage != null
                      ? kIsWeb
                          ? NetworkImage(_profileImage!.path)
                          : FileImage(File(_profileImage!.path))
                              as ImageProvider
                      : null,
                  child: _profileImage == null
                      ? Icon(Icons.camera_alt,
                          size: 40, color: Colors.grey[400])
                      : null,
                ),
                if (_isEditing && _profileImage == null)
                  Positioned(
                    bottom: 0,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Add Photo",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
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

  Widget _buildAnimatedFormField({
    required String label,
    required IconData icon,
    TextEditingController? controller,
    String? initialValue,
    bool readOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        initialValue: initialValue,
        readOnly: readOnly,
        keyboardType: keyboardType,
        validator: validator,
        style: GoogleFonts.poppins(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.blueAccent),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildDateOfBirthField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: _dateOfBirthController,
        readOnly: true,
        style: GoogleFonts.poppins(fontSize: 14),
        decoration: InputDecoration(
          labelText: "Date of Birth",
          prefixIcon: Icon(Icons.calendar_today, color: Colors.blueAccent),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.blueAccent),
          ),
        ),
        onTap: _isEditing ? _pickDateOfBirth : null,
      ),
    );
  }

  Widget _buildAnimatedDropdown({
    required String label,
    required IconData icon,
    required List<String> items,
    required String? value,
    required Function(String?)? onChanged,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item, style: GoogleFonts.poppins(fontSize: 14)),
                ))
            .toList(),
        onChanged: onChanged,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.blueAccent),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateOfBirth() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        _dateOfBirthController.text =
            DateFormat('dd-MM-yyyy').format(pickedDate);
      });
    }
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildAnimatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (_isEditing) {
                    if (_formKey.currentState!.validate()) {
                      setState(() => _isLoading = true);
                      try {
                        await _saveData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Profile updated successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error updating profile: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } finally {
                        setState(() {
                          _isLoading = false;
                          _isEditing = false;
                        });
                      }
                    }
                  } else {
                    setState(() => _isEditing = true);
                  }
                },
          text: _isLoading ? 'Saving...' : (_isEditing ? 'Save' : 'Edit'),
          icon: _isLoading
              ? Icons.hourglass_empty
              : (_isEditing ? Icons.save : Icons.edit),
          color: _isEditing ? Colors.green : Colors.blueAccent,
        ),
        _buildAnimatedButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          },
          text: "Sign Out",
          icon: Icons.logout,
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildAnimatedButton({
    required VoidCallback? onPressed,
    required String text,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 150,
      height: 45,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            SizedBox(width: 8),
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
