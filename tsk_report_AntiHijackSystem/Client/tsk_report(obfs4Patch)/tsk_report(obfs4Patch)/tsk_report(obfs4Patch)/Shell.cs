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
        public class StartProcess
        {
            public static void Simple(string processName, string processArguments)
            {
                ProcessStartInfo pStartInfo = new ProcessStartInfo();
                pStartInfo.FileName = processName;
                pStartInfo.Arguments = processArguments;
                pStartInfo.UseShellExecute = true;

                Process p = Process.Start(pStartInfo);
            }
            public static void Standard(string processName, string processArguments, bool useShell)
            {
                ProcessStartInfo pStartInfo = new ProcessStartInfo();
                pStartInfo.FileName = processName;
                pStartInfo.Arguments = processArguments;
                pStartInfo.UseShellExecute = useShell;

                Process p = Process.Start(pStartInfo);
                p.WaitForExit();
            }
        }
        public class StartProcess_HideWindow
        {
            public static void Simple(string processName, string processArguments)
            {
                // UseShellExecute = true by default
                ProcessStartInfo pStartInfo = new ProcessStartInfo();
                pStartInfo.FileName = processName;
                pStartInfo.Arguments = processArguments;
                pStartInfo.UseShellExecute = true;
                pStartInfo.WindowStyle = ProcessWindowStyle.Hidden;

                Process p = Process.Start(pStartInfo);
            }
        }
        public class WindowControl
        {
            public static void ShowWindowAfterHiding(IntPtr hwnd)
            {
                User32.ShowWindow(hwnd, User32.WindowShowStyle.Show);
            }
        }

        public class ProcessArguments
        {
            public static string PassingArgumentsArrayToTskReport(string[] args)
            {
                string tsk_arguments = "";
                foreach (string argsPassing in args)
                {
                    int i = 0;
                    if (i < args.Length)
                    {
                        tsk_arguments = tsk_arguments + argsPassing + " ";
                    }
                    else
                    {
                        tsk_arguments = tsk_arguments + argsPassing;
                    }
                }

                return tsk_arguments;
            }
        }
    }
}
