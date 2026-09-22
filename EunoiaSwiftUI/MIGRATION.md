# 第一阶段迁移记录

## 只读参考项目

- React Native Eunoia：`D:\workspace\eunoia`
- MyLog：`D:\归档\mylog\qingjiaorousibuyao.github.io\MyLog`

这两个目录未作为新工程输出位置。

## MyLog 聊天链迁移映射

- `Models/ChatMessage.swift` → `Eunoia/Models/ChatMessage.swift`
- `Views/ContactChatView.swift` → `Eunoia/Features/Chat/ContactChatView.swift`
- `Views/VoiceMessageBubble.swift` → `Eunoia/Features/Chat/VoiceMessageBubble.swift`
- `Services/ChatAudioManager.swift` → `Eunoia/Features/Chat/ChatAudioManager.swift`
- `Services/ChatAudioStore.swift` → `Eunoia/Features/Chat/ChatAudioStore.swift`
- `Services/ChatMessageTimeFormatter.swift` → `Eunoia/Features/Chat/ChatMessageTimeFormatter.swift`
- `Services/PersistentSettingsStore.swift` 的媒体持久化部分 → `Eunoia/Data/MediaStore.swift`

迁移版保持文字、图片、语音、发送身份切换、背景、长按删除、自动滚底、连续消息合并和 SwiftData 本地消息持久化。联系人字段改为 Eunoia 的单一 `Contact` 模型，聊天直接使用联系人 UUID。

## 暂未迁移

- 首页动态与发布动态
- 空间
- 完整用户资料页
- 信件、放映和相册业务
- 联系人真实动态及相册数据（当前准确显示空状态）
