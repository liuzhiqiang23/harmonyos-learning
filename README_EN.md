# harmonyos-learning

**[中文](./README.md) | English**

A learning repository for HarmonyOS app development, accompanying the university course “Mobile Internet Application Development” and the textbook *Fundamentals of HarmonyOS App Development*.

The repository is mirrored on GitHub and Gitee. A single **git push origin main** publishes to both platforms.

- [Gitee mirror](https://gitee.com/liu-zhiqiang20030520/harmonyos-learning)
- [GitHub repository](https://github.com/liuzhiqiang23/harmonyos-learning)

## Repository layout

~~~text
harmonyos-learning/
├── notes/       # Course and study notes in Markdown
├── projects/    # DevEco Studio projects, one per chapter or exercise
├── codelabs/    # Notes from Huawei's official Codelabs
└── README.md
~~~

## Environment

| Component | Version / notes |
|---|---|
| DevEco Studio | 6.0.2 Release / Build 6.0.2.670 (2026-08-31) |
| HarmonyOS SDK | API 22 (HarmonyOS 6.0.2 Release, SDK 6.0.2.130); bundled with the IDE |
| hvigor | 6.22.9, bundled under tools/hvigor; bundled Node.js v18.20.1 |
| Language | ArkTS, Stage model |
| Machine | Windows 11 / 16 GB RAM; use a remote emulator if the local emulator is slow |

For course material written for an older API (API 9 / FA model), use the latest DevEco Studio and Stage-model conventions as the reference.

## Projects

| Project | Description |
|---|---|
| [projects/HelloWorld](projects/HelloWorld) | Starter Empty Ability project in ArkTS and the Stage model (API 22); the assembleHap command-line build has succeeded. |

## Common commands

~~~bash
# Push to both GitHub and Gitee
git push origin main

# Push to one host only
git push github main
git push gitee main

# Build from the command line without opening the IDE
cd projects/HelloWorld
export DEVECO_SDK_HOME="<DevEco Studio SDK path>"
"<DevEco Studio>/tools/node/node.exe" "<DevEco Studio>/tools/hvigor/bin/hvigorw.js" \
  assembleHap --mode module -p product=default -p module=entry@default --no-daemon
~~~

## Resources

- [Huawei developer documentation](https://developer.huawei.com/consumer/en/doc/)
- [Official sample repository](https://gitee.com/HarmonyOS-Cases/Cases), importable from the DevEco plugin
- [Official Codelabs](https://developer.huawei.com/consumer/cn/codelabsPortal/serviceTypes/43)
- Certification: HCIA-HarmonyOS Application Developer
