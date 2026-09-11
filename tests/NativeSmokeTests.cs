using System;
using System.Reflection;
using System.Runtime.InteropServices;

namespace ExcelShiftScroll
{
    internal static class NativeSmokeTests
    {
        private static void Require(bool condition, string message)
        {
            if (!condition) throw new Exception(message);
        }
        public static int Main()
        {
            try
            {
                Require(IntPtr.Size == 8, "Run as x64.");
                Require(Marshal.SizeOf<Win32.MSG>() == 48, "x64 MSG size.");
                Require(Marshal.OffsetOf<Win32.MSG>("wParam").ToInt32() == 16, "MSG wParam offset.");
                var handler = new HorizontalScrollHandler();
                foreach (uint keys in new uint[] { 0, 8, 12, 5, 6, 20 })
                {
                    var message = new Win32.MSG { message = Win32.WM_MOUSEWHEEL,
                        wParam = new UIntPtr((120u << 16) | keys) };
                    Require(!handler.TryConvert(ref message), "Native chord intercepted.");
                    Require(message.message == Win32.WM_MOUSEWHEEL &&
                        message.wParam.ToUInt64() == ((120u << 16) | keys), "Native chord changed.");
                }
                for (int i = 0; i < 10; i++)
                {
                    var hook = new MouseHook(handler);
                    hook.Start();
                    var field = typeof(MouseHook).GetField("hookHandle", BindingFlags.NonPublic | BindingFlags.Instance);
                    var handle = (IntPtr)field.GetValue(hook);
                    Require(handle != IntPtr.Zero, "Hook installation failed.");
                    hook.Start();
                    Require((IntPtr)field.GetValue(hook) == handle, "Duplicate hook installed.");
                    hook.Dispose();
                    hook.Dispose();
                    Require((IntPtr)field.GetValue(hook) == IntPtr.Zero, "Unhook failed.");
                    bool rejected = false;
                    try { hook.Start(); } catch (ObjectDisposedException) { rejected = true; }
                    Require(rejected, "Disposed hook restarted.");
                }
                Console.WriteLine("PASS: x64 MSG layout; native chord preservation; 10 thread-local hook lifecycle cycles.");
                return 0;
            }
            catch (Exception error) { Console.Error.WriteLine(error); return 1; }
        }
    }
}
