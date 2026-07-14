import 'package:flutter/material.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final Future<void> Function()? onRefresh;
  final bool isLoading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.onRefresh,
    this.isLoading = false,
    this.actions,
    this.bottom,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize {
    final double bottomHeight = bottom?.preferredSize.height ?? 0.0;
    return Size.fromHeight(kToolbarHeight + bottomHeight);
  }
}

class _CustomAppBarState extends State<CustomAppBar> {
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    final bool showSpinner = widget.isLoading || _isRefreshing;

    return AppBar(
      title: Text(
        widget.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      actions: [
        ...?widget.actions,
        if (showSpinner)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.0),
            ),
          )
        else if (widget.onRefresh != null)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              if (mounted) {
                setState(() {
                  _isRefreshing = true;
                });
              }
              try {
                await widget.onRefresh!();
              } finally {
                if (mounted) {
                  setState(() {
                    _isRefreshing = false;
                  });
                }
              }
            },
            tooltip: '重新整理',
          ),
      ],
      bottom: widget.bottom,
    );
  }
}
