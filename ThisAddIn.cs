using System;
using System.Diagnostics;

namespace ExcelShiftScroll
{
    public partial class ThisAddIn
    {
        private MouseHook mouseHook;

        private void ThisAddIn_Startup(object sender, EventArgs e)
        {
            try
            {
                if (mouseHook != null) return;
                DiagnosticLog.Write("addin-start path=queue-hwheel-v3 version=" + typeof(ThisAddIn).Assembly.GetName().Version);
                // Observe and transform only this Excel UI thread's consumed messages.
                mouseHook = new MouseHook(new HorizontalScrollHandler());
                mouseHook.Start();
            }
            catch (Exception exception)
            {
                // A hook failure must not prevent Excel from starting. There is no UI/logging
                // surface in the first version; Debug output is available while developing.
                Debug.WriteLine("ExcelShiftScroll could not start the mouse hook: " + exception);
                DiagnosticLog.Write("addin-start-failed " + exception);
                DisposeMouseHook();
            }
        }

        private void ThisAddIn_Shutdown(object sender, EventArgs e)
        {
            DisposeMouseHook();
        }

        private void DisposeMouseHook()
        {
            MouseHook hook = mouseHook;
            mouseHook = null;
            if (hook != null)
            {
                hook.Dispose();
            }
        }

        #region VSTO generated code

        private void InternalStartup()
        {
            Startup += ThisAddIn_Startup;
            Shutdown += ThisAddIn_Shutdown;
        }

        #endregion
    }
}
