import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NeoDropdownItem<T> {
  final T value;
  final String label;
  final IconData? icon;
  final Color? accentColor;
  final bool isCompleted;

  const NeoDropdownItem({
    required this.value,
    required this.label,
    this.icon,
    this.accentColor,
    this.isCompleted = false,
  });
}

class NeoDropdown<T> extends StatefulWidget {
  final List<NeoDropdownItem<T>> items;
  final T? currentValue;
  final void Function(T) onSelected;
  final Widget child;
  final bool enabled;
  final double minMenuWidth;

  const NeoDropdown({
    super.key,
    required this.items,
    required this.onSelected,
    required this.child,
    this.currentValue,
    this.enabled = true,
    this.minMenuWidth = 160,
  });

  @override
  State<NeoDropdown<T>> createState() => _NeoDropdownState<T>();
}

class _NeoDropdownState<T> extends State<NeoDropdown<T>> {
  OverlayEntry? _overlay;
  final _triggerKey = GlobalKey();

  void _open() {
    if (!widget.enabled || _overlay != null) return;

    final renderBox = _triggerKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final globalOffset = renderBox.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(context).size.width;
    final menuWidth = max(size.width, widget.minMenuWidth);

    // Align right-edge of menu to right-edge of trigger if it would overflow.
    final left = (globalOffset.dx + menuWidth > screenWidth)
        ? globalOffset.dx + size.width - menuWidth
        : globalOffset.dx;

    _overlay = OverlayEntry(
      builder: (ctx) => _NeoDropdownOverlay<T>(
        items: widget.items,
        currentValue: widget.currentValue,
        onSelected: (v) {
          _close();
          widget.onSelected(v);
        },
        onClose: _close,
        top: globalOffset.dy + size.height + 4,
        left: left,
        width: menuWidth,
      ),
    );
    Overlay.of(context).insert(_overlay!);
    setState(() {});
  }

  void _close() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _overlay?.remove();
    _overlay = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _triggerKey,
      onTap: _overlay == null ? _open : _close,
      child: widget.child,
    );
  }
}

class _NeoDropdownOverlay<T> extends StatelessWidget {
  final List<NeoDropdownItem<T>> items;
  final T? currentValue;
  final void Function(T) onSelected;
  final VoidCallback onClose;
  final double top;
  final double left;
  final double width;

  const _NeoDropdownOverlay({
    required this.items,
    required this.onSelected,
    required this.onClose,
    required this.top,
    required this.left,
    required this.width,
    this.currentValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          top: top,
          left: left,
          width: width,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: theme.appColors.surface,
                border: Border.all(color: theme.appColors.border!, width: 2),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.appColors.shadow!,
                    offset: const Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: items.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    final isLast = i == items.length - 1;
                    final isSelected = item.value == currentValue;
                    return _NeoDropdownTile<T>(
                      item: item,
                      isSelected: isSelected,
                      showDivider: !isLast,
                      onTap: () => onSelected(item.value),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NeoDropdownTile<T> extends StatelessWidget {
  final NeoDropdownItem<T> item;
  final bool isSelected;
  final bool showDivider;
  final VoidCallback onTap;

  const _NeoDropdownTile({
    required this.item,
    required this.isSelected,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = item.isCompleted 
        ? Colors.grey 
        : (item.accentColor ?? theme.appColors.onSurface!);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: item.isCompleted ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isSelected
                ? theme.appColors.primary!.withOpacity(0.15)
                : Colors.transparent,
            child: Row(
              children: [
                if (item.icon != null) ...[
                  Icon(item.icon, size: 18, color: accent),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    item.label.toUpperCase(),
                    style: theme.appTextTheme.body?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: accent,
                    ),
                  ),
                ),
                if (item.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade400,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: const Text(
                      'DONE',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (isSelected)
                  Icon(Icons.check, size: 16, color: theme.appColors.primary),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 1, color: theme.appColors.border!.withOpacity(0.3)),
      ],
    );
  }
}
