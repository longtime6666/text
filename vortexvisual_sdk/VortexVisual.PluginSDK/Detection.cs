namespace VortexVisual.Models;

/// <summary>
/// 检测结果
/// </summary>
public class Detection
{
    public int ClassId { get; set; }
    public string ClassName { get; set; } = string.Empty;
    public float Confidence { get; set; }
    public float X { get; set; }
    public float Y { get; set; }
    public float Width { get; set; }
    public float Height { get; set; }

    public int Left => (int)(X - Width / 2);
    public int Top => (int)(Y - Height / 2);
    public int Right => (int)(X + Width / 2);
    public int Bottom => (int)(Y + Height / 2);
}
