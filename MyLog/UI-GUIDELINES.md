# MyLog UI 导航规范

- 一级 Tab 根页面：每个 Tab 只使用 `RootView` 提供的一层 `NavigationStack`。页面设置 `navigationTitle`，沿用系统 Large Title，在滚动时自动折叠为带 material 的 Inline Navigation Bar；操作按钮放入系统 toolbar。
- 一级页面正文必须从系统 Large Title 下方开始，不使用覆盖层、固定偏移或自绘标题。首页、日历、搜索和联系人遵循同一规则。
- “我的”是一级页面的视觉例外：个人封面承担页面标题作用，不显示 Large Title，只保留必要的系统 toolbar 操作。
- 普通功能页：聊天、新建、编辑等使用 `.navigationBarTitleDisplayMode(.inline)`，保持紧凑的系统导航栏。
- 沉浸式详情页：可以隐藏系统 Navigation Bar，让封面或内容延伸到屏幕顶部，并只保留遵守安全区的悬浮返回与必要操作。
- 聊天和沉浸式页面的悬浮控件统一复用 `LiquidGlassModifier` / `LiquidGlassButtonStyle`，不要各自复制 material、描边和阴影参数。
- 禁止通过固定顶部 padding、offset、GeometryReader、透明占位或自制标题模拟系统导航行为。
