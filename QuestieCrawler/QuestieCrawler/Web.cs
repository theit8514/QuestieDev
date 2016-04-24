using OpenQA.Selenium;
using OpenQA.Selenium.PhantomJS;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace QuestieCrawler
{
    public enum WorkingState
    {
        Working,
        Idle,
        Error,
        Remote,
        Quit
    }
    public class Web
    {

        public string Url()
        {
            return driver.Url;
        }

        public WorkingState State = WorkingState.Working;
        public IWebDriver driver;
        private int Navigates = 0;
        private int TotalAllowed = 30;

        bool hide;

        public void Init()
        {
            State = WorkingState.Working;
            PhantomJSDriverService service = PhantomJSDriverService.CreateDefaultService(@"D:\");
            service.IgnoreSslErrors = true;
            service.LoadImages = false;
            service.ProxyType = "none";
            service.HideCommandPromptWindow = hide;
            driver = new PhantomJSDriver(service);
            driver.Manage().Window.Size = new System.Drawing.Size(1920, 1080);
            State = WorkingState.Idle;
        }

        public Web(bool hide = false)
        {
            this.hide = hide;
            Init();
        }

        public Object GetVar(string Var)
        {
            IJavaScriptExecutor js = driver as IJavaScriptExecutor;
            try
            {
                Object o = (Object)js.ExecuteScript("return " + Var + ";");
                //Object o = (Object)js.ExecuteScript("if(" + Var + "~= nil ) then return "+Var+"; else return -1 end");
                return o;
            }
            catch
            {
                return null;
            }
        }

        public string g_listviews(string Path)
        {
            IJavaScriptExecutor js = driver as IJavaScriptExecutor;
            return (string)js.ExecuteScript("return JSON.stringify(g_listviews"+Path+";");
        }

        public void Navigate(string URL)
        {
            State = WorkingState.Working;
            if (Navigates >= TotalAllowed)
            {
                driver.Quit();
                Init();
                Thread.Sleep(250);
                Navigates = 0;
            }
            //driver.Manage().Window.Position = new System.Drawing.Point(1000000, 1000000);
            driver.Navigate().GoToUrl(URL);
            Navigates += 1;
            State = WorkingState.Idle;

        }

        public void Screenshot(string Path)
        {
            Screenshot ss = ((ITakesScreenshot)driver).GetScreenshot();
            ss.SaveAsFile(Path, System.Drawing.Imaging.ImageFormat.Png);
        }

        public void Quit()
        {
            driver.Quit();
            State = WorkingState.Quit;
        }
    }
}
