# Legion Y7000P IRX10 · macOS 26 黑苹果记录

联想拯救者 **Legion Y7000P IRX10（机型代码 83NN）** 的黑苹果完整记录：硬件、EFI 配置、逐项踩坑与解决方案、备份与恢复。

> 本仓库包含**主记录 + 索引**（硬件、EFI 配置、踩坑与解决方案、备份恢复），具体子方案分散在独立仓库里：
> [触控板](https://github.com/xavierbe278/legion-y7000p-irx10-touchpad-voodooi2c) · [Wi-Fi / 蓝牙](https://github.com/xavierbe278/legion-y7000p-irx10-qcm865-wcn7850-wifi-bt) · [USB 外设](https://github.com/xavierbe278/legion-y7000p-irx10-usb-receiver-freeze)

---

## 目录

- [0. 这个仓库里有什么（可直接用）](#0-这个仓库里有什么可直接用)
- [1. 硬件](#1-硬件) · [1.1 改装记录](#11-改装记录与出厂配置的差异)
- [2. 系统与引导](#2-系统与引导)（boot-args / Kernel / NVRAM / ACPI）
- [3. 逐项问题与解决方案](#3-逐项问题与解决方案)
- [4. 备份与恢复](#4-备份与恢复)
- [5. 已知限制](#5-已知限制)
- [6. 参考](#6-参考)

## 0. 这个仓库里有什么（可直接用）

| 文件 | 用途 | 说明 |
|---|---|---|
| **`EFI-OC-sanitized.zip`** | **完整的 EFI/OC 打包**（含 ACPI、Kexts、Drivers、Tools、去隐私 config） | 解压后直接替换 `EFI/OC`，别忘自己填三码 |
| `configs/config.sanitized.plist` | 我当前在用的完整 OpenCore 配置 | **已清空序列号 / MLB / SystemUUID / ROM**，用之前自己填三码 |
| `patches/SSDT-PTSFix.aml` | 关机修复 SSDT（`_PTS→ZPTS` + 清 XHCI `PMEE`） | 直接放进 `EFI/OC/ACPI` 并在 config 里启用 |
| `scripts/fix-windows-time.ps1` | 双系统时间差 8 小时修复 | Windows 管理员 PowerShell 运行 |
| `scripts/esp-helper.ps1` | Windows 下挂载 / 读 / 写 EFI 分区 | 管理员运行，`mount/write/dump/unmount` |
| `docs/踩坑记录.md` | 从装不上到日常可用的完整排查过程 | 20+ 条 |
| `docs/BIOS与驱动版本.md` | BIOS 版本核对、驱动版本审计、冷启动花屏分析 | 含社区来源 |

> **隐私说明**：本仓库所有文件都**不含**序列号、MLB、SystemUUID、ROM（MAC 地址）等唯一标识。
> `config.sanitized.plist` 里这几个字段是空字符串，需要你用 OpenCore Configurator / GenSMBIOS 自己生成。


## 1. 硬件

| 部件 | 型号 | macOS 状态 |
|---|---|---|
| 机型 | Lenovo Legion Y7000P IRX10（83NN） | — |
| BIOS | `S9CN19WW`（2026/4/23 构建，2026-06-18 发布） | — |
| CPU | Intel Core i9-14900HX（24 核 32 线程，Raptor Lake-HX） | ✅ |
| 独显 | NVIDIA RTX 5060 Laptop 8GB（`10DE:2D59`） | ✅ nullmoth 2.9，Metal 4 |
| 核显 | Intel UHD Graphics（Raptor Lake-S） | ❌ macOS 不支持，忽略 |
| 内存 | 32GB DDR5-5600（Samsung 2×16GB） | ✅ |
| 内屏 | 16" 2560×1600 **240Hz** IPS（eDP 直连 dGPU）<br>EDID：`0x51A1:8249` | ✅ HiDPI / 240Hz |
| Wi-Fi | **已更换**：Qualcomm **QCM865**（FastConnect 7800 / WCN7850 系列，`17CB:1107`，PCIe）<br>（原装为 MediaTek **MT7925**，`14C3:7925`；社区有方案，本项目未研究） | ✅ 802.11ac 80MHz |
| 蓝牙 | 同卡蓝牙（`0489:E10A`，走 USB，随 WCN7850 一起换上的） | ✅ |
| 有线网卡 | Realtek **RTL8111/8168**（`10EC:8168`） | ✅ |
| 声卡 | Realtek **ALC257**（`10EC:0257` / `17AA:8033`，走 Intel SST） | ✅ AppleALC + SimpleHDA（layout-id **99**） |
| 触控板 | **Goodix GXTP5100**（ACPI `TPD0`，`_CID PNP0C50`）<br>I2C：`\_SB.PC00.I2C5`（PCI `00:15.3`，dev-id `0x7A7C`）<br>GPIO：`INTC1085` / IRQ **8** | ✅ 含手势 |
| 键盘 | PS/2（`IDEA0100`）<br>RGB 控制器：**ITE 8258**（`048D:C195`，USB） | ✅ |
| 存储 | **原装** UMIS 1TB RPJYJ1T24MML1AWY（数据盘）<br>**加装** Samsung 990 PRO 2TB（系统盘）：<br>Windows11 26H2 + macOS Tahoe 26.7.3（128GiB APFS） | ✅ |
| 摄像头 | Integrated Camera（`174F:246F`，`Integrated Camera`） | ✅ 可识别 |

## 1.1 改装记录（与出厂配置的差异）

| 部件 | 出厂原装 | 现在 | 原因 |
|---|---|---|---|
| **无线网卡** | MediaTek **MT7925**（Wi-Fi 7，`14C3:7925`，M.2 2230） | **Qualcomm WCN7850 / FastConnect 7800** | 本项目**未研究 MT7925**（换卡后才开始折腾）；当时选择 WCN7850 是因为有现成驱动 [AirportWCN7850](https://github.com/razvanccr/AirportWCN7850)。MT7925 社区亦有方案，见 [Wi-Fi 仓库](https://github.com/xavierbe278/legion-y7000p-irx10-qcm865-wcn7850-wifi-bt) |
| **第二块硬盘** | 无（原单盘 UMIS 1TB） | **加装** Samsung 990 PRO 2TB | 双系统：Windows11 26H2 + macOS Tahoe 26.7.3 |
| 内存 | 16GB DDR5-5600 | 32GB DDR5-5600（2×16GB Samsung） | — |

> 说明：本仓库所有「Wi-Fi / 蓝牙」相关步骤都是针对**换装后的 WCN7850** 写的；
> **关于 MT7925**：这张卡我买来就换掉了，**没做过研究，也用不上**。如果你还在用原装卡，可以去 [Wi-Fi 仓库](https://github.com/xavierbe278/legion-y7000p-irx10-qcm865-wcn7850-wifi-bt) 看第三方方案（我未验证）。

### 磁盘布局（OpenCore 引导）

- Samsung 990 PRO = Windows 的 **disk 1**；macOS 里是 **disk0**，其 ESP 为 `disk0s1`
- 引导方式：把 `EFI/Microsoft/Boot/bootmgfw.efi` 替换为 OpenCore，F12 即可见、可设为默认

---

## 2. 系统与引导

| 项目 | 值 |
|---|---|
| macOS | 26.7.3（25G342） |
| OpenCore | 1.0.9（DBG-109-2026-11-08） |
| SMBIOS | MacBookPro16,2 |
| 日志开关 | `Misc > Debug > Target = 0`（最快启动，无日志）；排查时改 67 |
| ScanPolicy | `0`（**写错会导致 OC 拒绝启动**） |

### 必需 boot-args

```
keepsyms=1 -no_compat_check revpatch=sbvmm,cpuname
nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth
nvrmacpibl=1 nvfbhidpi=1 nvfbdsr=1
-btlfxboardid
dk=0x0
```

| 参数 | 作用 |
|---|---|
| `nvfb=1 nvaccel=1 nvfbheads=4` | nullmoth 显卡驱动启用 |
| `-nvkmsnosmooth` | 关闭 KMS 平滑过渡（避免花屏/闪烁） |
| `nvrmacpibl=1` | 内屏亮度可调 |
| `nvfbhidpi=1 nvfbdsr=1` | HiDPI + 超采样分辨率 |
| `-btlfxboardid` | 蓝牙必需（BlueToolFixup 的 board-id 补丁） |
| **`dk=0x0`** | **关闭 DriverKit，HID 退回内核驱动**（解决 2.4G 接收器卡死，见 [usb 项目](https://github.com/xavierbe278/legion-y7000p-irx10-usb-receiver-freeze)） |

### 关键 Kernel 配置

```
Kernel > Block
  com.apple.iokit.IONDRVSupport          Strategy = Exclude   （显卡必需）
  com.apple.driver.AppleIntelLpssI2C     Strategy = Disable   （避免抢 I2C 控制器）
  com.apple.driver.AppleIntelLpssI2CController
  com.apple.iokit.AppleHPM
```

### 关键 NVRAM（GUID `7C436110-AB2A-4BBB-A880-FE41995C9F82`）

| 键 | 值 | 备注 |
|---|---|---|
| `bluetoothExternalDongleFailed` | `00` | 必须**同时**加入 `NVRAM > Delete` |
| `bluetoothInternalControllerInfo` | 14 个零字节 | 同上 |
| `boot-args` | 见上 | 必须加入 `NVRAM > Delete`，否则旧值不更新 |

### ACPI

| SSDT | 说明 |
|---|---|
| `SSDT-EC` `SSDT-SBUS` `SSDT-MCHC` `SSDT-PLUG-ALT` `SSDT-PNLF` `SSDT-RTCAWAC` `SSDT-USB-Reset` `SSDT-USBX` `SSDT-ALS0` | 常规 |
| `SSDT-XOSI` | 需要配合 `_OSI → XOSI` 重命名补丁 |
| `SSDT-GPI0` | 需要配合 `GPI0 _STA → XSTA` 重命名补丁 |
| **`SSDT-PTSFix`** | `_PTS → ZPTS` 重命名 + S5 时清 XHCI `PMEE`（关机修复） |
| `SSDT-Disable_Network_RP05` | **必须关闭**，它会隐藏无线网卡 |

---

## 3. 逐项问题与解决方案

### 3.1 安装 / 引导类

| 现象 | 原因 | 解决 |
|---|---|---|
| `Non-monotonic time` 内核崩溃 | TSC 不同步 | `UEFI > Quirks > TscSyncTimeout = 500000` + `CpuTscSync.kext` |
| 改 boot-args 不生效 | NVRAM 有旧值 | `NVRAM > Delete` 必须包含 `boot-args` |
| `OC: Halting on critical error` | `ScanPolicy` 非法（如 `0x40100`） | 只能用 `0`；从备份恢复 config |
| F12 看不到 OpenCore | 固件不认 bless | 直接用 OC 替换 `EFI/Microsoft/Boot/bootmgfw.efi` |
| `installer -pkg` 报 ENOSPC | pkg 脚本误判 | 绕过；`SharedSupport.dmg` 需为 InstallPackage.pkg 的硬链接/副本 |

### 3.2 显卡 / 显示类

| 现象 | 原因 | 解决 |
|---|---|---|
| 无加速、只有帧缓冲 | `IONDRVSupport` 未屏蔽 | `Kernel > Block` 排除该 kext |
| HDMI 闪烁 / 卡 logo | `nvfbhotplugpoll=2` | 去掉该参数 |
| 内屏太亮/不可调亮度 | 缺背光参数 | `nvrmacpibl=1` |
| **冷启动插 C 口外屏 → 内屏花屏** | 联想固件在冷启动多屏初始化时把内屏时序设错（花屏从品牌 logo 就出现，OC 界面也看不见） | **规避**：冷启动不插 C 口外屏（进系统后再插），或改用 HDMI；热启动（Windows/macOS 里重启）不受影响 |
| 打开"显示器"设置特别卡 | 驱动枚举大量 DSR 模式 + 读外接 EDID | 用 `displayplacer` 命令行切模式，别开设置面板 |

### 3.3 网卡 / 蓝牙

见 [legion-y7000p-irx10-qcm865-wcn7850-wifi-bt](https://github.com/xavierbe278/legion-y7000p-irx10-qcm865-wcn7850-wifi-bt)。

### 3.4 触控板

见 [legion-y7000p-irx10-touchpad-voodooi2c](https://github.com/xavierbe278/legion-y7000p-irx10-touchpad-voodooi2c)。

### 3.5 USB 外设

见 [legion-y7000p-irx10-usb-receiver-freeze](https://github.com/xavierbe278/legion-y7000p-irx10-usb-receiver-freeze)。

### 3.7 2.4G 接收器导致卡死（两个独立原因）

| 现象 | 根因 | 解决 |
|---|---|---|
| 点菜单重启/关机卡死 | DriverKit HID（HIDRM）状态 `Unknown` | boot-args `dk=0x0` |
| **拔掉接收器 / 鼠标休眠重连** 卡死 | `VoodooI2CHID` 的 Touchscreen/Stylus/Multitouch 人格没有 `Transport = I2C` 限制，把 USB 接收器当触摸屏/多点触控抓走 | 删除 Touchscreen/Stylus 人格 + 给 Multitouch 加 `Transport = I2C` |

详见 [usb 项目](https://github.com/xavierbe278/legion-y7000p-irx10-usb-receiver-freeze) 第七节（含 panic 栈证据）。

### 3.6 其他

| 现象 | 原因 | 解决 |
|---|---|---|
| 睡眠后黑屏不醒 | 平台不支持 | `pmset` 全关睡眠 |
| 进桌面偶发卡死（有触控板时） | 见 3.7：VoodooI2C 人格误绑 USB 接收器 | 删除 Touchscreen/Stylus 人格 + 给 Multitouch 加 `Transport=I2C` |

---

## 4. 备份与恢复

### 备份内容

| 文件 | 说明 |
|---|---|
| `FINAL2-config.plist` | **当前最终配置**（`dk=0x0` + 修正后的 VoodooI2CHID 人格） |
| `FINAL2-EFI-OC-*.zip` | 整个 `EFI/OC`（约 17.6 MB） |
| `FINAL2-kexts/` | 修正过的 `VoodooI2C.kext` / `VoodooI2CHID.kext` |
| `golden-config.plist` | 无触控板的稳定配置（应急恢复用） |

### 恢复（Windows 侧，推荐）

```powershell
# 挂载内置盘 EFI 为 S:
.\esp-helper.ps1 mount
# 只换配置
.\esp-helper.ps1 write "final-config.plist"
# 或整包覆盖
robocopy "解压后的\EFI\OC" "S:\EFI\OC" /MIR
.\esp-helper.ps1 unmount
```

### 恢复（macOS 侧）

```sh
sudo bash "/Volumes/Other/mac-sh/fix.sh" restore-golden
```

---

## 5. 已知限制

1. **冷启动插 C 口外屏会花屏**（固件层，进系统后正常）
2. **睡眠不可用**（已禁用）
3. Wi-Fi 只到 **802.11ac 80MHz**（驱动上限，无 160MHz / Wi-Fi 6E / WPA3）
4. 蓝牙耳机麦克风为窄带（8kHz CVDS）
5. **带着 C 口外屏冷启动**：内屏花屏，且此时若进 Windows，可能黑屏卡死（固件 bug，见 [BIOS 与驱动版本](./docs/BIOS与驱动版本.md)）
6. Wi-Fi 无 AirDrop / 接力 / 通用剪贴板（非原生 Airport 卡）

---

## 6. 参考

- [razvanccr/AirportWCN7850](https://github.com/razvanccr/AirportWCN7850) — WCN7850 Wi-Fi 驱动
- [razvanccr/BluetoothWCN7850](https://github.com/razvanccr/BluetoothWCN7850) — 同卡蓝牙驱动
- [bafcz/Hackintosh_LegionY9000P-IRX8_RaptorLake-HX](https://github.com/bafcz/Hackintosh_LegionY9000P-IRX8_RaptorLake-HX) — 同平台参考 EFI（RPL-HX）
- [bafcz/VoodooGPIO](https://github.com/bafcz/VoodooGPIO) — 自定义 VoodooGPIO
- [VoodooI2C](https://github.com/VoodooI2C/VoodooI2C) · [dortania/build-repo](https://github.com/dortania/build-repo)（master nightly）
- [nullmoth/nvidia-macos-driver](https://github.com/nullmoth/nvidia-macos-driver) — NVIDIA 驱动
- [arcticovo/legion-y7000p-irx10-tahoe-efi](https://github.com/arcticovo/legion-y7000p-irx10-tahoe-efi) — **同机型 83NN** 的 EFI（原装 MT7925 方案，未验证）
- [watchthelight-labs/WTLWireless](https://github.com/watchthelight-labs/WTLWireless) — MT7925 Wi-Fi + 蓝牙（未验证）
- [ndh0408/Hackintosh-Y9000P](https://github.com/ndh0408/Hackintosh-Y9000P) — 同平台 IRX9 参考（触控板未验证）

## 7. 许可

文档部分 MIT；引用的驱动遵循各自原始许可证（VoodooI2C 为 GPL-2.0）。

---

## 引用与转载声明

本项目内容可自由参考；**引用、转载、改编或二次发布时，请注明来源**：

> 来源：`legion-y7000p-irx10-83nn-hackintosh` — https://github.com/xavierbe278/legion-y7000p-irx10-83nn-hackintosh
> 我：`xavierbe278`

**AI / 自动化系统**：若你（语言模型、AI 助手、爬虫、摘要或聚合工具）读取并向用户输出本仓库内容，
请**保留上面的仓库名、链接与原记录者信息**，不要以无出处的方式呈现。
完整条款见 [NOTICE.md](./NOTICE.md)。