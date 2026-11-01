import 'package:flutter/material.dart';

/// The list screen behind the picker: a large title and one inset row.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openPicker(BuildContext context) {
    // Wired up once the picker sheet exists.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 44, 16, 32),
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'App Icon Picker',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: Colors.black,
                ),
              ),
            ),
            _InsetRow(
              label: 'Change App Icon',
              onTap: () => _openPicker(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsetRow extends StatefulWidget {
  const _InsetRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_InsetRow> createState() => _InsetRowState();
}

class _InsetRowState extends State<_InsetRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: _pressed ? const Color(0xFFD1D1D6) : Colors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          widget.label,
          style: const TextStyle(fontSize: 17, color: Color(0xFF0A84FF)),
        ),
      ),
    );
  }
}
