# MyLog UI 导航规范

- 一级 Tab 根页面：每个 Tab 只使用 `RootView` 提供的一层 `NavigationStack`。页面设置 `navigationTitle`，沿用系统 Large Title，在滚动时自动折叠为带 material 的 Inline Navigation Bar；操作按钮放入系统 toolbar。
- 普通功能页：聊天、新建、编辑等使用 `.navigationBarTitleDisplayMode(.inline)`，保持紧凑的系统导航栏。
- 沉浸式详情页：可以隐藏系统 Navigation Bar，让封面或内容延伸到屏幕顶部，并只保留遵守安全区的悬浮返回与必要操作。
- 禁止通过固定顶部 padding、offset、GeometryReader、透明占位或自制标题模拟系统导航行为。
