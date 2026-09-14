# HelloWorld（Empty Ability 模板工程）

鸿蒙专业课《移动互联网应用开发》的第一个工程：ArkTS + Stage 模型的标准 Empty Ability。

## 环境（本机实测）

| 项目 | 值 |
| --- | --- |
| DevEco Studio | 6.0.2 Release，Build 6.0.2.670，装在 `D:\DevEco Studio` |
| HarmonyOS SDK | API 22（HarmonyOS 6.0.2 Release，sdk 版本 6.0.2.130），随 IDE 内置 |
| hvigor / hvigor-ohos-plugin | 6.22.9（内置在 `D:\DevEco Studio\tools\hvigor`） |
| 内置 Node.js | v18.20.1 |
| 界面模型 | Stage 模型（`apiType: stageMode`） |

## 用 IDE 打开

DevEco Studio → `File > Open` → 选本目录（`D:\harmonyos-learning\projects\HelloWorld`）。
首次打开会提示同步（Sync），完成后点右上角 Previewer 或选设备运行。

## 命令行编译（已实测通过）

不打开 IDE 也能编译，验证环境是否正常很有用：

```bash
cd /d/harmonyos-learning/projects/HelloWorld
export DEVECO_SDK_HOME="D:\DevEco Studio\sdk"
"/d/DevEco Studio/tools/node/node.exe" "/d/DevEco Studio/tools/hvigor/bin/hvigorw.js" \
    assembleHap --mode module -p product=default -p module=entry@default --no-daemon
```

产物：`entry/build/default/outputs/default/entry-default-unsigned.hap`

> 注意 `WARN: No signingConfig found for product default`：这是**预期**的。
> 命令行默认产出未签名 HAP；要装到真机/模拟器需要签名，签名要登录华为账号，
> 在 IDE 里用 `File > Project Structure > Signing Configs` 勾选 `Automatically generate signature` 即可。

## 目录说明

```
entry/src/main/ets/entryability/EntryAbility.ets   UIAbility 生命周期入口
entry/src/main/ets/pages/Index.ets                 首页（@Entry @Component）
entry/src/main/module.json5                        模块配置（abilities/pages/权限）
entry/src/main/resources/base/                     本模块字符串/颜色/尺寸/图标
AppScope/app.json5                                 应用级配置（bundleName/版本/图标）
entry/build-profile.json5                          模块级构建配置
build-profile.json5                                工程级构建配置（SDK 版本、product）
```

## 可以动手改的地方

- `Index.ets` 里 `@State message` 改成自己的学号姓名，`Text(this.message)` 会跟着变。
- `AppScope/app.json5` 的 `bundleName` 按学校要求改（当前 `com.liuzhiqiang.helloworld`）。
- `entry/src/main/resources/base/element/string.json` 的 `EntryAbility_label` 就是桌面图标名。
