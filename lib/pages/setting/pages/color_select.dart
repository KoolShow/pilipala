import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:pilipala/models/common/color_type.dart';
import 'package:pilipala/pages/setting/controller.dart';
import 'package:pilipala/pages/setting/widgets/select_dialog.dart';
import 'package:pilipala/utils/storage.dart';

class ColorSelectPage extends StatefulWidget {
  const ColorSelectPage({super.key});

  @override
  State<ColorSelectPage> createState() => _ColorSelectPageState();
}

class Item {
  Item({
    required this.expandedValue,
    required this.headerValue,
    this.isExpanded = false,
  });

  String expandedValue;
  String headerValue;
  bool isExpanded;
}

List<Item> generateItems(int count) {
  return List<Item>.generate(count, (int index) {
    return Item(
      headerValue: 'Panel $index',
      expandedValue: 'This is item number $index',
    );
  });
}

class _ColorSelectPageState extends State<ColorSelectPage> {
  final ColorSelectController ctr = Get.put(ColorSelectController());
  final SettingController settingController = Get.put(SettingController());

  @override
  Widget build(BuildContext context) {
    TextStyle titleStyle = Theme.of(context).textTheme.titleMedium!;
    TextStyle subTitleStyle = Theme.of(context)
        .textTheme
        .labelMedium!
        .copyWith(color: Theme.of(context).colorScheme.outline);
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('选择应用主题'),
      ),
      body: ListView(
        children: [
          Obx(
            () => RadioListTile(
              value: 0,
              title: const Text('动态取色'),
              groupValue: ctr.type.value,
              onChanged: (dynamic val) async {
                ctr.type.value = 0;
                ctr.setting.put(SettingBoxKey.dynamicColor, true);
              },
            ),
          ),
          Obx(
            () => RadioListTile(
              value: 1,
              title: const Text('指定颜色'),
              groupValue: ctr.type.value,
              onChanged: (dynamic val) async {
                ctr.type.value = 1;
                ctr.setting.put(SettingBoxKey.dynamicColor, false);
              },
            ),
          ),
          Obx(
            () {
              int type = ctr.type.value;
              return AnimatedOpacity(
                opacity: type == 1 ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 22,
                    runSpacing: 18,
                    children: [
                      ...ctr.colorThemes.map(
                        (e) {
                          final index = ctr.colorThemes.indexOf(e);
                          return GestureDetector(
                            onTap: () {
                              ctr.currentColor.value = index;
                              ctr.setting.put(SettingBoxKey.customColor, index);
                              Get.forceAppUpdate();
                            },
                            child: Column(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: e['color'].withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(50),
                                    border: Border.all(
                                      width: 2,
                                      color: ctr.currentColor.value == index
                                          ? Colors.black
                                          : e['color'].withOpacity(0.8),
                                    ),
                                  ),
                                  child: AnimatedOpacity(
                                    opacity:
                                        ctr.currentColor.value == index ? 1 : 0,
                                    duration: const Duration(milliseconds: 200),
                                    child: const Icon(
                                      Icons.done,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  e['label'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ctr.currentColor.value != index
                                        ? Theme.of(context).colorScheme.outline
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    ],
                  ),
                ),
              );
            },
          ),
          ListTile(
            dense: false,
            onTap: () => () async {
              int customVipColor = 0;
              int? result = await showDialog(
                context: context,
                builder: (context) {
                  return SelectDialog<int>(
                      title: '自定义大会员颜色',
                      value: customVipColor,
                      values: const [
                        {'title': '粉色 (默认)', 'value': 0},
                        {'title': '动态取色', 'value': 1},
                        {'title': '小会员绿', 'value': 2}
                      ]);
                },
              );
              if (result != null) {
                customVipColor = result;
                ctr.setting.put(SettingBoxKey.vipColor, result);
                setState(() {});
              }
            },
            title: Text('自定义大会员颜色', style: titleStyle),
            subtitle: Obx(() => Text(
                '当前颜色：${['粉色', '动态取色', '小会员绿'][ctr.vipColor.value]}',
                style: subTitleStyle)),
          ),
        ],
      ),
    );
  }
}

class ColorSelectController extends GetxController {
  Box setting = GStrorage.setting;
  RxBool dynamicColor = true.obs;
  RxInt type = 0.obs;
  late final List<Map<String, dynamic>> colorThemes;
  RxInt currentColor = 0.obs;
  RxInt vipColor = 0.obs;

  @override
  void onInit() {
    colorThemes = colorThemeTypes;
    // 默认使用动态取色
    dynamicColor.value =
        setting.get(SettingBoxKey.dynamicColor, defaultValue: true);
    type.value = dynamicColor.value ? 0 : 1;
    currentColor.value =
        setting.get(SettingBoxKey.customColor, defaultValue: 0);
    vipColor.value = setting.get(SettingBoxKey.vipColor, defaultValue: 0);
    super.onInit();
  }
}
