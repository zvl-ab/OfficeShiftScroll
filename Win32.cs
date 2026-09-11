using System;
using System.Runtime.InteropServices;

namespace ExcelShiftScroll
{
    internal static class Win32
    {
        internal const int WH_GETMESSAGE = 3;
        internal const uint WM_MOUSEWHEEL = 0x020A;
        internal const uint WM_MOUSEHWHEEL = 0x020E;
        internal const uint GA_PARENT = 1;
        internal const uint GA_ROOT = 2;
        internal const int VK_SHIFT = 0x10;
        internal const int VK_CONTROL = 0x11;
        internal const int VK_MENU = 0x12;
        internal const ushort MK_SHIFT = 0x0004;

        [StructLayout(LayoutKind.Sequential)]
        internal struct POINT { internal int X; internal int Y; }

        [StructLayout(LayoutKind.Sequential)]
        internal struct MSG
        {
            internal IntPtr hwnd;
            internal uint message;
            internal UIntPtr wParam;
            internal IntPtr lParam;
            internal uint time;
            internal POINT pt;
            internal uint lPrivate;
        }

        internal delegate IntPtr LowLevelMouseProc(int code, IntPtr wParam, IntPtr lParam);

        [DllImport("user32.dll", SetLastError = true)]
        internal static extern IntPtr SetWindowsHookEx(int idHook, LowLevelMouseProc callback,
            IntPtr module, uint threadId);
        [DllImport("user32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        internal static extern bool UnhookWindowsHookEx(IntPtr hook);
        [DllImport("user32.dll")]
        internal static extern IntPtr CallNextHookEx(IntPtr hook, int code, IntPtr wParam, IntPtr lParam);
        [DllImport("kernel32.dll")]
        internal static extern uint GetCurrentThreadId();
        [DllImport("user32.dll")]
        internal static extern IntPtr WindowFromPoint(POINT point);
        [DllImport("user32.dll")]
        internal static extern IntPtr GetAncestor(IntPtr window, uint flags);
        [DllImport("user32.dll")]
        internal static extern IntPtr GetForegroundWindow();
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        internal static extern bool IsWindowEnabled(IntPtr window);
        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        internal static extern int GetClassName(IntPtr window, char[] name, int capacity);
        [DllImport("user32.dll")]
        internal static extern short GetKeyState(int key);
        [DllImport("user32.dll")]
        internal static extern uint GetWindowThreadProcessId(IntPtr window, out uint processId);
    }
}
