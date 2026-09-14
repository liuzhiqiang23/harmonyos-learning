# HelloWorld（Empty Ability 模板工程）

鸿蒙专业课《移动互联网应用开发》的起步工程：ArkTS + Stage 模型。

首页已从"Hello World"扩成了**列表页 + 调本机后端**的练习（`Index.ets`）：页面创建时用
`@kit.NetworkKit` 的 http 请求本机 `http://127.0.0.1:8787/api/movies`，把返回的 JSON
渲染成列表。最早那版 Hello World 保留在 git 历史里（提交 `de42402`）。

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

## 联调运行（列表页 + 后端）

1. **先启动后端**：双击 `D:\harmonyos-learning\backend-demo\start-server.cmd`
   （或用命令行 `python server.py`）。看到"后端已启动"就对了。
   - 先自己用浏览器打开 `http://127.0.0.1:8787/` 确认有数据，**后端不通就不要往下走**。
2. **再跑鸿蒙端**：IDE 里打开本工程，点预览器的刷新按钮重新预览。
3. 界面上会依次出现：标题「电影列表」→ 一行状态（`正在请求...` → `成功：从服务器拿到 8 条数据`）
   → 一个「重新加载」按钮 → 8 条电影。

**如果状态那行显示 `请求失败`**，先把 `JSON.stringify(err)` 里的 `code` 读出来：

- `2300997` = 明文 HTTP 被拦截，需要在 `entry/src/main/resources/base/profile/` 下加
  `network_config.json` 放开 cleartext（本项目默认没加，因为默认是允许的）；
- 其他情况大多是后端没启动 / 端口被占 / 地址写错。

## 可以动手改的地方

- `Index.ets` 里 `@State message` 改成自己的学号姓名，`Text(this.message)` 会跟着变。
- `AppScope/app.json5` 的 `bundleName` 按学校要求改（当前 `com.liuzhiqiang.helloworld`）。
- `entry/src/main/resources/base/element/string.json` 的 `EntryAbility_label` 就是桌面图标名。
