import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellbotapp/components/background.dart';
import 'package:wellbotapp/responsive.dart';
import 'package:wellbotapp/screens/HomeScreen/home_screen.dart';

class PersonalInformationForm extends StatefulWidget {
  final String email;

  const PersonalInformationForm({Key? key, required this.email})
      : super(key: key);

  @override
  _PersonalInformationFormState createState() =>
      _PersonalInformationFormState();
}

class _PersonalInformationFormState extends State<PersonalInformationForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  String? _gender;
  String? _employmentStatus;
  String? _maritalStatus;
  XFile? _profileImage;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
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
    if (_profileImage != null)
      await prefs.setString('profileImage', _profileImage!.path);
  }

  Future<void> _pickImage() async {
    try {
      final selectedImage = await _picker.pickImage(
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

  @override
  Widget build(BuildContext context) {
    return Background(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.blueAccent,
          elevation: 0,
          title: Text(
            "Personal Information",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Responsive(
          mobile: _buildMobileContent(context),
          tablet: _buildTabletContent(context),
          desktop: _buildDesktopContent(context),
        ),
      ),
    );
  }

  Widget _buildMobileContent(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: _buildFormCard(context, isMobile: true),
      ),
    );
  }

  Widget _buildTabletContent(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: SizedBox(
            width: 600,
            child: _buildFormCard(context),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopContent(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 30.0),
          child: SizedBox(
            width: 800,
            child: _buildFormCard(context),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard(BuildContext context, {bool isMobile = false}) {
    return FadeTransition(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileImageSection(),
                  SizedBox(height: 30),
                  _buildAnimatedFormField(
                    controller: _fullNameController,
                    label: "Full Name",
                    icon: Icons.person,
                    validator: (value) => value?.isEmpty ?? true
                        ? "Please enter your full name"
                        : null,
                  ),
                  SizedBox(height: isMobile ? 20 : 15),
                  _buildAnimatedFormField(
                    initialValue: widget.email,
                    label: "Email",
                    icon: Icons.email,
                    readOnly: true,
                  ),
                  SizedBox(height: isMobile ? 20 : 15),
                  _buildAnimatedFormField(
                    controller: _phoneNumberController,
                    label: "Phone Number",
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) => value?.isEmpty ?? true
                        ? "Please enter your phone number"
                        : null,
                  ),
                  SizedBox(height: isMobile ? 20 : 15),
                  _buildDateOfBirthField(),
                  SizedBox(height: isMobile ? 20 : 15),
                  _buildAnimatedDropdown(
                    value: _gender,
                    label: "Gender",
                    icon: Icons.people,
                    items: ["Male", "Female", "Other"],
                    onChanged: (value) => setState(() => _gender = value),
                    validator: (value) =>
                        value == null ? "Please select your gender" : null,
                  ),
                  SizedBox(height: isMobile ? 20 : 15),
                  _buildAnimatedDropdown(
                    value: _employmentStatus,
                    label: "Employment Status",
                    icon: Icons.work,
                    items: ["Employed", "Unemployed", "Student"],
                    onChanged: (value) =>
                        setState(() => _employmentStatus = value),
                    validator: (value) => value == null
                        ? "Please select employment status"
                        : null,
                  ),
                  SizedBox(height: isMobile ? 20 : 15),
                  _buildAnimatedDropdown(
                    value: _maritalStatus,
                    label: "Marital Status",
                    icon: Icons.favorite,
                    items: ["Single", "Married", "Divorced"],
                    onChanged: (value) =>
                        setState(() => _maritalStatus = value),
                    validator: (value) =>
                        value == null ? "Please select marital status" : null,
                  ),
                  SizedBox(height: 30),
                  _buildActionButtons(),
                ],
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
                      ? FileImage(File(_profileImage!.path))
                      : null,
                  child: _profileImage == null
                      ? Icon(Icons.camera_alt,
                          size: 40, color: Colors.grey[400])
                      : null,
                ),
                if (_profileImage == null)
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
        onTap: () async {
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
        },
      ),
    );
  }

  Widget _buildAnimatedDropdown({
    required String label,
    required IconData icon,
    required List<String> items,
    required String? value,
    required Function(String?) onChanged,
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

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildAnimatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => _isLoading = true);
                    try {
                      await _saveData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Profile saved successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error saving profile: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  }
                },
          text: _isLoading ? 'Saving...' : 'Save',
          icon: _isLoading ? Icons.hourglass_empty : Icons.save,
          color: Colors.green,
        ),
        _buildAnimatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          },
          text: "Let's Go",
          icon: Icons.arrow_forward,
          color: Colors.blueAccent,
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
