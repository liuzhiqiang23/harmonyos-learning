# HelloWorld：电影列表（调真实后端）

鸿蒙专业课《移动互联网应用开发》的练手工程：ArkTS + Stage 模型。

首页 `Index.ets` 是一个**带海报的电影列表**，数据来自本机真实运行的 **movie-system**
后端（Spring Boot，8000 端口），支持分页。最早那版 Hello World 保留在 git 历史里（提交 `de42402`）。

现在是三个页面：`Index`（列表 + 搜索）和 `Recommend`（推荐）都可以点进 `VideoDetail`（影片详情）。

## 环境（本机实测）

| 项目 | 值 |
| --- | --- |
| DevEco Studio | 6.0.2 Release，Build 6.0.2.670，装在 `D:\DevEco Studio` |
| HarmonyOS SDK | API 22（HarmonyOS 6.0.2 Release，sdk 版本 6.0.2.130），随 IDE 内置 |
| hvigor / hvigor-ohos-plugin | 6.22.9（内置在 `D:\DevEco Studio\tools\hvigor`） |
| 内置 Node.js | v18.20.1 |
| 界面模型 | Stage 模型（`apiType: stageMode`） |
| 数据源 | movie-system 后端，`http://127.0.0.1:8000` |

## 命令行编译（已实测通过）

不打开 IDE 也能编译，验证环境是否正常很有用：

```bash
cd /d/harmonyos-learning/projects/HelloWorld
export DEVECO_SDK_HOME="D:\DevEco Studio\sdk"
"/d/DevEco Studio/tools/node/node.exe" "/d/DevEco Studio/tools/hvigor/bin/hvigorw.js" \
    assembleHap --mode module -p product=default -p module=entry@default --no-daemon
```

产物：`entry/build/default/outputs/default/entry-default-unsigned.hap`

> `WARN: No signingConfig found for product default` 是**预期**的：命令行默认产出未签名 HAP。
> 要装到真机/模拟器才需要签名（需登录华为账号，IDE 里 Project Structure → Signing Configs）。

## 联调运行

1. **先启动 movie-system 后端**（8000 端口），自己先验证一下它活着：

   ```bash
   curl -X POST http://127.0.0.1:8000/api/admin/video/page/list \
        -H "Content-Type: application/json" -d "{\"pageIndex\":1,\"pageSize\":2}"
   ```

   能返回 JSON 才往下走。
2. **再跑鸿蒙端**：IDE 里 `File > Reload All from Disk`（我是在 IDE 外面改的文件，不 reload 看不到新代码），
   然后点预览器刷新。
3. 界面上会出现：标题「电影列表」→ 状态行（`第 1 / 246 页，共 4908 部`）→ 带海报的列表 → 上一页 / 下一页。

### 用到的接口

| 用途 | 请求 | 说明 |
| --- | --- | --- |
| 列表 | `POST /api/admin/video/page/list`，体 `{"pageIndex":1,"pageSize":20}` | 字段名是 **pageIndex**；写成 `pageNum` 后端会 500 NPE |
| 详情 | `POST /api/admin/video/getVideoDetailByVideoId/{videoId}`，**无请求体** | 匿名可用（同组的 `select/{id}` 要登录态，会 500，别用）。返回片名/原名/简介/tagline/评分/热度/上映日期/播放记录 |
| 海报 | `GET /posters/{videoId}.jpg` | `videoId` 就是 **TMDB 影片 ID**，海报是后端 `static/posters` 下的本地文件 |

### 三个必须知道的坑

1. 返回结构是 `{code, message, response}`，**`code === 1` 才是成功**（不是 0）。业务错误也带
   HTTP 200 返回，所以**只看 HTTP 状态码会误判**。
2. **不是每部电影都有海报**（本地 4891 张 vs 4908 部）。缺图时 `/posters/xxx.jpg` 返回的不是 404，
   而是一段 200 的 JSON 错误，图片解码会失败——所以 `Image` 上挂了 `.alt($r('app.media.icon'))` 兜底。
3. 数据库里的 `poster_path` 字段（TMDB 的 hash 路径）是**死数据**，实测直接返回
   "No static resource"，不要用它拼图片地址。

**如果状态行显示 `请求失败`**：读 `JSON.stringify(err)` 里的 `code`。
`2300997` = 明文 HTTP 被拦截（加 `network_config.json` 放开 cleartext，本项目默认没加，因为默认允许）；
其他大多是后端没启动 / 端口被占 / 地址写错。

### 搜索与推荐页（顺便练 router 页面跳转）

- 首页顶部有**搜索框**：走同一个 `page/list` 接口，多传 `videoName` 字段（后端模糊匹配）。输入留空点搜索 = 显示全部。
- 右上角「猜你喜欢」→ 跳转 `pages/Recommend`（`router.pushUrl`；页面必须先在
  `resources/base/profile/main_pages.json` 里注册，漏了会直接白屏报路由找不到）。
- 推荐接口 `POST /api/recommend`，`algo` 必填：
  - `demographic` 热门推荐，不用参数，最快；
  - `content` 相似电影，**只认英文原名**——输中文名会报 `Movie title not found in dataset`（算法数据集是英文的）；
  - `user_knn / svd / knn_svd` 还要传 `userId`。
- 推荐是**现场拉起 Python 引擎**算的，比普通接口慢一个量级，所以 `readTimeout` 给到 60s。
- `router` 在新 API 里已标 deprecated（官方推 Navigation），但教材用的就是 router，先沿用，编译只有 WARN 没有错。

### 详情页（列表和推荐都能点进去）

- `pages/VideoDetail.ets`。跳转靠 `router.pushUrl({ url: 'pages/VideoDetail', params: { videoId: m.videoId } })`，
  详情页再用 `router.getParams()` 把参数取回来。**列表里的 `videoId` 和推荐里的 `movieId` 是同一个东西**
  （TMDB 影片 ID），和海报文件名也是同一个号，所以两个入口能共用一页。
- 两个入口传参：列表项、推荐项各自点一下即可；列表项右侧的 `›` 是"可以点"的提示。
- 推荐数据集里可能有库里没收录的片子，点进去会显示「视频不存在」——后端这时返回的是
  **`code=404` 而不是 HTTP 404**，所以 `responseCode` 和 `code` 两层都得判。
- **这里有个值得记的坑**：这个接口是 POST 但没有请求体，如果给 `extraData` 传空字符串 `''`，
  HarmonyOS 的 http 会直接抛 `401 Parameter error`（**是鸿蒙自己的参数校验错误码，不是 HTTP 401**，
  很容易看岔）。改成 `extraData: '{}'` 就通了。后端没有 `@RequestBody`，请求体会被忽略。
- 详情接口不返回 `videoUrl`，而且这批影片的 `videoUrl` 本来就是 null（只存了 TMDB 元数据，
  没有实际视频文件），所以详情页只做信息展示，不做播放器。

## 部署到模拟器（免签名，一键脚本）

**模拟器不需要华为账号、也不需要签名**——用 `hdc` 直接装未签名 HAP 就能跑（实测通过）。
项目根目录有个一键脚本：

```
install-to-device.cmd      编译 → 安装 → 启动，三步一次搞定
```

它内部等价于：

```bash
hvigor assembleHap ...                                        # 编译
hdc install -r entry\build\default\outputs\default\entry-default-unsigned.hap
hdc shell "aa start -a EntryAbility -b com.liuzhiqiang.helloworld"
```

**两个 Git Bash 的坑**（在 cmd 里跑脚本不受影响，手动敲命令会遇到）：

- `hdc file recv /data/...` 里的 `/data/...` 会被 MSYS 改写成 `C:/Program Files/Git/data/...`，
  必须加 `MSYS_NO_PATHCONV=1`；
- 路径参数要用反斜杠，PowerShell/Windows API 只吃反斜杠。

**从命令行看模拟器画面**（不用截屏工具，也不需要视觉）：

```bash
hdc shell "snapshot_display -f /data/local/tmp/shot.jpeg"
MSYS_NO_PATHCONV=1 hdc file recv /data/local/tmp/shot.jpeg D:\DevEco\shots\emu_shot.jpeg
```

> IDE 里点绿色 **Run** 走的是另一条路：要求签名、要登录华为账号。所以**模拟器调试用这个脚本更省事**；
> 只有装**真机**才必须签名。

### 离线兜底

`backend-demo/`（仓库根目录）里有一个纯标准库的 toy 后端，返回 8 条假电影。
movie-system 没启动时可以用它练手，但要改 `Index.ets` 的 `API_BASE` 和解析结构，两者接口形状不同。

## 目录说明

```
entry/src/main/ets/entryability/EntryAbility.ets   UIAbility 生命周期入口
entry/src/main/ets/pages/Index.ets                 首页：电影列表 + 搜索（调 movie-system）
entry/src/main/ets/pages/Recommend.ets             推荐页：热门推荐 / 相似电影
entry/src/main/ets/pages/VideoDetail.ets           详情页：片名/原名/简介/评分/上映日期
entry/src/main/module.json5                        模块配置（abilities/pages/权限）
entry/src/main/resources/base/                     本模块字符串/颜色/尺寸/图标
AppScope/app.json5                                 应用级配置（bundleName/版本/图标）
entry/build-profile.json5                          模块级构建配置
build-profile.json5                                工程级构建配置（SDK 版本、product）
```

## 可以动手改的地方

- `Index.ets` 顶部 `API_BASE` 改成局域网地址，可以用真机调试（手机和电脑同一 WiFi）。
- 列表接口的请求体支持 `videoName` 字段做模糊搜索——加个输入框就能实现搜索。
- `PAGE_SIZE` 现在是 20，改成 50 体验一下。
- `AppScope/app.json5` 的 `bundleName` 按学校要求改（当前 `com.liuzhiqiang.helloworld`）。
- `entry/src/main/resources/base/element/string.json` 的 `EntryAbility_label` 是桌面图标名。
