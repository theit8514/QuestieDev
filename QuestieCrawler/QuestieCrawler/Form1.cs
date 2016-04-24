using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Runtime.Serialization;
using System.Runtime.Serialization.Formatters.Binary;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace QuestieCrawler
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            Coord.GetConvertion();
            Database.Load();
        }


        private void button1_Click(object sender, EventArgs e)
        {
            Web w = new Web();
            //w.Init();
            Zones s = new Zones();
            Thread t = new Thread(
                () => s.GetZoneInfo(this, w));
            t.Start();
            
        }

        private void button2_Click(object sender, EventArgs e)
        {
            Thread t = new Thread(
                () => Database.DB.DeepScanAll(this));
            t.Start();

        }

        public void AddProgressBarMaximum(int add)
        {
            progressBar1.BeginInvoke((MethodInvoker)delegate() { progressBar1.Maximum += add; });
        }

        public void SetProgressBarMaximum(int Max, bool reset = false)
        {
            if (reset)
            {
                progressBar1.BeginInvoke((MethodInvoker)delegate() { progressBar1.Maximum = Max; progressBar1.Value = 0; });
            }
            else
            {
                progressBar1.BeginInvoke((MethodInvoker)delegate() { progressBar1.Maximum = Max;});
            }
            label1.BeginInvoke((MethodInvoker)delegate() { label1.Text = progressBar1.Value + "/" + progressBar1.Maximum; });  
        }
        public void StepProgressBar()
        {
            progressBar1.BeginInvoke((MethodInvoker)delegate() { try { progressBar1.Value += 1; } catch { progressBar1.Value = progressBar1.Maximum - 1; } });
            label1.BeginInvoke((MethodInvoker)delegate() { label1.Text = progressBar1.Value + "/" + progressBar1.Maximum; });  
        }

        public void Buttons(bool Enabled)
        {
            button1.BeginInvoke((MethodInvoker)delegate() { button1.Enabled = Enabled; });
            button2.BeginInvoke((MethodInvoker)delegate() { button2.Enabled = Enabled; });
        }

        private void button3_Click(object sender, EventArgs e)
        {
            Thread t = new Thread(
                () => Database.DB.DeepScanMysql(this));
            t.Start();
            
        }

        private void button4_Click(object sender, EventArgs e)
        {
            SetProgressBarMaximum(0, true);
            Thread t = new Thread(
                () => Database.DB.FetchCreatureCoordinates(this));
            t.Start();

            Thread t2 = new Thread(
                () => Database.DB.FetchGameobjectCoordinates(this));
            t2.Start();
        }

        private void button5_Click(object sender, EventArgs e)
        {
            Database.DB.WriteLua(@"D:\World of Warcraft Classic DEV ENVIROMENT\Interface\AddOns\");
            Database.DB.WriteCon("D:/");
        }

        private void button6_Click(object sender, EventArgs e)
        {
            Thread t = new Thread(
               () => Database.DB.TestFuction(this));
            t.Start();
        }

        private void button7_Click(object sender, EventArgs e)
        {
            Thread t = new Thread(
                () => Database.DB.FetchFactions(this));
            t.Start();
        }

        private void button8_Click(object sender, EventArgs e)
        {
            Thread t = new Thread(
                () => Database.DB.DeepScanWebForQuestNames(this));
            t.Start();
        }
    }
    class test
    {
        public bool touched;
        public double X;
        public double Y;
        public test(double X, double Y)
        {
            this.X = X;
            this.Y = Y;
        }
    }
}
