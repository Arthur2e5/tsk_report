using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using LibTskReportObfs4;
using System.Threading;

namespace tsk_report_obfs4Patch_
{
    class Program
    {
        static void Main(string[] args)
        {
            Shell.StartProcess_HideWindow.Simple("notepad");
            Thread.Sleep(2000);
            Console.WriteLine("okay");
            Console.ReadLine();

            IntPtr hwndnotepad = User32.FindWindow("Notepad", "无标题 - 记事本");
            Shell.WindowControl.ShowWindowAfterHiding(hwndnotepad);
            Console.ReadLine();
        }
    }
}
