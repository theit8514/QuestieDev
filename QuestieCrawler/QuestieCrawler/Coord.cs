using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace QuestieCrawler
{
    [Serializable]
    public class Coord
    {
        public int C, Z, WoWheadZoneID;
        public double X, Y;
        public Coord(int WoWheadZoneID, double X, double Y, int C = -1, int Z = -1) { this.C = C; this.Z = Z; this.X = X; this.Y = Y; this.WoWheadZoneID = WoWheadZoneID; }

        public Coord GetCoord()
        {
            if(C == -1 || Z == -1)
            {
                Convert();
            }
            return this;
        }

        public void Convert()
        {
            if (Convertion.Count == 0) { GetConvertion(); }
            if (Convertion.ContainsKey(WoWheadZoneID))
            {
                C = Convertion[WoWheadZoneID][0];
                Z = Convertion[WoWheadZoneID][1];
            }
        }
        public static Dictionary<int, string> NameConvertion = new Dictionary<int, string>();
        public static Dictionary<int, int[]> Convertion = new Dictionary<int, int[]>();
        public static void GetConvertion()
        {
            Web web = new Web(true);
            web.Navigate("http://db.vanillagaming.org/?zones=" + 0);
            Object Read = (Object)web.GetVar("g_listviews['zones']['data']['length']");
            if (Read == null) { return; }

            int ZoneLength = int.Parse(Read.ToString());
            int indx = 1;
            for (int i = 0; i < ZoneLength; i++)
            {
                dynamic id = web.GetVar("g_listviews['zones']['data'][" + i + "]['id']");
                dynamic name = web.GetVar("g_listviews['zones']['data'][" + i + "]['name']");
                if (name == "Deeprun Tram") {  continue; }
                Convertion.Add(int.Parse(id), new int[] { 2, indx});
                NameConvertion.Add(int.Parse(id), name);
                indx++;
            }

            web.Navigate("http://db.vanillagaming.org/?zones=" + 1);
            Read = (Object)web.GetVar("g_listviews['zones']['data']['length']");
            if (Read == null) { return; }

            ZoneLength = int.Parse(Read.ToString());

            indx = 1;
            for (int i = 0; i < ZoneLength; i++)
            {
                dynamic id = web.GetVar("g_listviews['zones']['data'][" + i + "]['id']");
                dynamic name = web.GetVar("g_listviews['zones']['data'][" + i + "]['name']");
                Convertion.Add(int.Parse(id), new int[] { 1, indx });
                NameConvertion.Add(int.Parse(id), name);
                indx++;
            }

            web.Quit();
            /*if (WoWHeadZoneID == 331) { return new int[] { 1, 1 }; }//Ashenvale
            if (WoWHeadZoneID == 16) { return new int[] { 1, 2}; }//Azshara
            if (WoWHeadZoneID == 148) { return new int[] { 1, 3 }; }//Darkshore
            if (WoWHeadZoneID == 1657) { return new int[] { 1, 4 }; }//Darnassus
            if (WoWHeadZoneID == 405) { return new int[] { 1, 5 }; }//Desolace
            if (WoWHeadZoneID == 14) { return new int[] { 1, 6 }; }
            if (WoWHeadZoneID == 15) { return new int[] { 1, 7 }; }
            if (WoWHeadZoneID == 361) { return new int[] { 1, 8 }; }
            if (WoWHeadZoneID == 357) { return new int[] { 1, 9 }; }
            if (WoWHeadZoneID == 493) { return new int[] { 1, 10 }; }
            if (WoWHeadZoneID == 215) { return new int[] { 1, 11 }; }
            if (WoWHeadZoneID == 1637) { return new int[] { 1, 12 }; }
            if (WoWHeadZoneID == 357) { return new int[] { 1, 13 }; }
            if (WoWHeadZoneID == 357) { return new int[] { 1, 14 }; }
            if (WoWHeadZoneID == 357) { return new int[] { 1, 15 }; }*/
        }
    }
}
