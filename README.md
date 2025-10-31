## 音乐播放器 (Music Player)
一个基于 Flutter 开发的跨平台音乐播放器，主要音源来自 Bilibili。支持 Android 和 Windows 平台，后续将支持 iOS 和 macOS。

### 🎯 项目简介
这是一个功能简陋的音乐播放器应用，主要特色包括：

* 跨平台支持：第一版支持 Android + Windows，第二版支持 iOS, macOS
* B站音源：从 Bilibili 解析音频内容
* 智能缓存：支持离线播放和缓存管理
* 后台播放：移动端支持后台和锁屏播放
* 桌面集成：桌面端支持窗口隐藏和系统集成

### 📁 项目目录结构
    lib/
        ├── core/                   # 核心基础设施
        │   ├── constants/          # 应用常量定义
        │   ├── themes/             # 主题和样式配置
        │   ├── utils/              # 工具类和辅助函数
        │   └── exceptions/         # 自定义异常处理
        ├── data/                   # 数据层
        │   ├── models/             # 数据模型定义
        │   ├── services/           # 业务服务层
        │   │   └── audio_player_service.dart  # 音频播放核心服务
        │   └── test_data.dart      # 测试数据提供
        ├── domain/                 # 业务逻辑层
        │   └── models/             # 业务模型定义
        │       └── audio_info.dart # 音频信息模型
        └── presentation/           # 表现层 (UI)
            ├── providers/          # 状态管理 (Riverpod)
            │   └── audio_provider.dart # 音频相关状态管理
            ├── screens/            # 页面组件
            │   └── player_screen.dart  # 主播放界面
            └── widgets/            # 可复用UI组件
                ├── audio_controls.dart # 音频控制组件
                ├── progress_bar.dart   # 进度条组件
                └── playlist_widget.dart # 播放列表组件

### 📋 文件作用说明
#### 核心文件
* main.dart - 应用入口点，ProviderScope 包装
* data/services/audio_player_service.dart - 音频播放核心服务
    * 管理播放器状态、播放列表、播放控制
    * 基于 just_audio 和 ChangeNotifier

* domain/models/audio_info.dart - 音频信息数据模型
    * 定义音频的标题、URL、封面、时长等属性

#### 状态管理
* presentation/providers/audio_provider.dart - Riverpod 状态管理
    * 提供播放状态、播放列表、当前音频等状态
    * 使用 ChangeNotifierProvider 管理音频服务

#### UI 组件
* presentation/screens/player_screen.dart - 主播放界面
    * 集成所有播放器组件
    * 显示当前播放信息和播放列表

* presentation/widgets/audio_controls.dart - 播放控制按钮
    * 播放/暂停、上一首/下一首控制
* presentation/widgets/progress_bar.dart - 播放进度条
    * 显示和控制播放进度

* presentation/widgets/playlist_widget.dart - 播放列表显示
    * 显示播放队列，支持跳转到指定曲目

#### 测试数据
* data/test_data.dart - 测试音频数据
    * 提供用于开发和测试的示例音频

### 🚀 当前功能状态
#### ✅ 已完成功能
1. 核心播放流程
    * 音频播放控制（播放/暂停/停止）
    * 播放列表管理
    * 进度控制和显示
    * 上一首/下一首切换
    * 指定曲目跳转

2. UI 界面
    * 主播放界面布局
    * 播放控制面板
    * 播放列表显示
    * 当前播放信息展示

3. 状态管理
    * Riverpod 状态管理
    * 响应式 UI 更新
    * 播放状态同步

4. 跨平台基础
    * Android 平台支持
    * Windows 平台支持
    * 基础音频播放

5. B站音源解析
    * 链接解析服务
    * 音频信息提取逻辑
    * 批量导入功能（换行符分割）
    * TXT 文件导入支持
    * 音频信息元数据提取
    * 离线播放支持
    * 音频处理（FFmpeg）
    * 缓存清理功能
    * 实现本地数据存储（Hive）
    * 播放列表持久化

#### 🔄 进行中功能


### 📅 后续开发计划
#### 第一阶段：核心功能完善 (完成)


#### 第二阶段：平台特性集成 (预计 3-4 周)
##### 第5周：Android 平台优化
* 后台播放服务集成
* 锁屏播放控制
* 通知栏播放控制
* 音频焦点管理

##### 第6周：Windows 平台优化
* 系统托盘集成
* 全局快捷键支持
* 窗口隐藏/显示功能
* 桌面集成优化

##### 第7周：字幕功能
* 字幕文件解析（SRT, LRC）
* 字幕同步显示
* 字幕下载和管理
* 歌词显示界面

#### 第三阶段：高级功能 (预计 4-5 周)
##### 第8-9周：iOS + macOS 支持
* iOS 平台适配和测试
* macOS 平台适配
* 各平台 UI/UX 优化
* 平台特定功能实现

##### 第10周：音频库管理
* 音频信息编辑功能
* 分组和分类管理
* 搜索和筛选功能
* 收藏夹功能

##### 第11-12周：体验优化
* 性能优化和内存管理
* 错误处理和用户反馈
* 主题和个性化设置
* 无障碍功能支持

### 🛠 技术栈
* 框架: Flutter 3.0+
* 状态管理: Riverpod
* 音频播放: just_audio + audio_service
* 本地存储: Hive
* 网络请求: dio
* 桌面支持: Flutter 官方桌面支持

### 📦 安装和运行
#### 环境要求
* Flutter SDK 3.0.0 或更高版本
* Android SDK (Android 开发)
* Visual Studio (Windows 开发)
* FFmpeg (音频处理)

#### 安装FFmpeg
* Windows:
```
choco install ffmpeg
```
* MacOS:
```
brew install ffmpeg
```

#### 运行步骤
````
# 克隆项目
git clone <repository-url>

# 进入项目目录
cd music_player

# 安装依赖
flutter pub get

# 运行应用
flutter run
````

#### 平台特定运行
```
# 运行在 Android
flutter run -d android

# 运行在 Windows
flutter run -d windows
```

----
### 📝 License
This project is licensed under the [MIT License].

----
LastUpdate: 2025-10-28
