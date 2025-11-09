import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_navigation.dart';
import 'pin_lock_screen.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback? onLanguageChange;
  final VoidCallback? onLogout;

  const SettingsPage({super.key, this.onLanguageChange, this.onLogout});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isVietnamese = true;
  bool hasPin = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isVietnamese = prefs.getBool('isVietnamese') ?? true;
      hasPin = prefs.getString('app_pin') != null;
    });
  }

  Future<void> _toggleLanguage(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isVietnamese', value);
    setState(() => isVietnamese = value);
    widget.onLanguageChange?.call();
  }

  Future<void> _setPin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PinLockScreen(mode: 'set')),
    );
    if (result == true) {
      setState(() => hasPin = true);
    }
  }

  Future<void> _removePin() async {
    final verified = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PinLockScreen(mode: 'remove')),
    );
    if (verified == true) {
      setState(() => hasPin = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isVietnamese ? "Đăng xuất" : "Logout",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isVietnamese
              ? "Bạn có chắc chắn muốn đăng xuất?"
              : "Are you sure you want to logout?",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isVietnamese ? "Hủy" : "Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(
              isVietnamese ? "Đăng xuất" : "Logout",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authService = AuthService();
      await authService.logout();
      widget.onLogout?.call();

      if (widget.onLogout == null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => LoginPage(
              onLoginSuccess: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MainNavigation()),
              ),
            ),
          ),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          _buildSettingCard(
            icon: Icons.language,
            title: isVietnamese ? "Ngôn ngữ" : "Language",
            subtitle: isVietnamese ? "Tiếng Việt" : "English",
            trailing: Switch(
              value: isVietnamese,
              onChanged: _toggleLanguage,
              activeColor: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            icon: Icons.lock_outline,
            title: isVietnamese ? "Mã PIN" : "App PIN",
            subtitle: hasPin
                ? (isVietnamese ? "Đã bật PIN" : "PIN enabled")
                : (isVietnamese ? "Chưa đặt PIN" : "No PIN set"),
            trailing: ElevatedButton(
              onPressed: hasPin ? _removePin : _setPin,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasPin ? Colors.redAccent : Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: Text(
                hasPin
                    ? (isVietnamese ? "Gỡ" : "Remove")
                    : (isVietnamese ? "Đặt PIN" : "Set PIN"),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            icon: Icons.logout,
            title: isVietnamese ? "Đăng xuất" : "Logout",
            titleColor: Colors.redAccent,
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.blueAccent, size: 24),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: titleColor ?? Colors.black87,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              )
            : null,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
