import 'package:flutter/material.dart';

/// 閃爍骨架載入框架元件
/// 使用方式：用 SkeletonBox 建立任意形狀的佔位符
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.3,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: colorScheme.onSurface.withValues(
              alpha: _animation.value * 0.12,
            ),
          ),
        );
      },
    );
  }
}

/// 成績卡片的骨架框架
class GradesSkeletonCard extends StatelessWidget {
  const GradesSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SkeletonBox(height: 18, width: double.infinity),
                ),
                const SizedBox(width: 16),
                SkeletonBox(width: 60, height: 18),
              ],
            ),
            const SizedBox(height: 8),
            SkeletonBox(height: 12, width: 200),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _buildCourseRow(),
            const SizedBox(height: 8),
            _buildCourseRow(),
            const SizedBox(height: 8),
            _buildCourseRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseRow() {
    return Row(
      children: [
        const Expanded(child: SkeletonBox(height: 14)),
        const SizedBox(width: 16),
        SkeletonBox(width: 40, height: 28, borderRadius: 8),
      ],
    );
  }
}

/// 課表格子的骨架框架 (僅顯示外框與標題列，內部留白)
class ScheduleSkeletonGrid extends StatelessWidget {
  const ScheduleSkeletonGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final weekDays = ['一', '二', '三', '四', '五', '六'];

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Card(
        clipBehavior: Clip.hardEdge,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [

            Container(
              height: 40.0,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 40.0),
                  ...weekDays.map((d) => const Expanded(child: SizedBox())),
                ],
              ),
            ),

            Expanded(
              child: Container(
                width: double.infinity,
                color: colorScheme.surface,
                child: Row(
                  children: [
                    Container(
                      width: 40.0,
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 畢業學分的骨架框架
class GraduationSkeletonView extends StatelessWidget {
  const GraduationSkeletonView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Card(
            elevation: 2,
            shadowColor: Colors.transparent,
            color: colorScheme.surfaceContainer,
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  SkeletonBox(height: 14, width: 80),
                  SizedBox(height: 12),
                  SkeletonBox(height: 64, width: 100, borderRadius: 12),
                  SizedBox(height: 20),
                  Divider(),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          SkeletonBox(height: 12, width: 60),
                          SizedBox(height: 8),
                          SkeletonBox(height: 28, width: 80, borderRadius: 16),
                        ],
                      ),
                      Column(
                        children: [
                          SkeletonBox(height: 12, width: 60),
                          SizedBox(height: 8),
                          SkeletonBox(height: 28, width: 80, borderRadius: 16),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SkeletonBox(height: 22, width: 100),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: List.generate(
                  7,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: const [
                        Expanded(child: SkeletonBox(height: 14)),
                        SizedBox(width: 8),
                        Expanded(child: SkeletonBox(height: 14)),
                        SizedBox(width: 8),
                        Expanded(child: SkeletonBox(height: 14)),
                        SizedBox(width: 8),
                        Expanded(child: SkeletonBox(height: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 行事曆的骨架框架（月曆格子 + 事件列表）
class CalendarSkeletonView extends StatelessWidget {
  final bool isExpanded;
  const CalendarSkeletonView({super.key, this.isExpanded = true});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final calendarCard = Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [

            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(width: 32, height: 32, borderRadius: 16),
                SkeletonBox(width: 120, height: 20),
                SkeletonBox(width: 32, height: 32, borderRadius: 16),
              ],
            ),
            const SizedBox(height: 12),

            if (isExpanded)
              Row(
                children: List.generate(
                  7,
                  (_) => const Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: SkeletonBox(height: 14),
                    ),
                  ),
                ),
              ),
            if (isExpanded) const SizedBox(height: 8),

            if (isExpanded)
              ...List.generate(
                5,
                (_) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: List.generate(
                      7,
                      (_) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: SkeletonBox(height: 48, borderRadius: 24),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: calendarCard,
          ),
          if (isExpanded) const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: List.generate(
                3,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: SkeletonBox(height: 52, borderRadius: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
