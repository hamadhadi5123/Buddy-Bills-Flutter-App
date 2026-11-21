import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class EmailService {
  // ============================================================================
  // EMAIL DISPATCH CONFIGURATION
  // ============================================================================
  // Choose your preferred transactional email provider:
  // Option 1: EmailJS (Free 200 emails/month, connects directly to your Gmail)
  //   1. Go to https://www.emailjs.com/ and create a free account.
  //   2. Add Email Service (connect your Gmail) -> Get Service ID.
  //   3. Create Email Template with variables {{to_email}}, {{otp_code}}, {{app_name}} -> Get Template ID.
  //   4. Copy Public Key from Account Settings.
  //
  // Option 2: Brevo (Formerly Sendinblue - Free 300 emails/day)
  //   1. Go to https://www.brevo.com/ and copy your API Key.
  // ============================================================================

  // --- EmailJS Configuration ---
  static const String emailJsServiceId = ""; // e.g. "service_xxxxxxx"
  static const String emailJsTemplateId = ""; // e.g. "template_xxxxxxx"
  static const String emailJsPublicKey = ""; // e.g. "public_key_xxxxxxx"

  // --- Brevo Configuration ---
  static const String brevoApiKey = ""; // e.g. "xkeysib-xxxxxxx"
  static const String brevoSenderEmail = "support@buddybills.com";
  static const String brevoSenderName = "Buddy Bills";

  // --- Custom Webhook / Cloud Function (Optional) ---
  static const String customWebhookUrl = ""; // e.g. "https://your-cloud-function.net/sendOtp"

  /// Dispatches the 6-digit OTP code to the recipient's official Gmail inbox.
  /// Returns a map: {'success': bool, 'message': String}
  static Future<Map<String, dynamic>> sendOtpEmail({
    required String recipientEmail,
    required String otpCode,
    String recipientName = "User",
  }) async {
    // 1. Try EmailJS if configured
    if (emailJsServiceId.isNotEmpty &&
        emailJsTemplateId.isNotEmpty &&
        emailJsPublicKey.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
          headers: {
            'Content-Type': 'application/json',
            'Origin': 'http://localhost',
          },
          body: jsonEncode({
            'service_id': emailJsServiceId,
            'template_id': emailJsTemplateId,
            'user_id': emailJsPublicKey,
            'template_params': {
              'to_email': recipientEmail,
              'recipient_email': recipientEmail,
              'name': recipientName,
              'otp_code': otpCode,
              'otp': otpCode,
              'app_name': 'Buddy Bills',
            },
          }),
        );

        if (response.statusCode == 200) {
          debugPrint("EmailJS OTP successfully sent to $recipientEmail");
          return {
            'success': true,
            'message': 'OTP sent to $recipientEmail via EmailJS.'
          };
        } else {
          debugPrint("EmailJS error: ${response.statusCode} - ${response.body}");
          return {
            'success': false,
            'message': 'EmailJS dispatch failed (${response.statusCode}): ${response.body}'
          };
        }
      } catch (e) {
        debugPrint("EmailJS exception: $e");
        return {'success': false, 'message': 'EmailJS network error: $e'};
      }
    }

    // 2. Try Brevo REST API if configured
    if (brevoApiKey.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse('https://api.brevo.com/v3/smtp/email'),
          headers: {
            'accept': 'application/json',
            'api-key': brevoApiKey,
            'content-type': 'application/json',
          },
          body: jsonEncode({
            'sender': {
              'name': brevoSenderName,
              'email': brevoSenderEmail,
            },
            'to': [
              {
                'email': recipientEmail,
                'name': recipientName,
              }
            ],
            'subject': 'Your Buddy Bills Verification OTP Code',
            'htmlContent': '''
              <div style="font-family: Arial, sans-serif; max-width: 500px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; borderRadius: 12px;">
                <h2 style="color: #FFB300; text-align: center;">Buddy Bills</h2>
                <p>Hello <b>$recipientName</b>,</p>
                <p>Your one-time verification code (OTP) for creating your Buddy Bills account is:</p>
                <div style="background-color: #f7f9fa; padding: 15px; text-align: center; border-radius: 8px; margin: 20px 0;">
                  <span style="font-size: 32px; font-weight: bold; letter-spacing: 6px; color: #0F172A;">$otpCode</span>
                </div>
                <p style="color: #666; font-size: 13px;">This code is valid for 59 seconds. Please do not share this code with anyone.</p>
                <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
                <p style="color: #999; font-size: 11px; text-align: center;">If you did not request this code, please ignore this email.</p>
              </div>
            ''',
          }),
        );

        if (response.statusCode == 201 || response.statusCode == 200) {
          debugPrint("Brevo OTP successfully sent to $recipientEmail");
          return {
            'success': true,
            'message': 'OTP sent to $recipientEmail via Brevo.'
          };
        } else {
          debugPrint("Brevo error: ${response.statusCode} - ${response.body}");
          return {
            'success': false,
            'message': 'Brevo dispatch failed: ${response.body}'
          };
        }
      } catch (e) {
        debugPrint("Brevo exception: $e");
        return {'success': false, 'message': 'Brevo network error: $e'};
      }
    }

    // 3. Try custom webhook if configured
    if (customWebhookUrl.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse(customWebhookUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'recipientEmail': recipientEmail,
            'otpCode': otpCode,
            'recipientName': recipientName,
          }),
        );
        if (response.statusCode == 200) {
          return {
            'success': true,
            'message': 'OTP sent via custom email webhook.'
          };
        }
      } catch (e) {
        debugPrint("Webhook exception: $e");
      }
    }

    // Fallback: If no external email service API key is configured yet
    debugPrint("⚠️ EmailService: No live email API key (EmailJS/Brevo) configured yet.");
    return {
      'success': false,
      'isConfigRequired': true,
      'message': 'Email provider not configured. Please add your EmailJS or Brevo API keys in lib/services/email_service.dart.'
    };
  }
}
