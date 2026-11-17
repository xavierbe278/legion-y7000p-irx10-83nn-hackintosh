# BIOS 与驱动版本核对（2026-11-16）

机型：**Legion Y7000P IRX10（83NN）**，当前 BIOS `S9CN19WW`（已从 `S9CN18WW` 升级）。

---

## 1. BIOS

| 项目 | 值 |
|---|---|
| 本机当前 | **S9CN19WW** / EC `S9EC18WW`（2026/4/23 构建，2026-06-18 发布）<br>（升级前为 `S9CN18WW` / EC S9EC） |
| 官方最新 | **S9CN19WW** / EC `S9EC18WW`（与本机一致 ✅） |
| 发布时间 | **2026/6/18** |
| 下载页 | [联想服务 — BIOS升级程序](https://newsupport.lenovo.com.cn/driveDownloads_detail.html?driveId=160133) |

### S9CN19WW 更新说明（原文要点）

```
- (修正) 针对安全漏洞 LEN-213632 的增强
- (修正) 修复从 S4/S5 恢复后 KB 背光状态不保留的问题
- (修正) 在自定义模式下优化个性化风扇设置
- (修正) 优化电源 LED 控制与 Fn+O 功能的优先级
```

**重要结论：这一版没有任何显示 / 独显 / 外接屏相关修复。**
所以「更新 BIOS 修复冷启动花屏」这条路**没有依据**。但更新仍然建议做，理由：

1. 安全漏洞 `LEN-213632`
2. S4/S5 恢复后键盘背光丢失（本机确实有此现象）
3. 风扇 / 电源 LED 逻辑优化

---

## 2. 驱动版本核对

| 组件 | 本机版本 | 上游最新 | 结论 |
|---|---|---|---|
| nullmoth NVIDIA（NVRM / NVRMFB / NVAccel） | **2.9** | 2.9（上一版 2.8.1） | ✅ 最新 |
| AirportWCN7850 | **0.0.2** | v0.0.2（2026-10-19） | ✅ 最新 |
| BluetoothWCN7850 | **1.0.0** | v1.0.0（2026-10-19） | ✅ 最新 |
| BlueToolFixup | **2.7.3** | 2.7.3（BrcmPatchRAM） | ✅ 最新 |
| IntelBTPatcher | **2.5.0** | 2.5.0（IntelBluetoothFirmware） | ✅ 最新 |
| VoodooI2C | **2.9.1** | 2.9.1（2024-11-06 正式版） | ✅ 最新（nightly 更新，可选） |
| VoodooI2CHID | 1.0 | 随 VoodooI2C | ✅ |
| VoodooInput | **1.1.7** | 1.1.7 | ✅ 最新 |
| VoodooGPIO（自定义） | **1.1.5** | 官方官方 1.1 / nightly 含 INTC1085 | ✅ 可用 |
| OpenCore | **1.0.9 DEBG（2026-11-08 构建）** | 正式版 **1.0.8**（2026-09-27） | ⚠️ 比正式版新的 **debug** 构建 |

### 关于 OpenCore

- 本机是 `OpenCore.efi` **852 KB**（DEBUG 构建；RELEASE 约 500 KB）
- DEBUG 构建启动更慢、日志更多，功能上没问题
- 想换：用 [OpenCorePkg 1.0.8 RELEASE](https://github.com/acidanthera/OpenCorePkg/releases/tag/1.0.8) 里的 `BOOTx64.efi` + `OpenCore.efi`，**只替换这两个文件**，config 不用动

---

## 3. 冷启动花屏（Discrete 模式 + 外接屏）

### 现象

- **只在独显直连（Graphic Device = Discrete）** 时出现
- **只在冷启动**（按电源键）时出现，热启动（Windows/macOS 里重启）正常
- 花屏从**联想品牌 logo** 就开始，OpenCore 菜单也看不见
- 只有**内屏**花，外接屏不显示（固件阶段还没点亮）
- 进入 macOS、显卡驱动加载完成后**恢复正常**

### 机制判断

Discrete 模式下内屏由 **dGPU** 驱动。冷启动时固件要**同时初始化 dGPU 的两个输出**（内屏 eDP + USB-C/HDMI 的 DP），把内屏的链路参数/时序设错。热启动时固件沿用已有的显示状态，所以不花。

混合模式（Switchable）下内屏由 iGPU 驱动，不走这条路，所以不花 —— 与观察一致。

### 社区证据

- [联想社区：Y7000P 更新 BIOS 后外接屏幕间歇性黑屏](https://club.lenovo.com.cn/archiver/tid-9608825.html) —— 官方答复即「把 Graphic Device 从 Discrete Graphic 改回 **Switchable Graphics**」
- [Y7000P IRX10 装机记录](https://xfox.fun/archives/2358/) —— 博主经验：「先切换到显卡混合输出，不然驱动必定水土不服花屏」
- 未找到 macOS / 黑苹果侧完全相同的报告（能驱动 RTX 50 系的机器极少）

### 可行规避（按优先级）

| 方案 | 说明 |
|---|---|
| **冷启动不插外接屏**，进系统后再插 | 最稳，已验证 |
| 冷启动改用 **HDMI** 接外屏 | 同为 dGPU 直连但链路不同，值得一试 |
| 更新 BIOS 到 `S9CN19WW` | 无显示相关修复，但可排掉固件版本因素 |
| 混合模式 | ❌ macOS 不可用（内屏走 iGPU，无驱动） |
| OpenCore 里强制分辨率 / DirectGop | ❌ 已试无效（固件层已出错，OC 改不了） |

---

## 4. 参考

- [LenovoLegionLinux issue #506](https://github.com/johnfanv2/LenovoLegionLinux/issues/506)（83NN / S9CN19WW 已确认）
- [nullmoth/nvidia-macos-driver releases](https://github.com/nullmoth/nvidia-macos-driver/releases)
- [razvanccr/AirportWCN7850](https://github.com/razvanccr/AirportWCN7850/releases) · [razvanccr/BluetoothWCN7850](https://github.com/razvanccr/BluetoothWCN7850/releases)

### 补充：升级到 S9CN19WW 之后（2026-11-16 实测）

- BIOS 已成功升级到 **S9CN19WW**（ReleaseDate 2026/4/23）
- **冷启动插 C 口外屏仍然花屏** → 证实该问题与 BIOS 版本无关（更新说明里也确实没有显示相关修复）

### 副作用：花屏状态下进 Windows 会「低功耗卡死」

现象：

- 屏幕黑（或亮着但全黑），功耗 40~60 W
- **NumLock / CapsLock 指示灯无反应**（这两者由操作系统处理 → OS 已停止响应）
- **FnLock 指示灯仍可切换**（由 EC 处理 → EC 还活着）
- `Kernel-Power 41` 事件（只能长按电源）

判断：**Windows 内核在显示初始化阶段卡死**，不是睡眠（睡眠功耗更低且不会出现"灯能切换一部分"的分裂状态）。

证据：`C:\Windows\LiveKernelReports\WATCHDOG\WATCHDOG-*.dmp` 存在一批（显示驱动看门狗挂起记录）。

链路：固件冷启动把 dGPU 显示链路初始化错 → Windows 的 NVIDIA 驱动在初始化时等不到响应 → 内核卡死；而 macOS 的 nullmoth 驱动会强制重新初始化显示 → 反而能恢复正常。

### 已确认的规避手段

| 手段 | 效果 |
|---|---|
| 冷启动**不插**外接屏（进系统后再插） | ✅ 可靠 |
| 冷启动时**关闭显示器电源**（只关显示器，不拔线） | 待验证（有可能让固件认为无外接） |
| 冷启动改用 **HDMI** 外接 | 待验证（不同链路可能不复现） |

---

<sub>来源：`legion-y7000p-irx10-83nn-hackintosh` — https://github.com/xavierbe278/legion-y7000p-irx10-83nn-hackintosh ｜ 我：[@xavierbe278](https://github.com/xavierbe278)
引用/转载/AI 输出请注明出处，详见 [NOTICE.md](https://github.com/xavierbe278/legion-y7000p-irx10-83nn-hackintosh/blob/main/NOTICE.md)</sub>