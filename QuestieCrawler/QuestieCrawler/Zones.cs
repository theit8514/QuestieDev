using MySql.Data.MySqlClient;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace QuestieCrawler
{
    class Zones
    {
        public Dictionary<int, List<int>> World = new Dictionary<int, List<int>>(); 
        public void GetZones(Form1 Progress, Web web)
        {
            Dictionary<int, string> Zones = new Dictionary<int, string>();
            for (int z = 0; z < 2; z++)
            {
                web.Navigate("http://db.vanillagaming.org/?zones=" + z);
                Object Read = (Object)web.GetVar("g_listviews['zones']['data']['length']");
                if (Read == null) { return; }

                int ZoneLength = int.Parse(Read.ToString());
                //ReadOnlyCollection<Object> read = (ReadOnlyCollection<Object>)r;
                //int ZoneLength = int.Parse(web.GetVar("g_listviews['zones']['data']['length']").ToString());
                string DataPath = "g_listviews['zones']['data']";

                for (int i = 0; i < ZoneLength; i++)
                {
                    string Name = web.GetVar(DataPath + "['" + i + "']['name']").ToString();
                    int ID = int.Parse(web.GetVar(DataPath + "['" + i + "']['id']").ToString());
                    if (World.ContainsKey(z))
                    {
                        World[z].Add(ID);
                    }
                    else
                    {
                        World.Add(z, new List<int>());
                        World[z].Add(ID);
                    }
                    Zones.Add(ID, Name);
                }

            }
        }
        public void GetZoneInfo(Form1 ProgressController, Web web)
        {
            ProgressController.Buttons(false);
            Dictionary<int, string> Zones = new Dictionary<int, string>();
            for (int z = 0; z < 2; z++)
            {
                web.Navigate("http://db.vanillagaming.org/?zones="+z);
                Object Read = (Object)web.GetVar("g_listviews['zones']['data']['length']");
                if (Read == null) { return; }

                int ZoneLength = int.Parse(Read.ToString());
                //ReadOnlyCollection<Object> read = (ReadOnlyCollection<Object>)r;
                //int ZoneLength = int.Parse(web.GetVar("g_listviews['zones']['data']['length']").ToString());
                string DataPath = "g_listviews['zones']['data']";

                for (int i = 0; i < ZoneLength; i++)
                {
                    string Name = web.GetVar(DataPath + "['" + i + "']['name']").ToString();
                    int ID = int.Parse(web.GetVar(DataPath + "['" + i + "']['id']").ToString());
                    if(World.ContainsKey(z)){
                       World[z].Add(ID);
                    }
                    else
                    {
                        World.Add(z,new List<int>());
                        World[z].Add(ID);
                    }
                    Zones.Add(ID, Name);
                }
               
            }
            ProgressController.SetProgressBarMaximum(Zones.Count);
            //Seems wrong a lot backup with other data.
            //0 == Neutral
            //1 == Alliance
            //2 == Horde
            //3 == both (Seems to be wrong a lot)

            //className var
            //pin pin-2 == horde
            //pin pin-3 == ally
            //pin == neutral

            //innerHTML example "<a style="cursor: pointer;" href="?npc=2437#starts" rel="np"></a>"
            //Cords exists in myMapper.getCoords() but does not return questNPCID so its useless
            //<ZoneID, NPCIDs>
            Dictionary<int, List<int>> NPCs = new Dictionary<int, List<int>>();

            foreach (KeyValuePair<int, string> Zone in Zones)
            {
                web.Navigate("http://db.vanillagaming.org/?zone=" + Zone.Key);
                int Pinlenght = int.Parse(web.GetVar("myMapper['pins']['length']").ToString());
                for (int i = 0; i < Pinlenght; i++)
                {
                    Object X =(Object)web.GetVar("myMapper['pins']['" + i + "']['x']");
                    Object Y =(Object)web.GetVar("myMapper['pins']['" + i + "']['y']");
                    if (X == null || Y == null) { return; }
                    double x = double.Parse(X.ToString());
                    double y = double.Parse(Y.ToString());
                    Object InnerHTML = (Object)web.GetVar("myMapper['pins']['" + i + "']['innerHTML']");
                    if (InnerHTML == null) { return; }
                    string NPCID = Regex.Match(InnerHTML.ToString(), @"npc=(.+?)#starts").Groups[1].Value;
                    if (NPCs.ContainsKey(Zone.Key))
                    {
                        if (!NPCs[Zone.Key].Contains(int.Parse(NPCID)))
                        {
                            NPCs[Zone.Key].Add(int.Parse(NPCID));
                        }
                    }
                    else
                    {
                        NPCs.Add(Zone.Key, new List<int>());
                        NPCs[Zone.Key].Add(int.Parse(NPCID));
                    }
                    if (!Database.DB.Creatures.ContainsKey(int.Parse(NPCID)))
                    {
                        Database.DB.Creatures.Add(int.Parse(NPCID), new Creature(Zone.Key, int.Parse(NPCID),null));
                    }
                    //Do something with this?
                }
                ProgressController.StepProgressBar();
            }
            MySql.Data.MySqlClient.MySqlConnection dbConn = new MySql.Data.MySqlClient.MySqlConnection("Persist Security Info=False;server=localhost;database=mangos;uid=root;password=");
            ProgressController.AddProgressBarMaximum(Database.DB.Creatures.Count);
            foreach(KeyValuePair<int, Creature> c in Database.DB.Creatures)
            {            

                try
                {
                    dbConn.Open();
                }
                catch (Exception erro)
                {

                }
                MySqlCommand cmd = dbConn.CreateCommand();
                cmd.CommandText = "SELECT * FROM `creature_questrelation` where id=" + c.Key + ";";
                MySqlDataReader reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    int Quest = int.Parse(reader["quest"].ToString());
                    if (!Database.DB.Quests.ContainsKey(Quest))
                    {
                        Database.DB.Quests.Add(Quest, new Quest(Quest));
                    }
                    else
                    {

                    }
                }
                reader.Close();
                ProgressController.StepProgressBar();
            }
            Database.Save();
            /*int QuestsLength = int.Parse(web.GetVar("g_listviews['quests']['data']['length]"));
            for (int i = 0; i < Pinlenght; i++)
            {
                Quests.add(new Quest(web));
            }*/
            ProgressController.Buttons(true);
            web.Quit();
        }
    }
}
