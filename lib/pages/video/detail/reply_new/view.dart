import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:pilipala/http/video.dart';
import 'package:pilipala/models/common/reply_type.dart';
import 'package:pilipala/models/video/reply/item.dart';
import 'package:pilipala/utils/feed_back.dart';
import 'package:pilipala/utils/storage.dart';

class VideoReplyNewDialog extends StatefulWidget {
  final int? oid;
  final int? root;
  final int? parent;
  final ReplyType? replyType;
  final ReplyItemModel? replyItem;

  const VideoReplyNewDialog({
    super.key,
    this.oid,
    this.root,
    this.parent,
    this.replyType,
    this.replyItem,
  });

  @override
  State<VideoReplyNewDialog> createState() => _VideoReplyNewDialogState();
}

class _VideoReplyNewDialogState extends State<VideoReplyNewDialog>
    with WidgetsBindingObserver {
  final TextEditingController _replyContentController = TextEditingController();
  final FocusNode replyContentFocusNode = FocusNode();
  final GlobalKey _formKey = GlobalKey<FormState>();
  double _keyboardHeight = 0.0; // 键盘高度
  final _debouncer = Debouncer(milliseconds: 100); // 设置延迟时间
  bool ableClean = false;
  Timer? timer;
  Box localCache = GStrorage.localCache;
  late double sheetHeight;

  @override
  void initState() {
    super.initState();
    // 监听输入框聚焦
    // replyContentFocusNode.addListener(_onFocus);
    _replyContentController.addListener(_printLatestValue);
    // 界面观察者 必须
    WidgetsBinding.instance.addObserver(this);
    // 自动聚焦
    _autoFocus();

    sheetHeight = localCache.get('sheetHeight');
  }

  _autoFocus() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (context.mounted) {
      FocusScope.of(context).requestFocus(replyContentFocusNode);
    }
  }

  _printLatestValue() {
    setState(() {
      ableClean = _replyContentController.text != '';
    });
  }

  Future submitReplyAdd() async {
    feedBack();
    String message = _replyContentController.text;
    var result = await VideoHttp.replyAdd(
      type: widget.replyType ?? ReplyType.video,
      oid: widget.oid!,
      root: widget.root!,
      parent: widget.parent!,
      message: widget.replyItem != null && widget.replyItem!.root != 0
          ? ' 回复 @${widget.replyItem!.member!.uname!} : $message'
          : message,
    );
    if (result['status']) {
      SmartDialog.showToast(result['data']['success_toast']);
      Get.back(result: {
        'data': ReplyItemModel.fromJson(result['data']['reply'], ''),
      });
    } else {
      SmartDialog.showToast(result['msg']);
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 键盘高度
      final viewInsets = EdgeInsets.fromViewPadding(
          View.of(context).viewInsets, View.of(context).devicePixelRatio);
      _debouncer.run(() {
        if (mounted) {
          setState(() {
            _keyboardHeight =
                _keyboardHeight == 0.0 ? viewInsets.bottom : _keyboardHeight;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _replyContentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        color: Theme.of(context).colorScheme.background,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(
                  top: 6, right: 15, left: 15, bottom: 10),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: TextField(
                  controller: _replyContentController,
                  minLines: 1,
                  maxLines: null,
                  autofocus: false,
                  focusNode: replyContentFocusNode,
                  decoration: const InputDecoration(
                      hintText: "输入回复内容",
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        fontSize: 14,
                      )),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ),
          Divider(
            height: 1,
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
          Container(
            height: 52,
            padding: const EdgeInsets.only(left: 12, right: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                      onPressed: () {
                        FocusScope.of(context)
                            .requestFocus(replyContentFocusNode);
                      },
                      icon: Icon(Icons.keyboard,
                          size: 22,
                          color: Theme.of(context).colorScheme.onBackground),
                      highlightColor:
                          Theme.of(context).colorScheme.onInverseSurface,
                      style: ButtonStyle(
                        padding: MaterialStateProperty.all(EdgeInsets.zero),
                        backgroundColor:
                            MaterialStateProperty.resolveWith((states) {
                          return Theme.of(context).highlightColor;
                        }),
                      )),
                ),
                const Spacer(),
                TextButton(
                    onPressed: () => submitReplyAdd(), child: const Text('发送'))
              ],
            ),
          ),
          AnimatedSize(
            curve: Curves.easeInOut,
            duration: const Duration(milliseconds: 300),
            child: SizedBox(
              width: double.infinity,
              height: _keyboardHeight,
            ),
          ),
        ],
      ),
    );
  }
}

typedef DebounceCallback = void Function();

class Debouncer {
  DebounceCallback? callback;
  final int? milliseconds;
  Timer? _timer;

  Debouncer({this.milliseconds});

  run(DebounceCallback callback) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds!), () {
      callback();
    });
  }
}
