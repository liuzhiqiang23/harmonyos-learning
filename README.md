# harmonyos-learning

HarmonyOS 应用开发学习仓库 —— 专业课《移动互联网应用开发》（教材：HarmonyOS 应用开发基础）配套。

双平台托管：GitHub + Gitee（`git push origin main` 一次推两端）。

## 目录规划

```
harmonyos-learning/
├── notes/          # 课程/学习笔记（Markdown）
├── projects/       # DevEco Studio 工程（每章/每个练手项目一个子目录）
├── codelabs/       # 华为官方 Codelabs 跟练记录
└── README.md
```

## 环境

| 项 | 版本/说明 |
|----|-----------|
| DevEco Studio | 6.0.2 Release / Build 6.0.2.670（2026-08-31），装在 `D:\DevEco Studio` |
| HarmonyOS SDK | API 22（HarmonyOS 6.0.2 Release，SDK 6.0.2.130），随 IDE 内置，无需另下 |
| hvigor | 6.22.9（内置 `tools\hvigor`）；内置 Node.js v18.20.1 |
| 开发语言 | ArkTS（Stage 模型） |
| 机器 | Windows 11 / 16GB（模拟器吃紧时用远程模拟器） |

> 教材若基于旧 API（API 9 / FA 模型），以 DevEco 最新版 + Stage 模型写法为准。

## 工程

| 工程 | 说明 |
|------|------|
| [projects/HelloWorld](projects/HelloWorld) | ArkTS + Stage 模型 Empty Ability 起步工程（API 22），命令行 `assembleHap` 编译已通过 |

## 常用命令

```bash
# 双推（GitHub + Gitee）
git push origin main

# 只推某一家
git push github main
git push gitee  main

# 命令行编译工程（不开 IDE，用来验证环境）
cd projects/HelloWorld
export DEVECO_SDK_HOME="D:\DevEco Studio\sdk"
"/d/DevEco Studio/tools/node/node.exe" "/d/DevEco Studio/tools/hvigor/bin/hvigorw.js" \
    assembleHap --mode module -p product=default -p module=entry@default --no-daemon
```

## 相关资源

- 官方文档：https://developer.huawei.com/consumer/cn/doc/
- 官方案例库（DevEco 插件可导入）：https://gitee.com/HarmonyOS-Cases/Cases
- Codelabs 实操教程：https://developer.huawei.com/consumer/cn/codelabsPortal/serviceTypes/43
- 认证：HCIA-HarmonyOS Application Developer
