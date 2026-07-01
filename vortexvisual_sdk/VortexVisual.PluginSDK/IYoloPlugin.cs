using System.Windows;
using VortexVisual.Models;

namespace VortexVisual.Services;

/// <summary>
/// YOLO插件接口 - 所有DLL插件必须实现此接口
/// </summary>
public interface IYoloPlugin : IDisposable
{
    string Name { get; }
    string Description { get; }
    string Version { get; }
    string Author { get; }
    bool IsEnabled { get; set; }
    
    FrameworkElement? GetSettingsView();
    void Initialize(IPluginHost host);
    void Start();
    void Stop();
    void OnDetections(IReadOnlyList<Detection> detections, int frameWidth, int frameHeight);
    void OnModelLoaded(string modelName, int classCount, IReadOnlyList<string> classNames) { }
}

/// <summary>
/// 插件宿主接口
/// </summary>
public interface IPluginHost
{
    IReadOnlyList<Detection> CurrentDetections { get; }
    int FrameWidth { get; }
    int FrameHeight { get; }
    bool IsInferencing { get; }
    string ModelName { get; }
    int ClassCount { get; }
    IReadOnlyList<string> AllClassNames { get; }
    string GetClassName(int classId);
    void InvokeOnUI(Action action);
    void ShowStatus(string message);
    void SetOverlay(string key, PluginOverlay overlay);
    void ClearOverlay(string key);
}
