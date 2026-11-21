import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/user.dart';
import '../services/user_activity_service.dart';
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

  Timer? _timer;
  int _start = 60;
  bool _canResend = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  String? verificationId;

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
    nameController.dispose();
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  void startTimer() {
    _timer?.cancel();
    setState(() {
      _start = 60;
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
                  _buildToggleAuthMode(subTextColor),
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
      title = "Verify Phone Number";
      subtitle = "Enter the 6-digit OTP code sent to your phone";
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
            hint: "yourname@example.com",
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
            hint: "••••••••",
          ),
          const SizedBox(height: 16),
        ],

        // Phone number field for Signup
        if (!isLogin && !isOtpSent) ...[
          _buildPremiumTextField(
            phoneController,
            "Phone Number",
            Icons.phone_rounded,
            isDark,
            keyboardType: TextInputType.phone,
            hint: "+923001234567 (with country code)",
          ),
        ],

        // OTP verification step
        if (isOtpSent) ...[
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: primaryBrandColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryBrandColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sms_rounded, color: primaryBrandColor, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      "Code sent to ${phoneController.text.trim()}",
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: primaryBrandColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildPremiumTextField(
            otpController,
            "6-Digit Verification Code",
            Icons.shield_rounded,
            isDark,
            keyboardType: TextInputType.number,
            hint: "123456",
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    isOtpSent = false;
                  });
                },
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: Text("Edit Details", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(foregroundColor: primaryBrandColor),
              ),
              Row(
                children: [
                  Text(
                    _canResend ? "" : "Resend in ",
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
                      onPressed: sendOtp,
                      child: Text(
                        "Resend Code",
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
      ],
    );
  }

  Widget _buildPremiumTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    bool isDark, {
    bool isPassword = false,
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
          obscureText: isPassword && !passwordVisible,
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
                      passwordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: () => setState(() => passwordVisible = !passwordVisible),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: GlassButton(
        onPressed: isLoading ? () {} : _handleMainButtonAction,
        label: isLoading ? "Please wait..." : _getMainButtonText(),
        icon: isLogin 
            ? Icons.login_rounded 
            : (isOtpSent ? Icons.check_circle_rounded : Icons.arrow_forward_rounded),
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
              Image.asset('lib/assets/images/google.webp', height: 20),
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
    if (isOtpSent) return "Verify & Register";
    return "Send Verification Code";
  }

  void _handleMainButtonAction() {
    if (isLogin) {
      handleLogin();
    } else {
      isOtpSent ? verifyOtpAndCreateAccount() : sendOtp();
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

  // ================= SIGNUP WITH OTP VERIFICATION =================
  Future<void> sendOtp() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    String phone = phoneController.text.trim();

    if (name.isEmpty) {
      showMessage("Please enter your full name", isError: true);
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      showMessage("Please enter a valid email address", isError: true);
      return;
    }
    if (password.length < 6) {
      showMessage("Password must be at least 6 characters", isError: true);
      return;
    }
    if (phone.isEmpty) {
      showMessage("Please enter your phone number", isError: true);
      return;
    }
    if (!phone.startsWith('+')) {
      showMessage("Please include country code with '+' (e.g. +923001234567)", isError: true);
      return;
    }
    if (phone.length < 9) {
      showMessage("Phone number is too short", isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      await fb.FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (cred) async {
          await _finalizeSignupWithPhoneCred(cred);
        },
        verificationFailed: (e) {
          setState(() => isLoading = false);
          String errorMsg = e.message ?? e.code;
          showMessage("OTP Verification Failed: $errorMsg", isError: true);
        },
        codeSent: (id, _) {
          verificationId = id;
          setState(() {
            isOtpSent = true;
            isLoading = false;
          });
          startTimer();
          showMessage("6-digit code sent to $phone");
        },
        codeAutoRetrievalTimeout: (id) => verificationId = id,
      );
    } catch (e) {
      setState(() => isLoading = false);
      showMessage("Error sending OTP: ${e.toString()}", isError: true);
    }
  }

  Future<void> verifyOtpAndCreateAccount() async {
    final smsCode = otpController.text.trim();
    if (smsCode.isEmpty || smsCode.length < 6) {
      showMessage("Please enter the 6-digit OTP code", isError: true);
      return;
    }

    if (verificationId == null) {
      showMessage("Verification session expired. Please request a new code.", isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final phoneCred = fb.PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: smsCode,
      );

      await _finalizeSignupWithPhoneCred(phoneCred);
    } on fb.FirebaseAuthException catch (e) {
      setState(() => isLoading = false);
      if (e.code == 'invalid-verification-code') {
        showMessage("Invalid verification code. Please check and try again.", isError: true);
      } else if (e.code == 'session-expired') {
        showMessage("Verification code expired. Please request a new code.", isError: true);
      } else {
        showMessage(e.message ?? "Verification failed [${e.code}]", isError: true);
      }
    } catch (e) {
      setState(() => isLoading = false);
      showMessage("Failed to verify: ${e.toString()}", isError: true);
    }
  }

  Future<void> _finalizeSignupWithPhoneCred(fb.PhoneAuthCredential phoneCred) async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final phone = phoneController.text.trim();

    try {
      // 1. Sign in with the verified phone credential
      final userCred = await fb.FirebaseAuth.instance.signInWithCredential(phoneCred);
      final fbUser = userCred.user!;

      // 2. Link Email & Password credential so user can log in with Email and Password
      try {
        await fbUser.linkWithCredential(
          fb.EmailAuthProvider.credential(email: email, password: password),
        );
      } catch (_) {
        try {
          await fbUser.updateEmail(email);
          await fbUser.updatePassword(password);
        } catch (_) {}
      }

      await fbUser.updateDisplayName(name);

      // 3. Create Firestore record with standard 'user' role
      final newUser = User(
        uid: fbUser.uid,
        name: name,
        email: email,
        phoneNumber: phone,
        role: 'user',
        isAdmin: false,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance.collection('users').doc(fbUser.uid).set(newUser.toMap(), SetOptions(merge: true));

      // 4. Enter application
      await _navigate(newUser);
    } catch (e) {
      setState(() => isLoading = false);
      showMessage("Signup finalization failed: ${e.toString()}", isError: true);
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
