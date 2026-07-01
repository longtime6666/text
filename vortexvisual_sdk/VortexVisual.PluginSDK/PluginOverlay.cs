using System;
using System.Collections.Generic;

namespace VortexVisual.Models;

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

public sealed class PluginOverlay
{
    public IReadOnlyList<OverlayRect> Rects { get; init; } = Array.Empty<OverlayRect>();
}
