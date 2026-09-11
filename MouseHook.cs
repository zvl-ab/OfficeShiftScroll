using System;
using System.ComponentModel;
using System.Runtime.InteropServices;

namespace ExcelShiftScroll
{
    // Thread-local hook: runs before Excel preprocesses a message retrieved from its
    // own queue. No global mouse hook, background thread, timer, or input injection.
    internal sealed class MouseHook : IDisposable
    {
        private readonly HorizontalScrollHandler scrollHandler;
        private readonly Win32.LowLevelMouseProc hookProc;
        private IntPtr hookHandle;
        private bool disposed;
        private int observed;

        internal MouseHook(HorizontalScrollHandler scrollHandler)
        {
            this.scrollHandler = scrollHandler ?? throw new ArgumentNullException(nameof(scrollHandler));
            hookProc = HookCallback;
        }

        internal void Start()
        {
            if (disposed) throw new ObjectDisposedException(nameof(MouseHook));
            if (hookHandle != IntPtr.Zero) return;
            uint thread = Win32.GetCurrentThreadId();
            hookHandle = Win32.SetWindowsHookEx(Win32.WH_GETMESSAGE, hookProc, IntPtr.Zero, thread);
            if (hookHandle == IntPtr.Zero) throw new Win32Exception(Marshal.GetLastWin32Error());
            DiagnosticLog.Write("queue-hook-installed thread=" + thread);
        }

        private IntPtr HookCallback(int code, IntPtr removed, IntPtr pointer)
        {
            try
            {
                // Do not alter PM_NOREMOVE peeks: transform only when Excel consumes it.
                if (code >= 0 && removed == new IntPtr(1) && !disposed)
                {
                    var message = Marshal.PtrToStructure<Win32.MSG>(pointer);
                    if (message.message == Win32.WM_MOUSEWHEEL || message.message == Win32.WM_MOUSEHWHEEL)
                    {
                        if (++observed <= 30)
                            DiagnosticLog.Write("queue-wheel msg=" + message.message.ToString("X") +
                                " keys=" + (message.wParam.ToUInt64() & 0xffff));
                        if (scrollHandler.TryConvert(ref message))
                            Marshal.StructureToPtr(message, pointer, false);
                    }
                }
            }
            catch (Exception error)
            {
                DiagnosticLog.Write("queue-hook-error " + error.GetType().Name);
            }
            return Win32.CallNextHookEx(IntPtr.Zero, code, removed, pointer);
        }

        public void Dispose()
        {
            disposed = true;
            if (hookHandle == IntPtr.Zero) return;
            bool released = Win32.UnhookWindowsHookEx(hookHandle);
            DiagnosticLog.Write("queue-hook-uninstalled success=" + released);
            if (released) hookHandle = IntPtr.Zero;
            GC.KeepAlive(hookProc);
        }
    }
}
