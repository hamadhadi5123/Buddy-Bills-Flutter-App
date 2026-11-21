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
  bool isEmailVerificationSent = false;
  bool isLoading = false;
  bool passwordVisible = false;
  bool confirmPasswordVisible = false;

  Timer? _timer;
  Timer? _emailPollingTimer;
  int _start = 60;
  bool _canResend = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();

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
    _emailPollingTimer?.cancel();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
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
                        if (isLogin && !isEmailVerificationSent) _buildSocialLogin(textColor, isDark),
                      ],
                    ),
                  ),
                  if (!isEmailVerificationSent) _buildToggleAuthMode(subTextColor),
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
    } else if (isEmailVerificationSent) {
      title = "Verify Your Email";
      subtitle = "We have sent a verification email to your inbox";
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
        if (!isLogin && !isEmailVerificationSent) ...[
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
        if (!isEmailVerificationSent) ...[
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
        if (!isEmailVerificationSent) ...[
          _buildPremiumTextField(
            passwordController,
            "Password",
            Icons.lock_rounded,
            isDark,
            isPassword: true,
            isPasswordVisible: passwordVisible,
            onToggleVisibility: () => setState(() => passwordVisible = !passwordVisible),
            hint: "••••••••",
          ),
          const SizedBox(height: 16),
        ],

        // Confirm Password field for Signup
        if (!isLogin && !isEmailVerificationSent) ...[
          _buildPremiumTextField(
            confirmPasswordController,
            "Confirm Password",
            Icons.lock_outline_rounded,
            isDark,
            isPassword: true,
            isPasswordVisible: confirmPasswordVisible,
            onToggleVisibility: () => setState(() => confirmPasswordVisible = !confirmPasswordVisible),
            hint: "••••••••",
          ),
        ],

        // Email verification step
        if (isEmailVerificationSent) ...[
          _buildEmailVerificationStep(isDark, textColor),
        ],
      ],
    );
  }

  Widget _buildEmailVerificationStep(bool isDark, Color textColor) {
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
            "Verification email sent to:",
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
              emailController.text.trim(),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: primaryBrandColor,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black38 : Colors.white70,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: primaryBrandColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Waiting for verification... Open your email and tap the confirmation link.",
                    style: GoogleFonts.poppins(fontSize: 11, color: textColor.withOpacity(0.85)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : _manualCheckEmailVerified,
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: Text(
                isLoading ? "Checking..." : "I Have Verified My Email",
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  _emailPollingTimer?.cancel();
                  setState(() {
                    isEmailVerificationSent = false;
                  });
                },
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
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
                      onPressed: _resendVerificationEmail,
                      child: Text(
                        "Resend Email",
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
    if (isEmailVerificationSent) return const SizedBox.shrink();
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
    if (isEmailVerificationSent) return const SizedBox.shrink();
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
                isEmailVerificationSent = false;
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
    return "Sign Up & Verify Email";
  }

  void _handleMainButtonAction() {
    if (isLogin) {
      handleLogin();
    } else {
      handleSignupWithEmailVerification();
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

      // Check email verification for non-admin accounts
      final isPredefinedAdmin = email.toLowerCase() == predefinedAdminEmail.toLowerCase();
      if (!userCredential.user!.emailVerified && !isPredefinedAdmin) {
        await userCredential.user!.sendEmailVerification();
        await fb.FirebaseAuth.instance.signOut();
        if (mounted) setState(() => isLoading = false);
        showMessage("Your email is not verified yet. We have sent a verification email to $email. Please check your inbox and verify before signing in.", isError: true);
        return;
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

  // ================= SIGNUP WITH EMAIL VERIFICATION =================
  Future<void> handleSignupWithEmailVerification() async {
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
    if (password.length < 6) {
      showMessage("Password must be at least 6 characters", isError: true);
      return;
    }
    if (password != confirmPassword) {
      showMessage("Passwords do not match. Please verify your confirm password.", isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      fb.UserCredential cred;
      try {
        cred = await fb.FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
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
      await fbUser.updateDisplayName(name);
      await fbUser.sendEmailVerification();

      if (mounted) {
        setState(() {
          isLoading = false;
          isEmailVerificationSent = true;
        });
        startTimer();
        _startEmailVerificationPolling();
        showMessage("Verification email sent to $email. Please check your inbox.");
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
      showMessage("Error during registration: ${e.toString()}", isError: true);
    }
  }

  void _startEmailVerificationPolling() {
    _emailPollingTimer?.cancel();
    _emailPollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkEmailVerifiedSilently();
    });
  }

  Future<void> _checkEmailVerifiedSilently() async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await user.reload();
      if (user.emailVerified) {
        _emailPollingTimer?.cancel();
        await _finalizeVerifiedEmailUser(user);
      }
    } catch (_) {}
  }

  Future<void> _manualCheckEmailVerified() async {
    setState(() => isLoading = true);
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      showMessage("Session expired. Please sign in.", isError: true);
      return;
    }
    try {
      await user.reload();
      if (user.emailVerified) {
        _emailPollingTimer?.cancel();
        await _finalizeVerifiedEmailUser(user);
      } else {
        setState(() => isLoading = false);
        showMessage("Email not yet verified. Please tap the verification link in your email inbox.", isError: true);
      }
    } catch (e) {
      setState(() => isLoading = false);
      showMessage("Verification check failed: ${e.toString()}", isError: true);
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResend) return;
    try {
      final user = fb.FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();
      startTimer();
      showMessage("New verification email sent to ${emailController.text.trim()}");
    } catch (e) {
      showMessage("Failed to resend email: ${e.toString()}", isError: true);
    }
  }

  Future<void> _finalizeVerifiedEmailUser(fb.User fbUser) async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final isPredefinedAdmin = email.toLowerCase() == predefinedAdminEmail.toLowerCase();

    final newUser = User(
      uid: fbUser.uid,
      name: name.isNotEmpty ? name : (fbUser.displayName ?? "User"),
      email: email,
      phoneNumber: null,
      role: isPredefinedAdmin ? 'admin' : 'user',
      isAdmin: isPredefinedAdmin,
      isActive: true,
      createdAt: DateTime.now(),
    );

    await FirebaseFirestore.instance.collection('users').doc(fbUser.uid).set(newUser.toMap(), SetOptions(merge: true));
    await UserActivityService.logActivity(
      userId: fbUser.uid,
      userName: newUser.name,
      action: 'Account Registration',
      details: 'Email verified successfully: $email',
    );

    if (mounted) {
      setState(() => isLoading = false);
      showMessage("Email verified successfully! Welcome to Buddy Bills.");
      await _navigate(newUser);
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
