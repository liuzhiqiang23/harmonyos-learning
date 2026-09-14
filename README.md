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
| DevEco Studio | 6.0.2.670 Release（2026-08-31，HarmonyOS 6 / NEXT 线） |
| 开发语言 | ArkTS（Stage 模型） |
| 机器 | Windows 11 / 16GB（模拟器吃紧时用远程模拟器） |

> 教材若基于旧 API（API 9 / FA 模型），以 DevEco 最新版 + Stage 模型写法为准。

## 常用命令

```bash
# 双推（GitHub + Gitee）
git push origin main

# 只推某一家
git push github main
git push gitee  main
```

## 相关资源

- 官方文档：https://developer.huawei.com/consumer/cn/doc/
- 官方案例库（DevEco 插件可导入）：https://gitee.com/HarmonyOS-Cases/Cases
- Codelabs 实操教程：https://developer.huawei.com/consumer/cn/codelabsPortal/serviceTypes/43
- 认证：HCIA-HarmonyOS Application Developer
