import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pilipala/common/skeleton/video_card_h.dart';
import 'package:pilipala/common/widgets/animated_dialog.dart';
import 'package:pilipala/common/widgets/http_error.dart';
import 'package:pilipala/common/widgets/overlay_pop.dart';
import 'package:pilipala/common/widgets/video_card_h.dart';
import './controller.dart';

class RelatedVideoPanel extends StatelessWidget {
  final ReleatedController _releatedController =
      Get.put(ReleatedController(), tag: Get.arguments?['heroTag']);
  RelatedVideoPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _releatedController.queryRelatedVideo(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data == null) {
            return const SliverToBoxAdapter(child: SizedBox());
          }
          if (snapshot.data!['status']) {
            // 请求成功
            return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
              if (index == snapshot.data['data'].length) {
                return SizedBox(height: MediaQuery.of(context).padding.bottom);
              } else {
                return Material(
                  child: VideoCardH(
                    videoItem: snapshot.data['data'][index],
                    showPubdate: true,
                    longPress: () {
                      try {
                        _releatedController.popupDialog =
                            _createPopupDialog(snapshot.data['data'][index]);
                        Overlay.of(context)
                            .insert(_releatedController.popupDialog!);
                      } catch (err) {
                        return {};
                      }
                    },
                    longPressEnd: () {
                      _releatedController.popupDialog?.remove();
                    },
                  ),
                );
              }
            }, childCount: snapshot.data['data'].length + 1));
          } else {
            // 请求错误
            return HttpError(errMsg: '出错了', fn: () {});
          }
        } else {
          // 骨架屏
          return SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return const VideoCardHSkeleton();
            }, childCount: 5),
          );
        }
      },
    );
  }

  OverlayEntry _createPopupDialog(videoItem) {
    return OverlayEntry(
      builder: (BuildContext context) => AnimatedDialog(
        closeFn: _releatedController.popupDialog?.remove,
        child: OverlayPop(
            videoItem: videoItem,
            closeFn: _releatedController.popupDialog?.remove),
      ),
    );
  }
}
