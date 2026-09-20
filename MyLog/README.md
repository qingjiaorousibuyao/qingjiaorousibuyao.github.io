# MyLog

只有自己一个人的私人 Twitter 风格日记，原生 iPhone App。

## 第一版已有

- 时间线式随手记录
- 单条记录最多 4 张照片
- 回复过去的自己，形成 Thread
- 收藏、全文搜索、日历查看
- Face ID / 设备密码锁
- SwiftData 本地保存
- JSON 备份导出

## 在 Mac / 云端 Mac 打开

项目使用 XcodeGen 描述工程，避免在 Windows 上手工维护 `.xcodeproj`：

1. 安装 Xcode 15+ 和 XcodeGen。
2. 在项目根目录运行 `xcodegen generate`。
3. 打开 `MyLog.xcodeproj`，选择自己的开发团队和 iPhone。
4. Build & Run。

最低系统版本为 iOS 17。

## 免费安装到 iPhone

仓库包含 GitHub Actions 自动构建配置。在 GitHub 的 Actions 页面运行
`Build MyLog IPA`，下载生成的 `MyLog-unsigned.ipa`，再由 AltStore 使用
免费 Apple ID 签名并安装。免费签名需要每 7 天刷新。
