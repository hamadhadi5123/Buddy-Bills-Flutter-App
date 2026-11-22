import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final VoidCallback? onTap;
  final bool showEditBadge;

  const UserAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 24,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.onTap,
    this.showEditBadge = false,
  });

  Uint8List? _decodeBase64(String str) {
    try {
      if (str.contains(',')) {
        str = str.split(',').last;
      }
      return base64Decode(str);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = radius;
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : "U";
    final isUrl = imageUrl != null && imageUrl!.trim().isNotEmpty;
    final isBase64 = isUrl && (imageUrl!.startsWith('data:image') || (imageUrl!.length > 200 && !imageUrl!.startsWith('http')));

    Widget avatarContent;

    if (isBase64) {
      final bytes = _decodeBase64(imageUrl!);
      if (bytes != null) {
        avatarContent = CircleAvatar(
          radius: effectiveRadius,
          backgroundImage: MemoryImage(bytes),
          backgroundColor: Colors.transparent,
        );
      } else {
        avatarContent = _buildInitialFallback(initial);
      }
    } else if (isUrl && imageUrl!.startsWith('http')) {
      avatarContent = CircleAvatar(
        radius: effectiveRadius,
        backgroundColor: Colors.transparent,
        child: ClipOval(
          child: Image.network(
            imageUrl!,
            width: effectiveRadius * 2,
            height: effectiveRadius * 2,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildInitialFallback(initial),
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Center(
                child: SizedBox(
                  width: effectiveRadius,
                  height: effectiveRadius,
                  child: const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFD700)),
                ),
              );
            },
          ),
        ),
      );
    } else {
      avatarContent = _buildInitialFallback(initial);
    }

    if (!showEditBadge && onTap == null) {
      return avatarContent;
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatarContent,
          if (showEditBadge)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.black),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInitialFallback(String initial) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            backgroundColor ?? const Color(0xFFFFD700),
            (backgroundColor ?? const Color(0xFFFFD700)).withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (backgroundColor ?? const Color(0xFFFFD700)).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.outfit(
            fontSize: fontSize ?? (radius * 0.9),
            fontWeight: FontWeight.bold,
            color: textColor ?? Colors.black,
          ),
        ),
      ),
    );
  }
}
