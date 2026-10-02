import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/models/image.dart';
import '../../core/models/note.dart';
import '../../services/note_service.dart';
import '../theme.dart';
import 'format.dart';

/// 笔记卡片：正文为主、标题可选、有图显示缩略图、绑定时间显示时间角标。
class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.service,
    required this.note,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showTimeBadge = true,
  });

  final NoteService service;
  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// 日历/当日列表可能想隐藏角标时置 false；默认显示。
  final bool showTimeBadge;

  @override
  Widget build(BuildContext context) {
    final color = NotePalette.colorOf(note.color);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 分类颜色小圆点。
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 6, right: 12),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (note.title != null && note.title!.trim().isNotEmpty)
                          Expanded(
                            child: Text(
                              NoteFormat.displayTitle(note),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: CoupleColors.textDark,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (onEdit != null || onDelete != null)
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.more_horiz,
                              size: 20,
                              color: CoupleColors.textLight,
                            ),
                            onSelected: (value) {
                              if (value == 'edit') onEdit?.call();
                              if (value == 'delete') onDelete?.call();
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('编辑'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('删除'),
                              ),
                            ],
                          ),
                      ],
                    ),
                    if (note.content.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        note.content.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: CoupleColors.textDark,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    _ThumbnailRow(service: service, noteId: note.id),
                    if (showTimeBadge &&
                        (note.timeBind != TimeBind.none ||
                            note.reminderOffsetMin != null)) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (note.timeBind != TimeBind.none) ...[
                            const Icon(
                              Icons.event,
                              size: 14,
                              color: CoupleColors.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              NoteFormat.timeBadge(note),
                              style: const TextStyle(
                                color: CoupleColors.textLight,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          if (note.reminderOffsetMin != null) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.notifications_active_outlined,
                              size: 14,
                              color: CoupleColors.primaryDark,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 卡片缩略图行：最多展示 3 张，按需生成缩略图，缺图显示柔和占位。
class _ThumbnailRow extends StatelessWidget {
  const _ThumbnailRow({required this.service, required this.noteId});

  final NoteService service;
  final String noteId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ImageMeta>>(
      future: service.imagesForNote(noteId),
      builder: (context, snapshot) {
        final images = snapshot.data ?? const <ImageMeta>[];
        if (images.isEmpty) return const SizedBox.shrink();
        return Row(
          children: [
            for (final image in images.take(3))
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _ThumbnailTile(service: service, image: image),
              ),
          ],
        );
      },
    );
  }
}

class _ThumbnailTile extends StatelessWidget {
  const _ThumbnailTile({required this.service, required this.image});

  final NoteService service;
  final ImageMeta image;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: service.thumbnailFor(image),
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file == null) {
          return const _ImagePlaceholder();
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 64,
            height: 64,
            child: Image.file(
              file,
              fit: BoxFit.cover,
              cacheWidth: 160,
              frameBuilder: (context, child, frame, wasSync) {
                if (frame == null) return const _ImagePlaceholder();
                return child;
              },
              errorBuilder: (context, error, stack) =>
                  const _ImagePlaceholder(),
            ),
          ),
        );
      },
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: CoupleColors.blush,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.image_outlined,
        size: 22,
        color: CoupleColors.primary,
      ),
    );
  }
}
