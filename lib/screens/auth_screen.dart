import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/user.dart';
import '../services/user_activity_service.dart';
import '../services/email_service.dart';
import '../widgets/glass_widgets.dart';
import '../theme/premium_theme.dart';
import 'home_navigation.dart';
import 'enhanced_admin_dashboard.dart';

class AuthScreen extends StatefulWidget {
  final bool isAdminMode;
  final VoidCallback? onBackToRoleSelection;
  const AuthScreen({
    super.key, 
    this.isAdminMode = false, 
    this.onBackToRoleSelection,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Predefined master App Admin email
  static const String predefinedAdminEmail = "admin@buddybills.com";

  bool isLogin = true;
  bool isOtpSent = false;
  bool isLoading = false;
  bool passwordVisible = false;
  bool confirmPasswordVisible = false;

  Timer? _timer;
  int _start = 59;
  bool _canResend = false;

  String? _currentOtp;
  String _pendingName = '';
  String _pendingEmail = '';
  String _pendingPassword = '';

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();
  final otpController = TextEditingController();

  Color get primaryBrandColor => PremiumTheme.goldenPrimary;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      fb.FirebaseAuth.instance.getRedirectResult().then((userCredential) {
        if (userCredential.user != null) {
          _fetchUserAndNavigate(userCredential.user!);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    otpController.dispose();
    super.dispose();
  }

  void startTimer() {
    _timer?.cancel();
    setState(() {
      _start = 59;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        timer.cancel();
        if (mounted) setState(() => _canResend = true);
      } else {
        if (mounted) setState(() => _start--);
      }
    });
  }

  void showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF1E2230),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final Color subTextColor = isDark ? Colors.white60 : const Color(0xFF4A4A6A);

    return Scaffold(
      body: GlassBackground(
        isDarkMode: isDark,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogoSection(textColor),
                  const SizedBox(height: 36),
                  GlassCard(
                    isDarkMode: isDark,
                    padding: EdgeInsets.all(isDark ? 24 : 32),
                    borderRadius: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormHeader(textColor, subTextColor),
                        const SizedBox(height: 28),
                        _buildAuthForm(isDark, textColor),
                        const SizedBox(height: 24),
                        _buildActionButton(),
                        if (isLogin && !isOtpSent) _buildSocialLogin(textColor, isDark),
                      ],
                    ),
                  ),
                  if (!isOtpSent) _buildToggleAuthMode(subTextColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection(Color textColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryBrandColor, primaryBrandColor.withOpacity(0.8)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryBrandColor.withOpacity(0.35),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.account_balance_wallet_rounded, size: 46, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 18),
        Text(
          "Buddy Bills",
          style: GoogleFonts.outfit(
            fontSize: 38,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Smart Bill Splitting & Expense Management",
          style: GoogleFonts.poppins(fontSize: 12, color: textColor.withOpacity(0.55)),
        ),
      ],
    );
  }

  Widget _buildFormHeader(Color textColor, Color subTextColor) {
    String title;
    String subtitle;

    if (isLogin) {
      title = "Welcome Back";
      subtitle = "Sign in with your email and password";
    } else if (isOtpSent) {
      title = "Enter Verification OTP";
      subtitle = "Enter the 6-digit code sent to your email";
    } else {
      title = "Create Account";
      subtitle = "Register to start splitting bills with friends";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: subTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAuthForm(bool isDark, Color textColor) {
    return Column(
      children: [
        // Name field for Signup
        if (!isLogin && !isOtpSent) ...[
          _buildPremiumTextField(
            nameController,
            "Full Name",
            Icons.person_rounded,
            isDark,
            hint: "e.g. Hamad Khan",
          ),
          const SizedBox(height: 16),
        ],

        // Email field
        if (!isOtpSent) ...[
          _buildPremiumTextField(
            emailController,
            "Email Address",
            Icons.alternate_email_rounded,
            isDark,
            keyboardType: TextInputType.emailAddress,
            hint: "yourname@gmail.com",
          ),
          const SizedBox(height: 16),
        ],

        // Password field
        if (!isOtpSent) ...[
          _buildPremiumTextField(
            passwordController,
            "Password",
            Icons.lock_rounded,
            isDark,
            isPassword: true,
            isPasswordVisible: passwordVisible,
            onToggleVisibility: () => setState(() => passwordVisible = !passwordVisible),
            hint: "•••••••• (min 8 chars)",
          ),
          const SizedBox(height: 16),
        ],

        // Confirm Password field for Signup
        if (!isLogin && !isOtpSent) ...[
          _buildPremiumTextField(
            confirmPasswordController,
            "Confirm Password",
            Icons.lock_outline_rounded,
            isDark,
            isPassword: true,
            isPasswordVisible: confirmPasswordVisible,
            onToggleVisibility: () => setState(() => confirmPasswordVisible = !confirmPasswordVisible),
            hint: "•••••••• (min 8 chars)",
          ),
        ],

        // OTP verification step
        if (isOtpSent) ...[
          _buildOtpVerificationStep(isDark, textColor),
        ],
      ],
    );
  }

  Widget _buildOtpVerificationStep(bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryBrandColor.withOpacity(0.18),
            primaryBrandColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryBrandColor.withOpacity(0.45), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryBrandColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.mark_email_read_rounded, size: 40, color: primaryBrandColor),
          ),
          const SizedBox(height: 16),
          Text(
            "Verify Your Email",
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "6-digit OTP code sent to your official Gmail:",
            style: GoogleFonts.poppins(fontSize: 12, color: textColor.withOpacity(0.7)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: primaryBrandColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _pendingEmail,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: primaryBrandColor,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Security instruction info box (NO OTP CODE SHOWN ON SCREEN)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black45 : Colors.white70,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primaryBrandColor.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.mark_email_unread_rounded, size: 22, color: primaryBrandColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Please check your Gmail inbox and spam folder for the 6-digit code.",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textColor.withOpacity(0.85),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 6-digit OTP Input field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Enter 6-Digit OTP",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  counterText: "",
                  hintText: "••••••",
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey.withOpacity(0.4),
                    fontSize: 22,
                    letterSpacing: 8,
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: primaryBrandColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Verify & Register Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : _verifyOtpAndCreateAccount,
              icon: const Icon(Icons.verified_user_rounded, size: 20),
              label: Text(
                isLoading ? "Creating Account..." : "Verify OTP & Create Account",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBrandColor,
                foregroundColor: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
            ),
          ),
          const SizedBox(height: 14),


          // Back to edit & Timer / Resend Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  _timer?.cancel();
                  setState(() {
                    isOtpSent = false;
                    otpController.clear();
                  });
                },
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: Text("Edit Details", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(foregroundColor: primaryBrandColor),
              ),
              Row(
                children: [
                  Text(
                    _canResend ? "" : "Expires in: ",
                    style: GoogleFonts.poppins(fontSize: 13, color: textColor.withOpacity(0.55)),
                  ),
                  if (!_canResend)
                    Text(
                      "00:${_start.toString().padLeft(2, '0')}",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: primaryBrandColor,
                      ),
                    ),
                  if (_canResend)
                    TextButton(
                      onPressed: _resendOtp,
                      child: Text(
                        "Resend OTP",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: primaryBrandColor,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    bool isDark, {
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onToggleVisibility,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword && !isPasswordVisible,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: Colors.grey.withOpacity(0.5), fontSize: 13),
            prefixIcon: Icon(icon, color: primaryBrandColor, size: 20),
            filled: true,
            fillColor: isDark ? Colors.black.withOpacity(0.25) : Colors.black.withOpacity(0.04),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: primaryBrandColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    if (isOtpSent) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      child: GlassButton(
        onPressed: isLoading ? () {} : _handleMainButtonAction,
        label: isLoading ? "Please wait..." : _getMainButtonText(),
        icon: isLogin ? Icons.login_rounded : Icons.arrow_forward_rounded,
        color: primaryBrandColor,
        isDarkMode: Theme.of(context).brightness == Brightness.dark,
      ),
    );
  }

  Widget _buildSocialLogin(Color textColor, bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Divider(color: textColor.withOpacity(0.12))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                "Or continue with",
                style: GoogleFonts.poppins(fontSize: 12, color: textColor.withOpacity(0.5)),
              ),
            ),
            Expanded(child: Divider(color: textColor.withOpacity(0.12))),
          ],
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: signInWithGoogle,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'lib/assets/images/google.webp',
                height: 20,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "G",
                    style: TextStyle(
                      color: Color(0xFF4285F4),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Google",
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleAuthMode(Color subTextColor) {
    if (isOtpSent) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isLogin ? "Don't have an account? " : "Already registered? ",
            style: GoogleFonts.poppins(fontSize: 14, color: subTextColor),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                isLogin = !isLogin;
                isOtpSent = false;
                otpController.clear();
              });
            },
            child: Text(
              isLogin ? "Sign Up" : "Sign In",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryBrandColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMainButtonText() {
    if (isLogin) return "Sign In";
    return "Send OTP";
  }

  void _handleMainButtonAction() {
    if (isLogin) {
      handleLogin();
    } else {
      handleSendEmailOtp();
    }
  }

  // ================= UNIFIED LOGIN (USER & PREDEFINED ADMIN) =================
  Future<void> handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage("Please enter your email and password", isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      fb.UserCredential userCredential;
      try {
        userCredential = await fb.FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on fb.FirebaseAuthException catch (e) {
        // If the predefined admin doesn't exist yet on fresh Firebase setup, bootstrap safely
        if (e.code == 'user-not-found' &&
            email.toLowerCase() == predefinedAdminEmail.toLowerCase()) {
          userCredential = await fb.FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          
          final adminUser = User(
            uid: userCredential.user!.uid,
            name: "Platform Administrator",
            email: email,
            isAdmin: true,
            isActive: true,
            role: "admin",
            createdAt: DateTime.now(),
          );
          
          await FirebaseFirestore.instance.collection('users').doc(adminUser.uid).set(adminUser.toMap());
          await _navigate(adminUser);
          return;
        } else {
          rethrow;
        }
      }

      // Check user document in Firestore
      final uid = userCredential.user!.uid;
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      User appUser;
      if (doc.exists && doc.data() != null) {
        appUser = User.fromMap(doc.data()!, doc.id);

        // Predefined Admin guarantee
        if (email.toLowerCase() == predefinedAdminEmail.toLowerCase()) {
          if (!appUser.isAdmin || appUser.role != 'admin') {
            appUser.isAdmin = true;
            appUser.role = 'admin';
            await FirebaseFirestore.instance.collection('users').doc(uid).update({
              'isAdmin': true,
              'role': 'admin',
            });
          }
        }
      } else {
        final isPredefinedAdmin = email.toLowerCase() == predefinedAdminEmail.toLowerCase();
        appUser = User(
          uid: uid,
          name: isPredefinedAdmin ? "Platform Administrator" : (userCredential.user!.displayName ?? "User"),
          email: email,
          isAdmin: isPredefinedAdmin,
          isActive: true,
          role: isPredefinedAdmin ? 'admin' : 'user',
          createdAt: DateTime.now(),
        );
        await FirebaseFirestore.instance.collection('users').doc(uid).set(appUser.toMap());
      }

      // Block suspended users
      final bool isPlatformAdmin = appUser.email.toLowerCase() == predefinedAdminEmail.toLowerCase() ||
          appUser.role.toLowerCase() == 'admin' ||
          appUser.isAdmin;

      if (!appUser.isActive && !isPlatformAdmin) {
        await fb.FirebaseAuth.instance.signOut();
        showMessage("Your account has been suspended by the administrator.", isError: true);
        return;
      }

      await _navigate(appUser);

    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        showMessage("No account found with this email. Please sign up first.", isError: true);
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        showMessage("Invalid email or password. Please try again.", isError: true);
      } else if (e.code == 'invalid-email') {
        showMessage("Please enter a valid email address.", isError: true);
      } else {
        showMessage(e.message ?? "Authentication failed [${e.code}]", isError: true);
      }
    } catch (e) {
      showMessage("Login failed: ${e.toString()}", isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ================= STEP 1: SEND EMAIL OTP (DOES NOT CREATE ACCOUNT YET) =================
  Future<void> handleSendEmailOtp() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (name.isEmpty) {
      showMessage("Please enter your full name", isError: true);
      return;
    }
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      showMessage("Please enter a valid email address", isError: true);
      return;
    }
    if (password.length < 8) {
      showMessage("Password must be at least 8 characters long", isError: true);
      return;
    }
    if (password != confirmPassword) {
      showMessage("Passwords do not match. Please verify your confirm password.", isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      // Generate 6-digit random OTP
      final random = Random();
      final otp = (100000 + random.nextInt(900000)).toString();

      _pendingName = name;
      _pendingEmail = email;
      _pendingPassword = password;
      _currentOtp = otp;
      otpController.clear();

      // Dispatch real email via EmailService
      final emailResult = await EmailService.sendOtpEmail(
        recipientEmail: email,
        otpCode: otp,
        recipientName: name,
      );

      setState(() {
        isLoading = false;
        isOtpSent = true;
      });

      startTimer();

      if (emailResult['success'] == true) {
        showMessage("Verification code sent to $email! Please check your inbox.");
      } else if (emailResult['isConfigRequired'] == true) {
        showMessage("Code generated for $email! Please configure EmailJS or Brevo in email_service.dart to receive emails.");
      } else {
        showMessage("Email dispatch warning: ${emailResult['message']}", isError: true);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      showMessage("Failed to generate OTP: ${e.toString()}", isError: true);
    }
  }

  // ================= RESEND OTP =================
  Future<void> _resendOtp() async {
    if (!_canResend) return;
    try {
      final random = Random();
      final newOtp = (100000 + random.nextInt(900000)).toString();
      setState(() {
        _currentOtp = newOtp;
        otpController.clear();
      });

      // Dispatch real email via EmailService
      final emailResult = await EmailService.sendOtpEmail(
        recipientEmail: _pendingEmail,
        otpCode: newOtp,
        recipientName: _pendingName,
      );

      startTimer();

      if (emailResult['success'] == true) {
        showMessage("New verification code sent to $_pendingEmail! Valid for 59 seconds.");
      } else if (emailResult['isConfigRequired'] == true) {
        showMessage("New OTP generated for $_pendingEmail! Please configure EmailJS or Brevo in email_service.dart.");
      } else {
        showMessage("Email dispatch warning: ${emailResult['message']}", isError: true);
      }
    } catch (e) {
      showMessage("Failed to resend OTP: ${e.toString()}", isError: true);
    }
  }

  // ================= STEP 2: VERIFY OTP AND REGISTER ACCOUNT =================
  Future<void> _verifyOtpAndCreateAccount() async {
    final enteredOtp = otpController.text.trim();

    if (enteredOtp.isEmpty) {
      showMessage("Please enter the 6-digit OTP code", isError: true);
      return;
    }

    if (enteredOtp.length != 6) {
      showMessage("OTP code must be 6 digits", isError: true);
      return;
    }

    if (_start == 0) {
      showMessage("OTP has expired. Please tap 'Resend OTP' to get a new code.", isError: true);
      return;
    }

    if (enteredOtp != _currentOtp) {
      showMessage("Invalid OTP code. Please enter the correct 6-digit code.", isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1. Create account in Firebase Auth only after OTP verification succeeds
      fb.UserCredential cred;
      try {
        cred = await fb.FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _pendingEmail,
          password: _pendingPassword,
        );
      } on fb.FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          setState(() => isLoading = false);
          showMessage("This email is already registered. Please sign in.", isError: true);
          return;
        }
        rethrow;
      }

      final fbUser = cred.user!;
      await fbUser.updateDisplayName(_pendingName);

      // 2. Create User document in Firestore
      final isPredefinedAdmin = _pendingEmail.toLowerCase() == predefinedAdminEmail.toLowerCase();
      final newUser = User(
        uid: fbUser.uid,
        name: _pendingName.isNotEmpty ? _pendingName : (fbUser.displayName ?? "User"),
        email: _pendingEmail,
        phoneNumber: null,
        role: isPredefinedAdmin ? 'admin' : 'user',
        isAdmin: isPredefinedAdmin,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance.collection('users').doc(fbUser.uid).set(newUser.toMap(), SetOptions(merge: true));
      
      // 3. Log user registration activity audit trail
      await UserActivityService.logActivity(
        userId: fbUser.uid,
        userName: newUser.name,
        action: 'Account Registration',
        details: 'Email OTP verified successfully: $_pendingEmail',
      );

      _timer?.cancel();

      if (mounted) {
        setState(() => isLoading = false);
        showMessage("Account created successfully! Welcome to Buddy Bills.");
        await _navigate(newUser);
      }
    } on fb.FirebaseAuthException catch (e) {
      if (mounted) setState(() => isLoading = false);
      if (e.code == 'invalid-email') {
        showMessage("Please provide a valid email address.", isError: true);
      } else {
        showMessage(e.message ?? "Registration failed [${e.code}]", isError: true);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      showMessage("Error during account registration: ${e.toString()}", isError: true);
    }
  }

  // ================= GOOGLE SIGN IN =================
  Future<void> signInWithGoogle() async {
    try {
      setState(() => isLoading = true);
      fb.UserCredential cred;

      if (kIsWeb) {
        cred = await fb.FirebaseAuth.instance.signInWithPopup(fb.GoogleAuthProvider());
      } else {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          setState(() => isLoading = false);
          return;
        }
        final googleAuth = await googleUser.authentication;
        cred = await fb.FirebaseAuth.instance.signInWithCredential(
          fb.GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          ),
        );
      }

      if (cred.user != null) {
        await _syncGoogleUser(cred.user!);
      }
    } catch (e) {
      showMessage("Google Sign-In failed: ${e.toString()}", isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _syncGoogleUser(fb.User u) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(u.uid).get();

    if (!doc.exists) {
      await FirebaseFirestore.instance.collection('users').doc(u.uid).set(
        User(
          uid: u.uid,
          name: u.displayName ?? "User",
          email: u.email ?? "",
          role: 'user',
          createdAt: DateTime.now(),
          isAdmin: false,
          isActive: true,
        ).toMap(),
      );
    }

    await _fetchUserAndNavigate(u);
  }

  Future<void> _fetchUserAndNavigate(fb.User u) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(u.uid).get();
    if (doc.exists && doc.data() != null) {
      _navigate(User.fromMap(doc.data()!, doc.id));
    }
  }

  Future<void> _navigate(User user) async {
    await UserActivityService.logLogin(user.uid, user.name);

    if (!mounted) return;

    final bool isPlatformAdmin = user.email.toLowerCase() == predefinedAdminEmail.toLowerCase() ||
        user.role.toLowerCase() == 'admin' ||
        user.isAdmin;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => isPlatformAdmin
            ? EnhancedAdminDashboard(currentUser: user)
            : HomeNavigation(user: user),
      ),
    );
  }
}
