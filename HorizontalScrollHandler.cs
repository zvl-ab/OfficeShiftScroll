using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace ExcelShiftScroll
{
    internal sealed class HorizontalScrollHandler
    {
        private readonly uint excelProcessId = unchecked((uint)Process.GetCurrentProcess().Id);
        private int converted;

        internal bool TryConvert(ref Win32.MSG message)
        {
            if (message.message != Win32.WM_MOUSEWHEEL) return false;
            uint value = unchecked((uint)message.wParam.ToUInt64());
            // The queued message is the source of truth for Shift/Ctrl/button state.
            // Consume Shift only for this mouse message; never change keyboard state.
            if ((value & 0xffff) != Win32.MK_SHIFT ||
                Down(Win32.VK_CONTROL) || Down(Win32.VK_MENU) || Down(0x5B) || Down(0x5C))
                return false;

            short delta = unchecked((short)(value >> 16));
            // Negating the minimum short cannot be represented in a wheel message.
            if (delta == 0 || delta == short.MinValue) return false;
            IntPtr root = Win32.GetAncestor(message.hwnd, Win32.GA_ROOT);
            if (root == IntPtr.Zero || root != Win32.GetForegroundWindow() ||
                !Win32.IsWindowEnabled(root) || !HasClass(root, "XLMAIN")) return false;
            Win32.GetWindowThreadProcessId(message.hwnd, out uint processId);
            if (processId != excelProcessId) return false;

            // Native WM_MOUSEWHEEL lParam contains signed screen coordinates.
            long position = message.lParam.ToInt64();
            var point = new Win32.POINT
            {
                X = unchecked((short)position),
                Y = unchecked((short)(position >> 16))
            };
            IntPtr worksheet = WorksheetAncestor(Win32.WindowFromPoint(point), root);
            // Require both the hit-test area and the message recipient to be the same
            // worksheet. Ribbon, dialogs and edit controls outside EXCEL7 pass through.
            if (worksheet == IntPtr.Zero || WorksheetAncestor(message.hwnd, root) != worksheet)
                return false;

            message.message = Win32.WM_MOUSEHWHEEL;
            message.wParam = new UIntPtr((uint)(ushort)(short)-delta << 16);
            if (++converted <= 20)
                DiagnosticLog.Write("queue-convert hwnd=" + message.hwnd + " delta=" + (-delta) +
                    " keys-before=4 keys-after=0");
            return true;
        }

        private static IntPtr WorksheetAncestor(IntPtr window, IntPtr root)
        {
            if (window == IntPtr.Zero || Win32.GetAncestor(window, Win32.GA_ROOT) != root)
                return IntPtr.Zero;
            for (int depth = 0; window != IntPtr.Zero && depth < 32; depth++)
            {
                if (HasClass(window, "EXCEL7")) return window;
                if (window == root) break;
                window = Win32.GetAncestor(window, Win32.GA_PARENT);
            }
            return IntPtr.Zero;
        }

        private static bool HasClass(IntPtr window, string expected)
        {
            char[] name = new char[256];
            int length = Win32.GetClassName(window, name, name.Length);
            return length > 0 && string.Equals(new string(name, 0, length), expected,
                StringComparison.OrdinalIgnoreCase);
        }

        private static bool Down(int key) => (Win32.GetKeyState(key) & 0x8000) != 0;
    }
}
