import 'package:flutter/material.dart';
import 'dart:io';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/profile_image_service.dart';
import 'package:provider/provider.dart';

class ProfileAvatar extends StatelessWidget {
  final double size;
  final bool showEditButton;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    this.size = 50,
    this.showEditButton = false,
    this.onTap,
  });

  Widget _buildProfileImage(String avatarPath) {
    // Image locale (fichier système)
    if (avatarPath.isNotEmpty && !avatarPath.startsWith('http')) {
      final file = File(avatarPath);
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: FileImage(file),
        backgroundColor: Colors.transparent,
      );
    }
    
    // Image web (URL HTTP)
    if (avatarPath.startsWith('http') && avatarPath.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(avatarPath),
        backgroundColor: Colors.transparent,
      );
    }
    
    // Avatar par défaut
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Colors.grey[300],
      child: Icon(Icons.person, color: Colors.grey[600], size: size * 0.6),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        
        if (user == null) {
          return CircleAvatar(
            radius: size / 2,
            backgroundColor: Colors.grey[300],
            child: Icon(Icons.person, color: Colors.grey[600], size: size * 0.6),
          );
        }

        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(2),
                    child: _buildProfileImage(user.avatar),
                  ),
                ),
                if (showEditButton)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: size * 0.3,
                      height: size * 0.3,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: size * 0.2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
