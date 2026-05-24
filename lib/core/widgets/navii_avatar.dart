import 'package:flutter/material.dart';

class NaviiAvatar extends StatelessWidget {
  final String seed;
  final double size;
  final bool animated;

  const NaviiAvatar({
    super.key,
    required this.seed,
    required this.size,
    this.animated = false,
  });

  String get _url {
    final s = seed.trim().isEmpty ? 'default' : seed.trim();
    final encoded = Uri.encodeComponent(s);
    final px = size.toInt().clamp(16, 1024);
    final anim = animated ? '&animated=1' : '';
    return 'https://api.navii.dev/avatar/$encoded.png?size=$px$anim';
  }

  @override
  Widget build(BuildContext context) {
    return Image.network(
      _url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _Fallback(size: size),
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : _Fallback(size: size),
    );
  }
}

class _Fallback extends StatelessWidget {
  final double size;
  const _Fallback({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: Colors.grey.shade200,
      child: Icon(Icons.person_rounded,
          size: size * 0.55, color: Colors.grey.shade400),
    );
  }
}
