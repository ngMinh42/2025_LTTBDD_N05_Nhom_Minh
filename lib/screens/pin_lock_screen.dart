import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_navigation.dart';

class PinLockScreen extends StatefulWidget {
  final String mode;
  final VoidCallback? onSuccess;
  const PinLockScreen({super.key, required this.mode, this.onSuccess});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _enteredPin = '';
  String _firstPin = '';
  bool _isConfirmStep = false;
  String? _savedPin;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPin();
  }

  Future<void> _loadPin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedPin = prefs.getString('app_pin');
      _loading = false;
    });
  }

  Future<void> _savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_pin', pin);
  }

  Future<void> _removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('app_pin');
  }

  void _onKeyPressed(String value) {
    if (_enteredPin.length >= 6) return;
    setState(() {
      _enteredPin += value;
    });

    if (_enteredPin.length == 6) {
      Future.delayed(const Duration(milliseconds: 150), _processPin);
    }
  }

  void _onDeletePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _processPin() async {
    if (widget.mode == 'set') {
      if (!_isConfirmStep) {
        _firstPin = _enteredPin;
        _enteredPin = '';
        _isConfirmStep = true;
        setState(() {});
      } else {
        if (_enteredPin == _firstPin) {
          await _savePin(_enteredPin);
          if (!mounted) return;
          _showSnack('Mã PIN đã được thiết lập');
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainNavigation()),
            );
          }
        } else {
          _showSnack('Mã PIN không khớp, thử lại');
          setState(() {
            _enteredPin = '';
            _isConfirmStep = false;
          });
        }
      }
    } else if (widget.mode == 'verify') {
      if (_enteredPin == _savedPin) {
        if (!mounted) return;
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainNavigation()),
          );
        }
      } else {
        _showSnack('Sai mã PIN, thử lại');
        setState(() => _enteredPin = '');
      }
    } else if (widget.mode == 'remove') {
      if (_enteredPin == _savedPin) {
        final confirmed = await _confirmDialog();
        if (confirmed) {
          await _removePin();
          if (!mounted) return;
          _showSnack('Đã xóa mã PIN');
          Navigator.pop(context, true);
        } else {
          setState(() => _enteredPin = '');
        }
      } else {
        _showSnack('Sai mã PIN');
        setState(() => _enteredPin = '');
      }
    }
  }

  Future<bool> _confirmDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xác nhận'),
            content: const Text('Bạn có chắc chắn muốn xóa mã PIN không?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xóa'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    String title;
    if (widget.mode == 'set') {
      title = _isConfirmStep
          ? 'Xác minh mã PIN mới của bạn'
          : 'Nhập mã PIN mới';
    } else if (widget.mode == 'verify') {
      title = 'Nhập mã PIN để tiếp tục';
    } else {
      title = 'Nhập mã PIN hiện tại để xóa';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 30),
            _buildPinDots(),
            const SizedBox(height: 40),
            _buildNumberPad(),
          ],
        ),
      ),
    );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        bool filled = index < _enteredPin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: filled ? Colors.black87 : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.grey, width: 1.5),
          ),
        );
      }),
    );
  }

  Widget _buildNumberPad() {
    final numbers = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['back', '0', 'del'],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Column(
        children: numbers.map((row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((item) {
              if (item == 'back') {
                return _buildIconButton(Icons.arrow_back, () {
                  Navigator.pop(context, false);
                });
              } else if (item == 'del') {
                return _buildIconButton(
                  Icons.backspace_outlined,
                  _onDeletePressed,
                );
              } else {
                return _buildNumberButton(item);
              }
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: GestureDetector(
        onTap: () => _onKeyPressed(number),
        child: Container(
          width: 75,
          height: 75,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFFdcdcdc), Color(0xFFeeeeee)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                offset: Offset(2, 2),
                blurRadius: 3,
              ),
            ],
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(fontSize: 24, color: Colors.black),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 75,
          height: 75,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[300],
          ),
          child: Icon(icon, size: 28, color: Colors.black87),
        ),
      ),
    );
  }
}
