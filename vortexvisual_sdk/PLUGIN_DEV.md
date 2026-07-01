# VortexVisual 插件开发文档

本文档面向第三方开发者，介绍如何为 VortexVisual 开发插件。

---

## 目录

1. [概述](#1-概述)
2. [快速开始](#2-快速开始)
3. [核心接口](#3-核心接口)
4. [数据模型](#4-数据模型)
5. [插件生命周期](#5-插件生命周期)
6. [设置界面](#6-设置界面)
7. [最佳实践](#7-最佳实践)
8. [常见问题](#8-常见问题)

---

## 1. 概述

### 1.1 插件系统特性

- **动态加载**: 插件可在运行时加载，无需重启主程序
- **动态卸载**: 支持热卸载，便于开发调试
- **隔离加载**: 每个插件在独立的 AssemblyLoadContext 中运行
- **类型共享**: 插件可直接使用主程序的公共类型
- **原始帧回调**: 可选实现 IFramePlugin 接收 BGRA 帧

### 1.2 插件目录结构


```
VortexVisual/
└── plugins/                    # 插件根目录
    └── YourPlugin/            # 你的插件文件夹（必须是子目录）
        ├── YourPlugin.dll     # 插件主 DLL
        └── (依赖DLL...)       # 其他依赖
```

**重要**: 插件 DLL 必须放在 `plugins` 目录的子文件夹中，不能直接放在 `plugins` 根目录。

---

## 2. 快速开始

### 2.1 创建项目

1. 创建 .NET 9 类库项目：

```bash
dotnet new classlib -n MyPlugin -f net9.0-windows
```

2. 编辑 `MyPlugin.csproj`：

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net9.0-windows</TargetFramework>
    <UseWPF>true</UseWPF>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <OutputType>Library</OutputType>
    <!-- 确保依赖DLL被复制到输出目录 -->
    <CopyLocalLockFileAssemblies>true</CopyLocalLockFileAssemblies>
  </PropertyGroup>

  <ItemGroup>
    <!-- 引用插件 SDK（包含接口定义） -->
    <ProjectReference Include="..\VortexVisual.PluginSDK\VortexVisual.PluginSDK.csproj">
      <Private>false</Private>
    </ProjectReference>
  </ItemGroup>
</Project>
```

> **注意**: `Private=false` 表示不将 SDK DLL 复制到输出目录，因为主程序已包含这些类型。

### 2.2 实现插件

```csharp
using System.Windows;
using VortexVisual.Models;
using VortexVisual.Services;

namespace MyPlugin;

public class MyPlugin : IYoloPlugin, IFramePlugin
{
    private IPluginHost? _host;
    private bool _isEnabled;

    // ========== 元信息（必须实现） ==========
    public string Name => "我的插件";
    public string Description => "插件功能描述";
    public string Version => "1.0.0";
    public string Author => "作者名";
    public bool IsEnabled { get => _isEnabled; set => _isEnabled = value; }

    // ========== 生命周期方法 ==========
    
    public void Initialize(IPluginHost host)
    {
        _host = host;
        // 初始化逻辑，只调用一次
    }

    public void Start()
    {
        // 用户启用插件时调用
    }

    public void Stop()
    {
        // 用户禁用插件时调用
    }

    public void Dispose()
    {
        // 插件卸载时调用，释放资源
    }

    // ========== 核心回调 ==========
    
    public void OnDetections(IReadOnlyList<Detection> detections, int frameWidth, int frameHeight)
    {
        if (!_isEnabled) return;
        
        // 每帧调用，处理检测结果
        foreach (var det in detections)
        {
            // det.ClassId    - 类别ID
            // det.ClassName  - 类别名称
            // det.Confidence - 置信度 (0-1)
            // det.X, det.Y   - 边界框中心坐标
            // det.Width, det.Height - 边界框尺寸
        }
    }

    public void OnFrame(byte[] bgraData, int width, int height, int stride)
    {
        if (!_isEnabled) return;
        
        // 原始 BGRA 帧回调（采集线程），不要阻塞或长期持有缓冲区
        // 如需处理，请自行复制或丢进队列再异步处理
    }

    public void OnModelLoaded(string modelName, int classCount, IReadOnlyList<string> classNames)
    {
        // 模型加载/切换时调用（可选实现）
    }

    // ========== 设置界面 ==========
    
    public FrameworkElement? GetSettingsView()
    {
        // 返回 WPF 控件作为设置界面，返回 null 表示无设置界面
        return null;
    }
}
```

> 如果不需要原始画面回调，可不实现 `IFramePlugin`，也无需提供 `OnFrame`。

### 2.3 编译与部署

```bash
# 编译
dotnet build -c Release

# 部署：将输出复制到插件目录
# bin/Release/net9.0-windows/ -> VortexVisual/plugins/MyPlugin/
```

### 2.4 测试

1. 启动 VortexVisual
2. 进入"插件"页面
3. 点击"刷新插件"按钮
4. 启用你的插件

---

## 3. 核心接口

### 3.1 IYoloPlugin 接口

所有插件必须实现此接口：

```csharp
public interface IYoloPlugin : IDisposable
{
    // ===== 元信息属性 =====
    
    /// <summary>插件名称（显示在UI中）</summary>
    string Name { get; }
    
    /// <summary>插件描述</summary>
    string Description { get; }
    
    /// <summary>插件版本（如 "1.0.0"）</summary>
    string Version { get; }
    
    /// <summary>插件作者</summary>
    string Author { get; }
    
    /// <summary>插件启用状态（由主程序设置）</summary>
    bool IsEnabled { get; set; }

    // ===== 生命周期方法 =====
    
    /// <summary>
    /// 初始化插件（加载时调用一次）
    /// </summary>
    /// <param name="host">插件宿主，用于与主程序交互</param>
    void Initialize(IPluginHost host);
    
    /// <summary>启动插件（用户启用时调用）</summary>
    void Start();
    
    /// <summary>停止插件（用户禁用时调用）</summary>
    void Stop();

    // ===== 核心回调 =====
    
    /// <summary>
    /// 接收检测结果（每帧调用，在推理线程中）
    /// </summary>
    /// <param name="detections">检测结果列表</param>
    /// <param name="frameWidth">帧宽度（像素）</param>
    /// <param name="frameHeight">帧高度（像素）</param>
    void OnDetections(IReadOnlyList<Detection> detections, int frameWidth, int frameHeight);
    
    /// <summary>
    /// 模型加载完成时调用（可选，有默认空实现）
    /// </summary>
    void OnModelLoaded(string modelName, int classCount, IReadOnlyList<string> classNames) { }

    // ===== 设置界面 =====
    
    /// <summary>
    /// 获取设置界面（返回 null 表示无设置界面）
    /// </summary>
    FrameworkElement? GetSettingsView();
}
```

### 3.2 IPluginHost 接口

通过此接口与主程序交互：

```csharp
public interface IPluginHost
{
    // ===== 检测状态 =====
    
    /// <summary>当前帧的检测结果</summary>
    IReadOnlyList<Detection> CurrentDetections { get; }
    
    /// <summary>当前帧宽度</summary>
    int FrameWidth { get; }
    
    /// <summary>当前帧高度</summary>
    int FrameHeight { get; }
    
    /// <summary>是否正在推理</summary>
    bool IsInferencing { get; }

    // ===== 模型信息 =====
    
    /// <summary>当前模型名称</summary>
    string ModelName { get; }
    
    /// <summary>模型类别总数</summary>
    int ClassCount { get; }
    
    /// <summary>所有类别名称列表</summary>
    IReadOnlyList<string> AllClassNames { get; }
    
    /// <summary>根据ID获取类别名称</summary>
    string GetClassName(int classId);

    // ===== 工具方法 =====
    
    /// <summary>在UI线程执行操作（用于更新UI）</summary>
    void InvokeOnUI(Action action);
    
    /// <summary>在主窗口状态栏显示消息</summary>
    void ShowStatus(string message);
    void SetOverlay(string key, PluginOverlay overlay);
    void ClearOverlay(string key);
}
```

---

### 3.3 IFramePlugin 接口（可选）

实现此接口可接收原始 BGRA 帧。回调在**采集线程**中触发，仅在插件启用时回调，必须快速返回，且不要长期持有传入的缓冲区。

```csharp
public interface IFramePlugin
{
    /// <summary>
    /// 原始 BGRA 帧回调（高频，采集线程）
    /// </summary>
    /// <param name="bgraData">BGRA 像素数据</param>
    /// <param name="width">帧宽度</param>
    /// <param name="height">帧高度</param>
    /// <param name="stride">每行字节数</param>
    void OnFrame(byte[] bgraData, int width, int height, int stride);
}
```

建议：如需耗时处理，请在 `OnFrame` 中复制必要数据后入队，避免阻塞采集线程。

---

## 4. 数据模型

### 4.1 Detection 类

检测结果数据结构：

```csharp
public class Detection
{
    /// <summary>类别ID（从0开始）</summary>
    public int ClassId { get; set; }
    
    /// <summary>类别名称</summary>
    public string ClassName { get; set; }
    
    /// <summary>置信度（0.0 - 1.0）</summary>
    public float Confidence { get; set; }
    
    /// <summary>边界框中心 X 坐标</summary>
    public float X { get; set; }
    
    /// <summary>边界框中心 Y 坐标</summary>
    public float Y { get; set; }
    
    /// <summary>边界框宽度</summary>
    public float Width { get; set; }
    
    /// <summary>边界框高度</summary>
    public float Height { get; set; }

    // 计算属性（边界框四边坐标）
    public int Left => (int)(X - Width / 2);
    public int Top => (int)(Y - Height / 2);
    public int Right => (int)(X + Width / 2);
    public int Bottom => (int)(Y + Height / 2);
}
```

### 4.2 坐标系说明

```
(0,0) ─────────────────────────► X
  │
  │    ┌─────────────┐
  │    │  Detection  │
  │    │    (X,Y)    │  ← 中心点
  │    │      ●      │
  │    │             │
  │    └─────────────┘
  │         Width
  ▼
  Y
```

- 原点 (0,0) 在画面左上角
- X 轴向右为正
- Y 轴向下为正
- Detection 的 (X, Y) 是边界框的中心点坐标

---

### 4.3 PluginOverlay Overlay

Use `IPluginHost.SetOverlay` to draw simple rectangles on the main preview. Coordinates are in frame space. If `Centered` is true, `X/Y` are the center; otherwise they are the top-left.

```csharp
public sealed class PluginOverlay
{
    public IReadOnlyList<OverlayRect> Rects { get; init; } = Array.Empty<OverlayRect>();
}

public sealed class OverlayRect
{
    public float X { get; set; }
    public float Y { get; set; }
    public float Width { get; set; }
    public float Height { get; set; }
    public bool Centered { get; set; } = true;
    public int Thickness { get; set; } = 2;
    public byte R { get; set; } = 255;
    public byte G { get; set; } = 255;
    public byte B { get; set; } = 255;
    public byte A { get; set; } = 255;
}
```

Recommendation: use a stable `key` (for example, the plugin name) and call `ClearOverlay` when the plugin stops or unloads.

## 5. 插件生命周期


```
┌────────────────────────────────────────────────────────────┐
│                      插件生命周期                           │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  【加载阶段】                                               │
│                                                            │
│    主程序启动 / 点击"刷新插件"                              │
│           │                                                │
│           ▼                                                │
│    ┌──────────────┐                                        │
│    │ 扫描 plugins │                                        │
│    │ 子目录的 DLL │                                        │
│    └──────┬───────┘                                        │
│           │                                                │
│           ▼                                                │
│    ┌──────────────┐                                        │
│    │ 查找实现     │                                        │
│    │ IYoloPlugin  │                                        │
│    │ 的类型       │                                        │
│    └──────┬───────┘                                        │
│           │                                                │
│           ▼                                                │
│    ┌──────────────┐                                        │
│    │ 创建实例     │                                        │
│    │ 调用         │                                        │
│    │ Initialize() │  ← 传入 IPluginHost                    │
│    └──────────────┘                                        │
│                                                            │
│  【运行阶段】                                               │
│                                                            │
│    用户启用插件                                             │
│           │                                                │
│           ▼                                                │
│    ┌──────────────┐                                        │
│    │ IsEnabled=   │                                        │
│    │ true         │                                        │
│    │ 调用 Start() │                                        │
│    └──────┬───────┘                                        │
│           │                                                │
│           ▼                                                │
│    ┌─────────────────────────────────┐                     │
│    │ 每帧调用 OnDetections()         │  ← 推理线程         │
│    │ (仅当 IsEnabled=true 时)        │                     │
│    └─────────────────────────────────┘                     │
│           │                                                │
│           ▼                                                │
│    用户禁用插件                                             │
│           │                                                │
│           ▼                                                │
│    ┌──────────────┐                                        │
│    │ 调用 Stop()  │                                        │
│    │ IsEnabled=   │                                        │
│    │ false        │                                        │
│    └──────────────┘                                        │
│                                                            │
│  【卸载阶段】                                               │
│                                                            │
│    点击"刷新插件" / 主程序退出                              │
│           │                                                │
│           ▼                                                │
│    ┌──────────────┐                                        │
│    │ 调用 Stop()  │  ← 如果正在运行                        │
│    │ 调用         │                                        │
│    │ Dispose()    │                                        │
│    └──────────────┘                                        │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

补充：实现 `IFramePlugin` 时，采集线程每帧会回调 `OnFrame`，与推理开关无关。

### 5.1 方法调用时机

| 方法 | 调用时机 | 调用线程 | 说明 |
|------|----------|----------|------|
| `Initialize` | 插件加载时 | UI 线程 | 只调用一次，初始化资源 |
| `Start` | 用户启用插件时 | UI 线程 | 可多次调用 |
| `Stop` | 用户禁用插件时 | UI 线程 | 可多次调用 |
| `OnDetections` | 每帧推理完成后 | **推理线程** | 高频调用，注意性能 |
| `OnFrame` | 每帧采集完成后 | **采集线程** | 仅实现 IFramePlugin 时回调，需快速返回 |
| `OnModelLoaded` | 模型加载/切换时 | UI 线程 | 可选实现 |
| `GetSettingsView` | 显示设置界面时 | UI 线程 | 可缓存返回值 |
| `Dispose` | 插件卸载时 | UI 线程 | 释放所有资源 |

### 5.2 线程安全

**重要**: `OnDetections` 在推理线程中调用，不是 UI 线程！

**同样重要**: `OnFrame` 在采集线程中调用，必须快速返回，避免阻塞采集。

```csharp
public void OnDetections(IReadOnlyList<Detection> detections, int w, int h)
{
    // ❌ 错误：直接更新 UI
    myLabel.Content = $"检测到 {detections.Count} 个目标";
    
    // ✅ 正确：通过 InvokeOnUI 更新 UI
    _host?.InvokeOnUI(() =>
    {
        myLabel.Content = $"检测到 {detections.Count} 个目标";
    });
}
```

---

## 6. 设置界面

### 6.1 简单设置界面

```csharp
public FrameworkElement? GetSettingsView()
{
    var panel = new StackPanel { Margin = new Thickness(10) };
    
    // 标题
    panel.Children.Add(new TextBlock
    {
        Text = "插件设置",
        FontSize = 16,
        FontWeight = FontWeights.Bold,
        Margin = new Thickness(0, 0, 0, 10)
    });
    
    // 开关
    var checkBox = new CheckBox { Content = "启用某功能" };
    checkBox.Checked += (s, e) => _featureEnabled = true;
    checkBox.Unchecked += (s, e) => _featureEnabled = false;
    panel.Children.Add(checkBox);
    
    // 滑块
    panel.Children.Add(new TextBlock { Text = "灵敏度", Margin = new Thickness(0, 10, 0, 5) });
    var slider = new Slider { Minimum = 0, Maximum = 100, Value = 50 };
    slider.ValueChanged += (s, e) => _sensitivity = (int)e.NewValue;
    panel.Children.Add(slider);
    
    return panel;
}
```

### 6.2 使用数据绑定 (MVVM)

```csharp
public class MyPlugin : IYoloPlugin, INotifyPropertyChanged
{
    private bool _featureEnabled;
    public bool FeatureEnabled
    {
        get => _featureEnabled;
        set { _featureEnabled = value; OnPropertyChanged(); }
    }
    
    public event PropertyChangedEventHandler? PropertyChanged;
    protected void OnPropertyChanged([CallerMemberName] string? name = null)
        => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
    
    public FrameworkElement? GetSettingsView()
    {
        var checkBox = new CheckBox { Content = "启用功能" };
        checkBox.SetBinding(CheckBox.IsCheckedProperty, new Binding(nameof(FeatureEnabled))
        {
            Source = this,
            Mode = BindingMode.TwoWay
        });
        return checkBox;
    }
}
```

### 6.3 缓存设置界面

```csharp
private FrameworkElement? _settingsView;

public FrameworkElement? GetSettingsView()
{
    // 缓存界面实例，避免重复创建
    return _settingsView ??= CreateSettingsView();
}

private FrameworkElement CreateSettingsView()
{
    // 创建界面...
}
```

---

## 7. 最佳实践

### 7.1 性能优化

```csharp
public void OnDetections(IReadOnlyList<Detection> detections, int w, int h)
{
    // ✅ 快速返回
    if (!_isEnabled || detections.Count == 0) return;
    
    // ✅ 避免在高频回调中创建对象
    // ❌ var list = new List<Detection>();
    // ✅ 使用预分配的缓冲区
    
    // ✅ 避免耗时操作
    // ❌ Thread.Sleep(100);
    // ❌ File.WriteAllText(...);
    
    // ✅ 异步处理非关键任务
    Task.Run(() => ProcessAsync(detections));
}
```

补充：`OnFrame` 在采集线程回调，原则与 `OnDetections` 相同。必要时使用小队列（如 2 帧）+ 处理线程，队列满时丢旧帧，避免阻塞采集。

### 7.2 资源管理

```csharp
public void Dispose()
{
    // 1. 停止后台任务
    _cancellationTokenSource?.Cancel();
    _backgroundThread?.Join(1000);
    
    // 2. 取消事件订阅
    if (_someObject != null)
        _someObject.SomeEvent -= OnSomeEvent;
    
    // 3. 释放非托管资源
    _device?.Dispose();
    _device = null;
    
    // 4. 清理引用
    _host = null;
    _settingsView = null;
}
```

### 7.3 配置持久化

```csharp
public class MyPlugin : IYoloPlugin
{
    private static readonly string ConfigPath = Path.Combine(
        Path.GetDirectoryName(typeof(MyPlugin).Assembly.Location) ?? "",
        "config.json"
    );
    
    public void Initialize(IPluginHost host)
    {
        _host = host;
        LoadConfig();
    }
    
    private void LoadConfig()
    {
        if (File.Exists(ConfigPath))
        {
            var json = File.ReadAllText(ConfigPath);
            // 反序列化配置...
        }
    }
    
    public void SaveConfig()
    {
        var json = JsonSerializer.Serialize(_config);
        File.WriteAllText(ConfigPath, json);
    }
}
```

### 7.4 调试技巧

```csharp
// 输出调试信息（在 Visual Studio 输出窗口显示）
System.Diagnostics.Debug.WriteLine($"[MyPlugin] 检测到 {detections.Count} 个目标");

// 在主程序状态栏显示消息
_host?.ShowStatus("处理完成");

// 附加调试器：Visual Studio → 调试 → 附加到进程 → VortexVisual.exe
```

---

## 8. 常见问题

### Q1: 插件加载失败

**检查项**：
1. DLL 是否在 `plugins` 的子目录中（不能直接放在 plugins 根目录）
2. 目标框架是否为 `net9.0-windows`
3. 是否正确实现了 `IYoloPlugin` 接口
4. 是否缺少依赖 DLL

**解决方案**：
```xml
<!-- 确保依赖被复制 -->
<CopyLocalLockFileAssemblies>true</CopyLocalLockFileAssemblies>
```

### Q2: 类型转换异常

**原因**: 插件中的类型与主程序不匹配

**解决方案**: 
- 必须引用 `VortexVisual.PluginSDK` 项目
- 设置 `<Private>false</Private>` 避免复制 SDK DLL 到输出目录

### Q3: UI 更新无效

**原因**: 在非 UI 线程更新 UI

**解决方案**:
```csharp
_host?.InvokeOnUI(() =>
{
    // 在这里更新 UI
});
```

### Q4: 插件卸载后内存未释放

**原因**: 存在未释放的资源或事件订阅

**解决方案**: 在 `Dispose` 中彻底清理：
- 取消所有事件订阅
- 停止所有后台线程
- 释放所有资源
- 将引用设为 null

### Q5: OnDetections / OnFrame 性能问题

**原因**: 在高频回调中执行耗时操作

**解决方案**:
- 快速返回，避免阻塞
- 耗时操作异步执行
- 避免频繁创建对象
- 使用对象池或预分配缓冲区
- 对 OnFrame 使用小队列 + 处理线程，队列满时丢旧帧

---

## 附录：完整示例

```csharp
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Windows;
using System.Windows.Controls;
using VortexVisual.Models;
using VortexVisual.Services;

namespace ExamplePlugin;

/// <summary>
/// 示例插件 - 统计检测目标数量
/// </summary>
public class CounterPlugin : IYoloPlugin, INotifyPropertyChanged
{
    private IPluginHost? _host;
    private bool _isEnabled;
    private FrameworkElement? _settingsView;
    private int _totalCount;
    private int _frameCount;

    // 元信息
    public string Name => "目标计数器";
    public string Description => "统计检测到的目标数量";
    public string Version => "1.0.0";
    public string Author => "示例作者";
    public bool IsEnabled { get => _isEnabled; set => _isEnabled = value; }

    // 可绑定属性
    public int TotalCount
    {
        get => _totalCount;
        set { _totalCount = value; OnPropertyChanged(); }
    }

    public void Initialize(IPluginHost host)
    {
        _host = host;
        _host.ShowStatus($"{Name} 已加载");
    }

    public void Start()
    {
        _totalCount = 0;
        _frameCount = 0;
        _host?.ShowStatus($"{Name} 已启动");
    }

    public void Stop()
    {
        _host?.ShowStatus($"{Name} 已停止，共处理 {_frameCount} 帧，{_totalCount} 个目标");
    }

    public void OnDetections(IReadOnlyList<Detection> detections, int w, int h)
    {
        if (!_isEnabled) return;

        _frameCount++;
        _totalCount += detections.Count;

        // 每100帧更新一次UI
        if (_frameCount % 100 == 0)
        {
            _host?.InvokeOnUI(() => OnPropertyChanged(nameof(TotalCount)));
        }
    }

    public void OnModelLoaded(string modelName, int classCount, IReadOnlyList<string> classNames)
    {
        _host?.ShowStatus($"模型已加载: {modelName} ({classCount} 类别)");
    }

    public FrameworkElement? GetSettingsView()
    {
        if (_settingsView != null) return _settingsView;

        var panel = new StackPanel { Margin = new Thickness(10) };
        
        var label = new TextBlock { FontSize = 14 };
        label.SetBinding(TextBlock.TextProperty, new System.Windows.Data.Binding(nameof(TotalCount))
        {
            Source = this,
            StringFormat = "累计检测: {0} 个目标"
        });
        panel.Children.Add(label);

        var resetBtn = new Button { Content = "重置计数", Margin = new Thickness(0, 10, 0, 0) };
        resetBtn.Click += (s, e) => { TotalCount = 0; _frameCount = 0; };
        panel.Children.Add(resetBtn);

        _settingsView = panel;
        return _settingsView;
    }

    public void Dispose()
    {
        _host = null;
        _settingsView = null;
    }

    public event PropertyChangedEventHandler? PropertyChanged;
    protected void OnPropertyChanged([CallerMemberName] string? name = null)
        => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
}
```

---

*文档版本: 1.0 | 适用于 VortexVisual 插件系统*
