using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;

namespace LibTskReportObfs4
{
    class User32
    {
        [DllImport("user32.dll")]
        public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hwnd, WindowShowStyle nCmdShow);
        public enum WindowShowStyle : uint
        {
            // These text were came from "http://www.pinvoke.net/default.aspx/user32.showwindow"

            // Hides the window and activates another window.
            // See SW_HIDE
            Hide = 0,
            // Activates and displays a window. If the window is minimized 
            // or maximized, the system restores it to its original size and 
            // position. An application should specify this flag when displaying 
            // the window for the first time.
            // See SW_SHOWNORMAL
            ShowNormal = 1,
            // Activates the window and displays it as a minimized window.
            // See SW_SHOWMINIMIZED
            ShowMinimized = 2,
            // Activates the window and displays it as a maximized window.
            // See SW_SHOWMAXIMIZED
            ShowMaximized = 3,
            // Maximizes the specified window.
            // See SW_MAXIMIZE
            Maximize = 3,
            // Displays a window in its most recent size and position. 
            // This value is similar to "ShowNormal", except the window is not 
            // actived.
            // See SW_SHOWNOACTIVATE
            ShowNormalNoActivate = 4,
            // Activates the window and displays it in its current size 
            // and position.
            // See SW_SHOW
            Show = 5,
            // Minimizes the specified window and activates the next 
            // top-level window in the Z order.
            // See SW_MINIMIZE
            Minimize = 6,
            // Displays the window as a minimized window. This value is 
            // similar to "ShowMinimized", except the window is not activated.
            // See SW_SHOWMINNOACTIVE
            ShowMinNoActivate = 7,
            // Displays the window in its current size and position. This 
            // value is similar to "Show", except the window is not activated.
            // See SW_SHOWNA
            ShowNoActivate = 8,
            // Activates and displays the window. If the window is 
            // minimized or maximized, the system restores it to its original size 
            // and position. An application should specify this flag when restoring 
            // a minimized window.
            // See SW_RESTORE
            Restore = 9,
            // Sets the show state based on the SW_ value specified in the 
            // STARTUPINFO structure passed to the CreateProcess function by the 
            // program that started the application.
            // See SW_SHOWDEFAULT
            ShowDefault = 10,
            // Windows 2000/XP: Minimizes a window, even if the thread 
            // that owns the window is hung. This flag should only be used when 
            // minimizing windows from a different thread.
            // See SW_FORCEMINIMIZE
            ForceMinimized = 11
        }

        [DllImport("user32.dll")]
        public static extern bool EnableWindow(IntPtr hwnd, bool enabled);

        
    }
}
