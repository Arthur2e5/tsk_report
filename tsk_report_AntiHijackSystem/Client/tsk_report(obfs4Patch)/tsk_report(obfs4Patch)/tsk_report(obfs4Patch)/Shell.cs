using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LibTskReportObfs4
{
    class Shell
    {
        public class StartProcess_HideWindow
        {
            public static void Simple(string processName)
            {
                ProcessStartInfo processStartInfo = new ProcessStartInfo();
                processStartInfo.FileName = processName;
                processStartInfo.UseShellExecute = true;
                processStartInfo.WindowStyle = ProcessWindowStyle.Hidden;

                Process p = Process.Start(processStartInfo);
            }
        }
        public class WindowControl
        {
            public static void ShowWindowAfterHiding(IntPtr hwnd)
            {
                User32.ShowWindow(hwnd, User32.WindowShowStyle.Show);
            }
        }
    }
}
