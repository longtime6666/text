namespace VortexVisual.Services;

/// <summary>
/// Optional frame callback for plugins that need raw BGRA frames.
/// </summary>
public interface IFramePlugin
{
    /// <summary>
    /// Called on the capture thread with the latest BGRA frame.
    /// Implementations must return quickly and should not hold the buffer.
    /// </summary>
    void OnFrame(byte[] bgraData, int width, int height, int stride);
}
