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
  const AuthScreen(
      {super.key, this.isAdminMode = false, this.onBackToRoleSelection});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool isOtpSent = false;
  bool isLoading = false;
  bool passwordVisible = false;
  String? adminError;

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
    if (widget.isAdminMode) {
      isLogin = true;
    }
    if (kIsWeb && !widget.isAdminMode) {
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
        setState(() => _canResend = true);
      } else {
        setState(() => _start--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final Color subTextColor = isDark ? Colors.white60 : const Color(0xFF4A4A6A);
    // Removed unused glassBorderColor and glassFillColor

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
                    if (widget.onBackToRoleSelection != null)
                      _buildBackButton(textColor),
                    
                    _buildLogoSection(textColor, isDark),
                    
                    const SizedBox(height: 40),
                    
                    GlassCard(
                      isDarkMode: isDark,
                      padding: EdgeInsets.all(isDark ? 24 : 32),
                      borderRadius: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFormHeader(textColor, subTextColor),
                          const SizedBox(height: 32),
                          _buildAuthForm(isDark),
                          const SizedBox(height: 24),
                          _buildActionButton(),
                          if (!widget.isAdminMode && !isOtpSent) _buildSocialLogin(textColor, isDark),
                        ],
                      ),
                    ),
                    
                    if (!widget.isAdminMode) _buildToggleAuthMode(subTextColor),
                    if (adminError != null) _buildAdminErrorCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildAdminErrorCard() {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Text(
          "Invalid Admin Credentials",
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }


  Widget _buildBackButton(Color iconColor) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: iconColor, size: 20),
          onPressed: widget.onBackToRoleSelection,
        ),
      ),
    );
  }

  Widget _buildLogoSection(Color textColor, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryBrandColor, primaryBrandColor.withValues(alpha: 0.8)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryBrandColor.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.wallet_rounded, size: 50, color: Colors.white),
        ),
        const SizedBox(height: 20),
        Text(
          "Buddy Bills",
          style: GoogleFonts.outfit(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }

  Widget _buildFormHeader(Color textColor, Color subTextColor) {
    String title = widget.isAdminMode 
        ? "Admin Login Only" 
        : (isLogin ? "Welcome Back" : "Join Buddy Bills");
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.isAdminMode 
              ? "Access the management dashboard" 
              : (isLogin ? "Please enter your details to sign in" : "Create an account to start splitting"),
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: subTextColor,
          ),
        ),
        if (widget.isAdminMode) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
            
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAuthForm(bool isDark) {
    return Column(
      children: [
        if (!isLogin && !isOtpSent)
          _buildPremiumTextField(
            nameController,
            "Full Name",
            Icons.person_rounded,
            isDark,
          ),
        if (!isLogin && !isOtpSent) const SizedBox(height: 18),
        if (!isOtpSent)
          _buildPremiumTextField(
            emailController,
            "Email Address",
            Icons.alternate_email_rounded,
            isDark,
            keyboardType: TextInputType.emailAddress,
          ),
        if (!isOtpSent) const SizedBox(height: 18),
        if (!isOtpSent)
          _buildPremiumTextField(
            passwordController,
            "Password",
            Icons.lock_rounded,
            isDark,
            isPassword: true,
          ),
        if (!isLogin && !isOtpSent) const SizedBox(height: 18),
        if (!isLogin && !isOtpSent)
          _buildPremiumTextField(
            phoneController,
            "Phone Number",
            Icons.phone_rounded,
            isDark,
            keyboardType: TextInputType.phone,
            hint: "+923000000000",
          ),
        if (isOtpSent) ...[
          Center(
            child: Column(
              children: [
                Text(
                  "Verification Code",
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  "We've sent an OTP to ${phoneController.text}",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.white60),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildPremiumTextField(
            otpController,
            "6-Digit Code",
            Icons.shield_rounded,
            isDark,
            keyboardType: TextInputType.number,
            hint: "000000",
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _canResend ? "Didn't receive code? " : "Resend code in ",
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white60),
              ),
              if (!_canResend)
                Text(
                  "00:${_start.toString().padLeft(2, '0')}",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryBrandColor,
                  ),
                ),
              if (_canResend)
                GestureDetector(
                  onTap: sendOtp,
                  child: Text(
                    "Resend Now",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: primaryBrandColor,
                    ),
                  ),
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
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : Colors.black54,
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
            hintStyle: GoogleFonts.poppins(color: Colors.grey.withOpacity(0.5), fontSize: 14),
            prefixIcon: Icon(icon, color: primaryBrandColor, size: 20),
            filled: true,
            fillColor: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.03),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.transparent),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: primaryBrandColor.withOpacity(0.5), width: 1.5),
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
        onPressed: isLoading ? () {} : _handleMainButtonAction, // Handle disabled state in GlassButton if needed
        label: _getMainButtonText(),
        color: primaryBrandColor,
        isDarkMode: Theme.of(context).brightness == Brightness.dark,
      ),
    );
  }

  Widget _buildSocialLogin(Color textColor, bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(child: Divider(color: textColor.withOpacity(0.1))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Or continue with",
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
              ),
            ),
            Expanded(child: Divider(color: textColor.withOpacity(0.1))),
          ],
        ),
        const SizedBox(height: 24),
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
              Image.asset('lib/assets/images/google.webp', height: 22),
              const SizedBox(width: 12),
              Text(
                "Google",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
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
            isLogin ? "Don't have an account? " : "Already working with us? ",
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
              isLogin ? "Sign Up" : "Login",
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
    if (isOtpSent) return "Verify & Create Account";
    return "Send OTP";
  }

  void _handleMainButtonAction() {
    if (isLogin) {
      handleLogin();
    } else {
      isOtpSent ? verifyOtpAndCreateAccount() : sendOtp();
    }
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ================= LOGIN =================
  Future<void> handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage("Please fill all fields");
      return;
    }

    setState(() => isLoading = true);

    // -------- ADMIN MODE: MULTI-ADMIN & LAZY AUTH --------
    if (widget.isAdminMode) {
      setState(() => adminError = null);
      
      try {
        // 1. Try standard sign-in first
        final userCredential = await fb.FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        // 2. Check if this user is actually an admin in Firestore
        final doc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();
        if (doc.exists) {
          final user = User.fromMap(doc.data()!, doc.id);
          if (user.role == 'admin' || user.isAdmin) {
            await _navigate(user);
            return;
          }
        }
        
        // Not an admin or no record found
        await fb.FirebaseAuth.instance.signOut();
        setState(() {
          adminError = "Access Denied: Not an Administrator";
          isLoading = false;
        });
      } on fb.FirebaseAuthException catch (e) {
        // 3. If Auth account doesn't exist or password mismatch, check Lazy Auth
        if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'wrong-password') {
          final query = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .where('initialPassword', isEqualTo: password)
              .limit(1)
              .get();

          if (query.docs.isNotEmpty) {
            // Found a pre-registered admin! Create their Auth account
            final doc = query.docs.first;
            final data = doc.data();
            
            if (data['role'] == 'admin' || data['isAdmin'] == true) {
              await _lazyCreateAdminAuth(email, password, doc.id, data);
              return;
            }
          }
        }
        
        setState(() {
          adminError = "Invalid Admin Credentials";
          isLoading = false;
        });
      } catch (e) {
        showMessage("Admin login failed: ${e.toString()}");
        setState(() => isLoading = false);
      }
      return;
    }

    // -------- STANDARD USER LOGIN --------
    try {
      final userCredential =
          await fb.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _fetchUserAndNavigate(userCredential.user!);
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        showMessage("No account found. Please sign up first.");
      } else if (e.code == 'invalid-credential') {
        showMessage("Invalid email or password");
      } else {
        showMessage("Login failed: ${e.toString()}");
      }
    } catch (e) {
      showMessage("Login failed: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ================= LAZY AUTH FLOW =================
  Future<void> _lazyCreateAdminAuth(String email, String password, String oldDocId, Map<String, dynamic> oldData) async {
    try {
      final userCredential = await fb.FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final newUid = userCredential.user!.uid;
      
      // Update Firestore: Use the new Auth UID, clear initialPassword
      final Map<String, dynamic> newData = Map.from(oldData);
      newData['uid'] = newUid;
      newData.remove('initialPassword');
      
      // 1. Set the new doc
      await FirebaseFirestore.instance.collection('users').doc(newUid).set(newData, SetOptions(merge: true));
      
      // 2. Delete the old doc if it had a different ID (like email or timestamp)
      if (oldDocId != newUid) {
        await FirebaseFirestore.instance.collection('users').doc(oldDocId).delete();
      }

      final adminUser = User.fromMap(newData, newUid);
      await _navigate(adminUser);
      
    } catch (e) {
      showMessage("Lazy Auth failed: ${e.toString()}");
      setState(() => isLoading = false);
    }
  }

  Future<void> sendOtp() async {
    String phone = phoneController.text.trim();
    
    // Basic Normalization: Ensure number starts with +
    if (!phone.startsWith('+')) {
      showMessage("Please include country code (e.g., +92 or +1)");
      return;
    }

    if (phone.length < 8) {
      showMessage("Invalid phone number length");
      return;
    }

    setState(() => isLoading = true);
    
    try {
      await fb.FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (cred) async {
          await _finalizeSignup(
            cred,
            nameController.text,
            emailController.text,
            passwordController.text,
          );
        },
        verificationFailed: (e) {
          setState(() => isLoading = false);
          // Show detailed error for debugging
          String errorMsg = e.code;
          if (e.message != null) errorMsg += ": ${e.message}";
          showMessage("OTP Error [$errorMsg]");
          print("FIREBASE OTP ERROR: $errorMsg");
        },
        codeSent: (id, _) {
          verificationId = id;
          setState(() {
            isOtpSent = true;
            isLoading = false;
          });
          startTimer();
          showMessage("Code sent to $phone");
        },
        codeAutoRetrievalTimeout: (id) => verificationId = id,
      );
    } catch (e) {
      setState(() => isLoading = false);
      showMessage("System error: ${e.toString()}");
    }
  }

  Future<void> verifyOtpAndCreateAccount() async {
    final cred = fb.PhoneAuthProvider.credential(
      verificationId: verificationId!,
      smsCode: otpController.text.trim(),
    );
    await _finalizeSignup(
      cred,
      nameController.text,
      emailController.text,
      passwordController.text,
    );
  }

  Future<void> _finalizeSignup(fb.PhoneAuthCredential cred, String name,
      String email, String password) async {
    final userCred = await fb.FirebaseAuth.instance.signInWithCredential(cred);
    await userCred.user!.linkWithCredential(
      fb.EmailAuthProvider.credential(email: email, password: password),
    );

    final user = User(
      uid: userCred.user!.uid,
      name: name,
      email: email,
      createdAt: DateTime.now(),
      isAdmin: false,
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(user.toMap());

    _navigate(user);
  }

  Future<void> signInWithGoogle() async {
    try {
      setState(() => isLoading = true);
      fb.UserCredential cred;

      if (kIsWeb) {
        cred = await fb.FirebaseAuth.instance
            .signInWithPopup(fb.GoogleAuthProvider());
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
      showMessage("Google Sign-In failed: ${e.toString()}");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _syncGoogleUser(fb.User u) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(u.uid).get();

    if (!doc.exists) {
      await FirebaseFirestore.instance.collection('users').doc(u.uid).set(
            User(
              uid: u.uid,
              name: u.displayName ?? "User",
              email: u.email ?? "",
              createdAt: DateTime.now(),
              isAdmin: false,
            ).toMap(),
          );
    }

    await _fetchUserAndNavigate(u);
  }

  Future<void> _fetchUserAndNavigate(fb.User u) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(u.uid).get();
    if (doc.exists && doc.data() != null) {
      _navigate(User.fromMap(doc.data()!, doc.id));
    }
  }

  Future<void> _navigate(User user) async {
    await UserActivityService.logLogin(user.uid, user.name);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => user.isAdmin
            ? EnhancedAdminDashboard(currentUser: user)
            : HomeNavigation(user: user),
      ),
    );
  }
}