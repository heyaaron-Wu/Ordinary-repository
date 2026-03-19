# NVIDIA GeForce RTX 50 Series - 模拟产品展示页

[![HTML5](https://img.shields.io/badge/HTML5-E34F26?style=flat&logo=html5&logoColor=white)](https://developer.mozilla.org/en-US/docs/Web/HTML)
[![CSS3](https://img.shields.io/badge/CSS3-1572B6?style=flat&logo=css3&logoColor=white)](https://developer.mozilla.org/en-US/docs/Web/CSS)
[![Vanilla JS](https://img.shields.io/badge/Vanilla_JS-F7DF1E?style=flat&logo=javascript&logoColor=black)](https://developer.mozilla.org/en-US/docs/Web/JavaScript)

本项目是一个基于纯前端技术（HTML / CSS / Vanilla JavaScript）构建的单页面应用（SPA），旨在高度还原并模拟 NVIDIA 官方 RTX 50 系列显卡的产品发布落地页。

项目通过多次迭代，逐步完善了视觉布局、交互动效、数据严谨性以及跨设备响应式体验。

## 🌟 最终版本核心特性 (Key Features)

- **高级沉浸式视觉 (Immersive UI)**：采用纯黑至深灰的“呼吸式”交替渐变背景，消除板块分割线，页面流转自然。
- **智能导航系统 (Smart Navigation)**：
  - **ScrollSpy**：滚动页面时，导航栏对应版块的文字会自动绿色高亮。
  - **自动隐现**：向下滚动时自动隐藏导航栏以提供沉浸式阅读，向上滚动时立即滑出。
- **全系性能对比交互 (Interactive Performance)**：支持一键平滑切换 RTX 5090 至 RTX 5050 的性能图表，包含严谨的代际颜色图例（50系绿、40系浅灰、30系中灰、20系深灰）及测试环境底注。
- **极简网格与图文排版 (Grid & Overlay Layouts)**：包含 48x48 图标的 AI 特性网格阵列，以及全屏背景图+文字悬浮的 RTX 游戏生态板块。
- **全响应式设计 (Fully Responsive)**：完美适配桌面端、平板及移动端，甚至针对手机横屏（Landscape）单独优化了首屏光影范围。
- **全英文国际化 (Full Localization)**：最终版本采用纯正的 NVIDIA 官方英文术语体系。

---

## 🚀 版本演进与升级日志 (Changelog)

### v1.0 基础框架版 (Initial Structure)
- **搭建骨架**：确立了黑绿配色的 NVIDIA 经典视觉规范。
- **核心板块**：实现首屏大图（Hero）、基础架构介绍、初步的规格对比表。

### v2.0 性能图表引入 (Performance Charts)
- **升级点**：引入 JavaScript 实现 Tab 切换功能。
- **内容**：新增“效能飞跃”板块，初步通过切换“4K游戏、全景光追、内容创作”来展示柱状图。

### v3.0 产品级性能选择器 (Product-based Selector)
- **逻辑重构**：将性能展示逻辑从“按场景切换”改为“按显卡型号切换”。
- **升级点**：加入横向滚动的显卡型号选择栏（RTX 5090 -> RTX 5050），实现动态图片切换与平滑淡入动画。

### v4.0 专业级规格参数表 (Pro Specs Table)
- **布局重构**：完全重写“技术规格”板块，采用横向滚动（支持移动端触控）的宽幅表格。
- **数据完善**：录入所有 7 款显卡的详细参数（AI TOPS、核心代数、NVENC/NVDEC 数量、显存带宽等），并增加首列冻结（Sticky）和绿色下划线装饰。

### v5.0 Blackwell 架构视觉升级 (Architecture UI Polish)
- **排版重构**：架构板块从卡片式改为“左图右文”的双栏 Flex 布局。
- **视觉融合**：去除架构芯片图片的外部边框和发光效果，使其完美融入黑色背景。增加“游戏玩家和创作者的终极平台”副标题。

### v6.0 AI 驱动特性网格 (AI Features Grid)
- **新增板块**：新增“AI 驱动的飞跃”板块。
- **精细化 UI**：采用网格布局，将 6 个功能特性配以严格缩放为 48x48 像素的定制图标，顶部添加标志性绿线，配合鼠标悬停浮动效果。

### v7.0 沉浸式呼吸背景与导航栏进化 (Breathing Backgrounds & Nav)
- **高级色彩流**：为全站所有板块引入 `黑 -> 灰` 接 `灰 -> 黑` 的交替线性渐变，彻底消除生硬的板块分割感。
- **横屏优化**：加入 `@media (orientation: landscape)`，横屏时收缩首屏绿色光晕范围。

### v8.0 智能交互增强 (Smart Interaction UX)
- **滑动监听 (ScrollSpy)**：加入原生 JS 滚动监听，阅读到特定区域时，导航栏对应链接自动变绿（首页顶部保持纯净无高亮）。
- **智能隐现**：加入判断滚动方向的 JS 逻辑，实现导航栏“下滚隐藏、上滚显示”，提升可视面积。
- **平滑滚动**：为全局添加 `scroll-behavior: smooth`。
**品牌化**：导航栏移除 Emoji 替换为官方 `nvidia-logo.png` 图片，并将底色改为纯黑无边框。
  
### v9.0 宏大 RTX 生态视界 (RTX Ecosystem Overlay)
- **新增板块**：插入 "RTX. It's On." 生态板块。
- **图层堆叠技术**：使用绝对定位将游戏合集大图作为全屏背景铺满，应用 `brightness(0.5)` 压暗处理，将标题、文案和可点击链接高亮悬浮于图片之上。后优化为“上文下大图”的清晰排版。

### v10.0 数据严谨性补全 (Data Rigor & Legends)
- **代际颜色图例**：在性能图表上方增加多维度的图例（Legend），通过提取色值区分不同代际（50系=NVIDIA绿，40系=浅灰，30系=中灰，20系=深灰）。
- **专业测试底注**：在每张图表下方加入居中的淡灰色测试环境说明（涵盖分辨率、DLSS状态、多帧生成模式及对比对象）。

### v11.0 国际化最终版 (English Localization Final)
- **语言转化**：将全站所有的简体中文文案、按钮、表格表头翻译为原汁原味的官方英文表述（如：*Supreme Power*, *Performance Multiplied*, *Tech Specs Overview* 等）。

---

## 📁 资源文件需求 (Assets Required)

运行此 V11.HTML 文件需要在同一目录下准备以下图片资源：
- `nvidia-logo.png` (导航栏 Logo)
- `geforce-rtx-50-series-architecture-ari.png` (架构芯片图)
- `image_0.png` 到 `image_5.png` (AI 特性 48x48 图标)
- `geforce-rtx-5090-perf-chart-outline.png` 等 7 张显卡性能对比图表
- `geforce-rtx-50-series-games-bm-xl980-d@2x.jpg` (RTX 游戏生态海报)
（其他版本的.html因为资源文件名字问题大概率出错）

## 🛠️ 如何运行 (How to Run)

本项目无任何第三方库依赖（无 React/Vue/Bootstrap），纯AI与人工配合。
直接双击打开 `v11.html` 即可在现代浏览器中完美预览最终版本。
