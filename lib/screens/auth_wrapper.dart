import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/user.dart' as model;
import 'auth_screen.dart';
import 'role_selection_screen.dart';
import 'home_navigation.dart';
import 'enhanced_admin_dashboard.dart';
import 'account_suspended_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  bool? isAdminSelection;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final db = Provider.of<DatabaseService>(context, listen: false);
      if (state == AppLifecycleState.resumed) {
        db.updateUserPresence(user.uid, true);
      } else {
        db.updateUserPresence(user.uid, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context, listen: false);
    
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = authSnapshot.data;
        if (user == null) {
          if (isAdminSelection == null) {
            return RoleSelectionScreen(
              onRoleSelected: (isAdmin) {
                setState(() => isAdminSelection = isAdmin);
              },
            );
          }
          return AuthScreen(
            isAdminMode: isAdminSelection!,
            onBackToRoleSelection: () {
              setState(() => isAdminSelection = null);
            },
          );
        }

        // Reset selection for next logout
        if (isAdminSelection != null) {
           WidgetsBinding.instance.addPostFrameCallback((_) {
             if (mounted && isAdminSelection != null) {
               setState(() => isAdminSelection = null);
             }
           });
        }

        return StreamBuilder<model.User?>(
          stream: db.streamUser(user.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final appUser = userSnapshot.data;
            if (appUser == null) {
              return AuthScreen(
                isAdminMode: false, 
                onBackToRoleSelection: () => setState(() => isAdminSelection = null)
              );
            }

            final bool isPlatformAdmin = appUser.role.toLowerCase() == 'admin' || appUser.isAdmin;

            // If account is suspended by Admin and not platform admin, block access
            if (!appUser.isActive && !isPlatformAdmin) {
              return const AccountSuspendedScreen();
            }

            if (isPlatformAdmin) {
              return EnhancedAdminDashboard(currentUser: appUser);
            } else {
              return HomeNavigation(user: appUser);
            }
          },
        );
      },
    );
  }
}
