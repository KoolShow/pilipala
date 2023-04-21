import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pilipala/common/widgets/video_card_h.dart';
import './controller.dart';

class RelatedVideoPanel extends StatefulWidget {
  const RelatedVideoPanel({super.key});

  @override
  State<RelatedVideoPanel> createState() => _RelatedVideoPanelState();
}

class _RelatedVideoPanelState extends State<RelatedVideoPanel> {
  final ReleatedController _releatedController = Get.put(ReleatedController());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _releatedController.queryRelatedVideo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data!['status']) {
            // 请求成功
            // List videoList = _releatedController.relatedVideoList;
            return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
              if (index == snapshot.data['data'].length) {
                return SizedBox(height: MediaQuery.of(context).padding.bottom);
              } else {
                return VideoCardH(
                  videoItem: snapshot.data['data'][index],
                );
              }
            }, childCount: snapshot.data['data'].length + 1));
          } else {
            // 请求错误
            return const Center(
              child: Text('出错了'),
            );
          }
        } else {
          return const SliverToBoxAdapter(
            child: Text('请求中'),
          );
        }
      },
    );
  }
}