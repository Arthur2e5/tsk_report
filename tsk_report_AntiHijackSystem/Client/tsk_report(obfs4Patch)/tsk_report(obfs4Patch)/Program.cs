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
            string tsk_arguments = LibTskReportObfs4.Shell.ProcessArguments.PassingArgumentsArrayToTskReport(args);

            Shell.StartProcess_HideWindow.Simple("bin\\ptproxy-4jvg5d.exe", "bin\\tenco.json");
            Console.WriteLine("Loading obfs4 proxy...");
            // wait fully obfs4proxy load
            Thread.Sleep(2000);

            Shell.StartProcess.Standard("tsk_report_core.exe", tsk_arguments, false);
            Console.WriteLine("tsk_report has exit.\nEnd obfs4 proxy now.");
            Shell.StartProcess.Simple("cmd.exe", "/c bin\\cmd\\quitAfter.cmd");

            Environment.Exit(1);
        }
    }
}
