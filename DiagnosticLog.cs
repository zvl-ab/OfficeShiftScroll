using System;
using System.IO;
using System.Collections.Concurrent;
using System.Diagnostics;
using System.Threading;

namespace ExcelShiftScroll
{
    internal static class DiagnosticLog
    {
        private static readonly ConcurrentQueue<string> Pending = new ConcurrentQueue<string>();
        private static int draining;
        private static readonly int ProcessId = Process.GetCurrentProcess().Id;
        private static readonly string FilePath = Path.Combine(
            Path.GetTempPath(),
            "ExcelShiftScroll.diagnostic.log");

        internal static void Write(string message)
        {
            try
            {
                Pending.Enqueue(DateTime.Now.ToString("O") + " pid=" + ProcessId + " " + message);
                if (Interlocked.CompareExchange(ref draining, 1, 0) == 0)
                    ThreadPool.QueueUserWorkItem(_ => Drain());
            }
            catch
            {
                // Diagnostics must never affect Excel or the hook callback.
            }
        }

        private static void Drain()
        {
            // Never do filesystem I/O on the low-level hook thread. Diagnostics are
            // best effort: process termination may discard pending shutdown lines.
            do
            {
                while (Pending.TryDequeue(out string line))
                {
                    try { File.AppendAllText(FilePath, line + Environment.NewLine); }
                    catch { }
                }
                Interlocked.Exchange(ref draining, 0);
            }
            while (!Pending.IsEmpty && Interlocked.CompareExchange(ref draining, 1, 0) == 0);
        }
    }
}
