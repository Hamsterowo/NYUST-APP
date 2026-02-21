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

/// 課表格子的骨架框架
class ScheduleSkeletonGrid extends StatelessWidget {
  const ScheduleSkeletonGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        // 假標題列
        Container(
          height: 40,
          color: colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              const SizedBox(width: 40),
              ...List.generate(
                7,
                (i) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 10,
                    ),
                    child: SkeletonBox(height: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        // 假格子列
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 節次欄
              SizedBox(
                width: 40,
                child: Column(
                  children: List.generate(
                    8,
                    (i) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: SkeletonBox(height: 12, borderRadius: 4),
                      ),
                    ),
                  ),
                ),
              ),
              // 格子
              Expanded(
                child: Column(
                  children: List.generate(
                    8,
                    (i) => Expanded(
                      child: Row(
                        children: List.generate(7, (j) {
                          // 隨機讓部分格子有課程骨架
                          final hasCourse =
                              (i * 7 + j) % 5 == 0 || (i * 7 + j) % 7 == 1;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: hasCourse
                                  ? SkeletonBox(borderRadius: 6)
                                  : const SizedBox.shrink(),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
          // 摘要卡片骨架
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
          // 表格骨架
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
  const CalendarSkeletonView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 月曆區域骨架
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // 月份標題列 (< 月份 >)
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonBox(width: 32, height: 32, borderRadius: 16),
                  SkeletonBox(width: 120, height: 20),
                  SkeletonBox(width: 32, height: 32, borderRadius: 16),
                ],
              ),
              const SizedBox(height: 12),
              // 週標題列
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
              const SizedBox(height: 8),
              // 日期格子（5 週）
              ...List.generate(
                5,
                (_) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: List.generate(
                      7,
                      (_) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: SkeletonBox(height: 36, borderRadius: 18),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // 事件列表骨架
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
    );
  }
}
