using LuaInterface;
using MySql.Data.MySqlClient;
using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.Serialization;
using System.Runtime.Serialization.Formatters.Binary;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace QuestieCrawler
{
    [Serializable]
    public static class Database
    {
        public static List<Web> WebClients = new List<Web>();
        static bool Loading = false;
        static string FileName = "MyFile3.bin";
        public static SubDatabase DB = new SubDatabase();
        public static void Save()
        {
            while (Loading) { }
            IFormatter f = new BinaryFormatter();
            Stream s = new FileStream(FileName,
                                     FileMode.Create,
                                     FileAccess.Write, FileShare.None);
            f.Serialize(s, Database.DB);
            s.Close();
        }


        public static void Load()
        {
            Loading = true;
            if (File.Exists(FileName))
            {
                IFormatter formatter = new BinaryFormatter();
                Stream stream = new FileStream(FileName,
                                         FileMode.Open,
                                         FileAccess.ReadWrite, FileShare.None);
                Database.DB = (SubDatabase)formatter.Deserialize(stream);
                stream.Close();
            }
            for (int i = 0; i < 1; i++)
            {
               // Thread t = new Thread(
                //() => Database.CreateClient());
                //t.Start();
            }
            Loading = false;
        }

        public static void CreateClient()
        {
          Database.WebClients.Add(new Web());
        }
    }
    enum Races : int
    {
        Human = 0,
        Orc = 1,
        Dwarf = 2,
        NightElf = 3,
        Undead = 4,
        Tauren = 5,
        Gnome = 6,
        Troll = 7,
    }

    [Serializable]
    public class SubDatabase
    {
        public Dictionary<int, Creature> Creatures = new Dictionary<int, Creature>();
        public Dictionary<int, Gameobject> Gameobjects = new Dictionary<int, Gameobject>();
        public Dictionary<int, Item> Items = new Dictionary<int, Item>();
        public Dictionary<int, Quest> Quests = new Dictionary<int, Quest>();
        public Dictionary<int, Use> Uses = new Dictionary<int, Use>();


        public void DeepScanMysql(Form1 Progress, bool forceUpdate = false)
        {
            Progress.Buttons(false);
            Progress.SetProgressBarMaximum(Creatures.Count + Gameobjects.Count + Items.Count + Quests.Count, true);

            MySql.Data.MySqlClient.MySqlConnection dbConn = new MySql.Data.MySqlClient.MySqlConnection("Persist Security Info=False;server=localhost;database=mangos;uid=root;password=");

            MySql.Data.MySqlClient.MySqlConnection dbConn2 = new MySql.Data.MySqlClient.MySqlConnection("Persist Security Info=False;server=localhost;database=mangos;uid=root;password=");

            try
            {
                dbConn.Open();
                dbConn2.Open();
            }
            catch (Exception erro)
            {

            }
            Progress.BeginInvoke((MethodInvoker)delegate() { Progress.Text = "Fetching Quests"; });  
            foreach (KeyValuePair<int, Quest> c in Quests)
            {
                Gameobjects.Remove(2691);
                MySqlCommand cmd = dbConn.CreateCommand();
                cmd.CommandText = "SELECT * FROM `quest_template` where entry="+c.Key+";";
                MySqlDataReader reader = cmd.ExecuteReader();

                while (reader.Read())
                {

                    int id = int.Parse(reader["entry"].ToString());
                    int minLevel = int.Parse(reader["minlevel"].ToString());
                    int questLevel = int.Parse(reader["questlevel"].ToString());
                    string title = reader["title"].ToString();
                    string details = reader["details"].ToString();
                    //details = reader["requestitemstext"].ToString();
                    int requiredRaces = int.Parse(reader["requiredraces"].ToString());
                    int requiredClasses = int.Parse(reader["requiredclasses"].ToString());
                    int requiredSkill = int.Parse(reader["requiredskill"].ToString());
                    int PrevQuestId = int.Parse(reader["prevquestid"].ToString());
                    int Zor = int.Parse(reader["zoneorsort"].ToString());
                    int nq = int.Parse(reader["NextQuestInChain"].ToString());

                    c.Value.details = details;
                    c.Value.QuestID = id;
                    c.Value.reqLevel = minLevel;
                    c.Value.level = questLevel;
                    c.Value.name = title;
                    c.Value.reqRaces = requiredRaces;
                    if (c.Value.RequiresQuest == null || c.Value.RequiresQuest == 0 && PrevQuestId > 0)
                    {
                        c.Value.RequiresQuest = PrevQuestId;
                    }
                    c.Value.reqClasses = requiredClasses;
                    c.Value.reqSkill = requiredSkill;
                    c.Value.ZoneOrSort = Zor;
                    c.Value.NextQuestInChain = nq;

                    MySqlCommand cmd2 = dbConn2.CreateCommand();
                    cmd2.CommandText = "SELECT * FROM `quest_template` where entry=" + nq + ";";
                    MySqlDataReader reader2 = cmd2.ExecuteReader();
                    while (reader2.Read())
                    {
                        int Nid = int.Parse(reader2["entry"].ToString());
                        int NPrevQuestId = int.Parse(reader2["prevquestid"].ToString());
                        int Nnq = int.Parse(reader2["NextQuestInChain"].ToString());
                        if(c.Value.RequiresQuest == NPrevQuestId && NPrevQuestId != 0)
                        {
                            Quests[Nnq].RequiresQuest = Nid;
                        }
                    }
                    reader2.Close();

                    int ProvidedItem = int.Parse(reader["srcitemid"].ToString());

                    //Items Check
                    for (int i = 1; i <= 4; i++)
                    {
                        int ReqItemID = int.Parse(reader["reqitemid" + i].ToString());
                        int ReqCount = int.Parse(reader["reqitemcount" + i].ToString());
                        //We dont care if we've gotten the item provided by the questgiver.
                        if (ReqItemID != 0 && ReqCount > 0 && ReqItemID != ProvidedItem)
                        {
                            if (!Items.ContainsKey(ReqItemID) && ReqItemID != 0)
                            {
                                Items.Add(ReqItemID, new Item(ReqItemID, null));
                                Progress.AddProgressBarMaximum(1);
                            }
                            c.Value.AddQuestObjective(new Objective(Items[ReqItemID], ReqCount));
                        }
                    }
                    


                    //Creature Check
                    for (int i = 1; i <= 4; i++)
                    {
                        //If ReqSpellCast is != 0, the objective is to cast on target, else kill.
                        //NOTE: If ReqSpellCast is != 0 and the spell has effects Send Event or Quest Complete, this field may be left empty.
                        int ReqSpellCast = int.Parse(reader["ReqSpellCast"+i].ToString());
                        //> 0 = Creature
                        //< 0 = Gameobject
                        int ReqCreatureID = int.Parse(reader["reqcreatureorgoid" + i].ToString());
                        int ReqCount = int.Parse(reader["reqcreatureorgocount" + i].ToString());
                        if (ReqCreatureID > 0 && ReqCount > 0)
                        {
                            if (!Creatures.ContainsKey(ReqCreatureID) && ReqCreatureID != 0)
                            {
                                Creatures.Add(ReqCreatureID, new Creature(-1, ReqCreatureID, null));
                                Progress.AddProgressBarMaximum(1);
                            }
                            c.Value.AddQuestObjective(new Objective(Creatures[ReqCreatureID], ReqCount));
                        }
                        else if (ReqCreatureID < 0 && ReqCount > 0)
                        {
                            ReqCreatureID = Math.Abs(ReqCreatureID);
                            if (!Gameobjects.ContainsKey(ReqCreatureID))
                            {
                                Gameobjects.Add(ReqCreatureID, new Gameobject(ReqCreatureID, null));
                                Progress.AddProgressBarMaximum(1);
                            }
                            c.Value.AddQuestObjective(new Objective(Gameobjects[ReqCreatureID], ReqCount));
                        }
                    }

                    /*if (x > 0)
                    {
                        List<Races> ReqRaces = new List<Races>();

                        BitArray b = new BitArray(new int[] { x });
                        for (int i = 0; i < 8; i++)
                        {
                            if (b.Get(i))
                            {
                                ReqRaces.Add((Races)i);
                            }
                        }
                    }
                    else
                    {

                    }*/
                        
                    //qs.Add(new Quest(0,0,id,questLevel,title,minLevel,requiredRaces,0));
                    //Quest q = new Quest(0, 0, id, level, name, reqlvl, side, xp);
                }
                reader.Close();


                //Starters GameObjects
                cmd = dbConn.CreateCommand();
                cmd.CommandText = "SELECT * FROM `gameobject_questrelation` where quest=" + c.Key + ";";
                reader = cmd.ExecuteReader(); //id quest
                while(reader.Read())
                {
                    int ID = int.Parse(reader["id"].ToString());
                    if(!Gameobjects.ContainsKey(ID))
                    {
                        Gameobjects.Add(ID, new Gameobject(ID, null));
                        Progress.AddProgressBarMaximum(1);
                    }
                    if(c.Value.Starter == null)
                    {
                        c.Value.Starter = new List<Objective>();
                    }
                    c.Value.Starter.Add(new Objective(Gameobjects[ID]));
                }
                reader.Close();

                //Starters Creatures
                cmd = dbConn.CreateCommand();
                cmd.CommandText = "SELECT * FROM `creature_questrelation` where quest=" + c.Key + ";";
                reader = cmd.ExecuteReader(); //id quest
                while (reader.Read())
                {
                    int ID = int.Parse(reader["id"].ToString());
                    if (!Creatures.ContainsKey(ID))
                    {
                        Creatures.Add(ID, new Creature(-1, ID, null));
                        Progress.AddProgressBarMaximum(1);
                    }
                    if (c.Value.Starter == null)
                    {
                        c.Value.Starter = new List<Objective>();
                    }
                    c.Value.Starter.Add(new Objective(Creatures[ID]));
                }
                reader.Close();

                //Finishers GameObjects
                cmd = dbConn.CreateCommand();
                cmd.CommandText = "SELECT * FROM `gameobject_involvedrelation` where quest=" + c.Key + ";";
                reader = cmd.ExecuteReader(); //id quest
                while (reader.Read())
                {
                    int ID = int.Parse(reader["id"].ToString());
                    if (!Gameobjects.ContainsKey(ID))
                    {
                        Gameobjects.Add(ID, new Gameobject(ID, null));
                        Progress.AddProgressBarMaximum(1);
                    }
                    if (c.Value.Finisher == null)
                    {
                        c.Value.Finisher = new List<Objective>();
                    }
                    c.Value.Finisher.Add(new Objective(Gameobjects[ID]));
                }
                reader.Close();

                //Finishers Creatures
                cmd = dbConn.CreateCommand();
                cmd.CommandText = "SELECT * FROM `creature_involvedrelation` where quest=" + c.Key + ";";
                reader = cmd.ExecuteReader(); //id quest
                while (reader.Read())
                {
                    int ID = int.Parse(reader["id"].ToString());
                    if (!Creatures.ContainsKey(ID))
                    {
                        Creatures.Add(ID, new Creature(-1, ID, null));
                        Progress.AddProgressBarMaximum(1);
                    }
                    if (c.Value.Finisher == null)
                    {
                        c.Value.Finisher = new List<Objective>();
                    }
                    c.Value.Finisher.Add(new Objective(Creatures[ID]));
                }
                reader.Close();

                if(c.Value.GetQuestObjectives().Count == 0)
                {

                }
                c.Value.RemoveDuplicates();

                Progress.StepProgressBar();
            }

            foreach(KeyValuePair<int, Quest> q in Quests)
            {
                foreach(Objective obj in q.Value.GetQuestObjectives())
                {
                    if(obj.GetObjectiveType() == typeof(IItem))
                    {
                        if (!Items.ContainsKey(obj.GetSource().GetID()))
                        {
                            Items.Add(obj.GetSource().GetID(), new Item(obj.GetSource().GetID(), ""));
                        }
                    }
                    else if(obj.GetObjectiveType() == typeof(IObject))
                    {
                        if (!Gameobjects.ContainsKey(obj.GetSource().GetID()))
                        {
                            Gameobjects.Add(obj.GetSource().GetID(), new Gameobject(obj.GetSource().GetID(), ""));
                        }
                    }
                    else if (obj.GetObjectiveType() == typeof(INPC))
                    {
                        if(!Creatures.ContainsKey(obj.GetSource().GetID()))
                        {
                            Creatures.Add(obj.GetSource().GetID(), new Creature(-1, obj.GetSource().GetID(), ""));
                        }
                    }
                }
            }

             /*MySqlCommand cmd1 = dbConn.CreateCommand();
             cmd1.CommandText = "SELECT * FROM `gameobject_template`;";
             MySqlDataReader reader1 = cmd1.ExecuteReader();

             while (reader1.Read())
             {
                 string name = reader1["name"].ToString();
                 int id = int.Parse(reader1["entry"].ToString());
                 if(!Gameobjects.ContainsKey(id))
                 {
                     Gameobjects.Add(id, new Gameobject(id, name));
                 }
             }
             reader1.Close();*/

            Progress.BeginInvoke((MethodInvoker)delegate() { Progress.Text = "Fetching Creature drops"; });
            MySqlCommand cmdt = dbConn.CreateCommand();
            cmdt.CommandText = "SELECT * FROM `creature_loot_template`;";
            MySqlDataReader readerr = cmdt.ExecuteReader();
            while (readerr.Read())
            {
                int ITEMid = int.Parse(readerr["item"].ToString());
                int NPCid = int.Parse(readerr["entry"].ToString());
                if (!Creatures.ContainsKey(NPCid) && Items.ContainsKey(ITEMid))
                {
                    Creatures.Add(NPCid, new Creature(-1, NPCid, ""));
                    Progress.AddProgressBarMaximum(1);
                    Creatures[NPCid].D_Drops.Add(ITEMid);
                }
            }
            readerr.Close();





            cmdt = dbConn.CreateCommand();
            cmdt.CommandText = "SELECT * FROM `gameobject_template`;";
            readerr = cmdt.ExecuteReader();
            while (readerr.Read())
            {
                string name = readerr["name"].ToString();
                int ID = int.Parse(readerr["entry"].ToString());
                if (!Gameobjects.ContainsKey(ID))
                {
                    Gameobjects.Add(ID, new Gameobject(ID, name));
                }
            }
            readerr.Close();

            Progress.BeginInvoke((MethodInvoker)delegate() { Progress.Text = "Fetching Gameobject drops : " + Gameobjects.Count; });  
            Progress.AddProgressBarMaximum(Gameobjects.Count);
            Web web = new Web(true);
            foreach (KeyValuePair<int, Gameobject> i in Gameobjects)
            {
                i.Value.FetchDropInformation(web);
                Progress.StepProgressBar();
            }
            web.Quit();



           /* Progress.AddProgressBarMaximum(Items.Count);
            foreach (KeyValuePair<int, Item> i in Items)
            {
                MySqlCommand cmd = dbConn.CreateCommand();
                cmd.CommandText = "SELECT * FROM `gameobject_loot_template` where item=" + i.Key + ";";
                MySqlDataReader reader = cmd.ExecuteReader();

                while (reader.Read())
                {
                    int GOid = int.Parse(reader["entry"].ToString());
                    if(!Gameobjects.ContainsKey(GOid))
                    {
                        Gameobjects.Add(GOid, new Gameobject(GOid, ""));
                        Progress.AddProgressBarMaximum(1);
                        Gameobjects[GOid].D_Drops.Add(i.Key);
                    }
                }
                reader.Close();

                Progress.StepProgressBar();
            }*/




            //Code above shuold be 1000x faster
            /*foreach (KeyValuePair<int, Item> i in Items)
            {
                MySqlCommand cmd = dbConn.CreateCommand();
                cmd.CommandText = "SELECT * FROM `creature_loot_template` where item=" + i.Key + ";";
                MySqlDataReader reader = cmd.ExecuteReader();

                while (reader.Read())
                {
                    int NPCid = int.Parse(reader["entry"].ToString());
                    if (!Creatures.ContainsKey(NPCid))
                    {
                        Creatures.Add(NPCid, new Creature(-1,NPCid, ""));
                        Creatures[NPCid].D_Drops.Add(i.Key);
                    }
                }
                reader.Close();

                Progress.SetProgressBarMaximum(Creatures.Count + Gameobjects.Count + Items.Count + Quests.Count);
                Progress.StepProgressBar();
            }*/

            //Test Resets sources
            /*foreach(KeyValuePair<int, Item> i in Items)
            {
                i.Value.Sources = new List<ISource>();
            }*/


            Progress.BeginInvoke((MethodInvoker)delegate() { Progress.Text = "Fetching Gameobject names"; });  
            cmdt = dbConn.CreateCommand();
            cmdt.CommandText = "SELECT * FROM `gameobject_template`;";
            readerr = cmdt.ExecuteReader();
            while (readerr.Read())
            {
                string name = readerr["name"].ToString();
                int ID = int.Parse(readerr["entry"].ToString());
                if (Gameobjects.ContainsKey(ID))
                {
                    Gameobjects[ID].Name = name;
                }
            }
            readerr.Close();

            /*Progress.AddProgressBarMaximum(Gameobjects.Count);
            foreach (KeyValuePair<int, Gameobject> i in Gameobjects)
            {
                MySqlCommand cmd = dbConn.CreateCommand();
                cmd.CommandText = "SELECT * FROM `gameobject_loot_template` where entry=" + i.Key + ";";
                MySqlDataReader reader = cmd.ExecuteReader(); //id quest
                while (reader.Read())
                {
                  int ItemID = int.Parse(reader["item"].ToString());
                  if (!Items.ContainsKey(ItemID))
                  {
                      Items.Add(ItemID, new Item(ItemID, null));
                      Progress.AddProgressBarMaximum(1);
                  }
                  Items[ItemID].AddSource(i.Value);
                  i.Value.D_Drops.Add(ItemID);
                }
                reader.Close();

                i.Value.RemoveDuplicates();

                Progress.StepProgressBar();
            }*/



            Progress.BeginInvoke((MethodInvoker)delegate() { Progress.Text = "Fetching Creature names"; });  
            cmdt = dbConn.CreateCommand();
            cmdt.CommandText = "SELECT * FROM `creature_template`;";
            readerr = cmdt.ExecuteReader();
            while (readerr.Read())
            {
                string name = readerr["name"].ToString();
                int ID = int.Parse(readerr["entry"].ToString());
                if (Creatures.ContainsKey(ID))
                {
                    Creatures[ID].Name = name;
                }
            }
            readerr.Close();




            Progress.BeginInvoke((MethodInvoker)delegate() { Progress.Text = "Fetching Creature drops"; });  
            Progress.AddProgressBarMaximum(Creatures.Count);
            foreach (KeyValuePair<int, Creature> i in Creatures)
            {
                MySqlCommand cmd = dbConn.CreateCommand();
                cmd.CommandText = "SELECT * FROM `creature_loot_template` where entry=" + i.Key + ";";
                MySqlDataReader reader = cmd.ExecuteReader(); //id quest
                while (reader.Read())
                {
                    int ItemID = int.Parse(reader["item"].ToString());
                    if (!Items.ContainsKey(ItemID))
                    {
                        Items.Add(ItemID, new Item(ItemID, null));
                        Progress.AddProgressBarMaximum(1);
                    }
                    i.Value.D_Drops.Add(ItemID);
                    Items[ItemID].AddSource(i.Value);
                }
                reader.Close();

                i.Value.RemoveDuplicates();

                Progress.StepProgressBar();
            }



            Progress.BeginInvoke((MethodInvoker)delegate() { Progress.Text = "Fetching Item names"; });  
            cmdt = dbConn.CreateCommand();
            cmdt.CommandText = "SELECT * FROM `item_template`;";
            readerr = cmdt.ExecuteReader();
            while (readerr.Read())
            {
                string name = readerr["name"].ToString();
                int ID = int.Parse(readerr["entry"].ToString());
                if (Items.ContainsKey(ID))
                {
                    Items[ID].Name = name;
                }
            }
            readerr.Close();

            Progress.AddProgressBarMaximum(Items.Count);
            foreach (KeyValuePair<int, Item> i in Items)
            {
                //Run through all items
                /*MySqlCommand cmd = dbConn.CreateCommand();
                cmd.CommandText = "SELECT * FROM `item_template` where entry=" + i.Key + ";";
                MySqlDataReader reader = cmd.ExecuteReader();

                while (reader.Read())
                {
                    i.Value.Name = reader["name"].ToString();
                }
                reader.Close();*/

                /*foreach (KeyValuePair<int, Creature> z in Creatures)
                {
                    foreach(int s in z.Value.D_Drops)
                    {
                        if(s == z.Key)
                        {
                            i.Value.AddSource(z.Value);
                        }
                    }
                }

                foreach (KeyValuePair<int, Gameobject> z in Gameobjects)
                {
                    foreach (int s in z.Value.D_Drops)
                    {
                        if (s == z.Key)
                        {
                            i.Value.AddSource(z.Value);
                        }
                    }
                }*/

                i.Value.RemoveDuplicates();

                Progress.StepProgressBar();
            }
          

            string hej = "svej";
            Database.Save();
            Progress.Buttons(true);
        }

        public void TestFuction(Form1 Progress)
        {
            if(Uses == null)
            {
                Uses = new Dictionary<int, Use>();
            }
            Dictionary<int, int[]> Lookup = new Dictionary<int, int[]>();
            using(Lua lu = new Lua())
            {
                lu.DoFile(@"D:\World of Warcraft Classic DEV ENVIROMENT\Interface\!Questie\Database\zone.lua"); 
                foreach (DictionaryEntry member in lu.GetTable("QuestieZones"))
                {
                    int lukeID = -1;
                    int[] z = new int[2];
                    foreach (DictionaryEntry Table in (LuaTable)member.Value)
                    {
                        if ((double)Table.Key == 1)
                        {
                            //MapID
                            lukeID = (int)((double)Table.Value);
                        }
                        else if ((double)Table.Key == 5)
                        {
                            //Z
                            z[1] = (int)((double)Table.Value);
                        }
                        else if ((double)Table.Key == 4)
                        {
                            //C
                            z[0] = (int)((double)Table.Value);
                        }
                    }
                    Lookup.Add(lukeID, z);
                }
            }

            Lua lua = new Lua();
            if (File.Exists(@"D:\World of Warcraft Classic DEV ENVIROMENT\Interface\!Questie\Database\items.lua"))
            {
                var result = lua.DoFile(@"D:\World of Warcraft Classic DEV ENVIROMENT\Interface\!Questie\Database\items.lua");
            }
            
            Progress.SetProgressBarMaximum(Quests.Count, true);
            foreach (KeyValuePair<int, Quest> Quest in Quests)
            {
                foreach (Objective Obj in Quest.Value.GetQuestObjectives())
                {
                    if (Obj.GetObjectiveType() == typeof(IItem))
                    {
                        Item i = (Item)Obj.GetSource();
                        if (i.Sources.Count < 2 && i.Sources.Count > 0)
                        {

                        }
                        else
                        {
                            if (i.Sources.Count > 0) { continue; }
                            foreach (DictionaryEntry member in lua.GetTable("QuestieItems"))
                            {
                                if (member.Key.ToString() == i.Name)
                                {
                                    foreach (DictionaryEntry Table in (LuaTable)member.Value)
                                    {
                                        if (Table.Key.ToString() == "locations")
                                        {
                                            foreach (DictionaryEntry LOC in (LuaTable)Table.Value)
                                            {
                                                double X = -1;
                                                double Y = -1;
                                                int mapid = -1;
                                                foreach (DictionaryEntry A in (LuaTable)LOC.Value)
                                                {
                                                    if ((double)A.Key == 1)
                                                    {
                                                        //MapID
                                                        mapid = (int)((double)A.Value);
                                                    }
                                                    else if ((double)A.Key == 2)
                                                    {
                                                        //X
                                                        X = (double)A.Value;
                                                    }
                                                    else if ((double)A.Key == 3)
                                                    {
                                                        //Y
                                                        Y = (double)A.Value;
                                                    }
                                                }
                                                if (!Uses.ContainsKey(i.GetID()) && Lookup[mapid][0] != -1 && Lookup[mapid][1] != -1)
                                                {
                                                    Uses.Add(i.GetID(), new Use(i.GetID(), new Coord(-1, X, Y, Lookup[mapid][0], Lookup[mapid][1])));
                                                }
                                                else if (Uses.ContainsKey(i.GetID()) && Lookup[mapid][0] != -1 && Lookup[mapid][1] != -1 && !Uses[i.GetID()].D_Locations.Contains(new Coord(-1, X, Y, Lookup[mapid][0], Lookup[mapid][1])))
                                                {
                                                    Uses[i.GetID()].AddCord(new Coord(-1, X, Y, Lookup[mapid][0], Lookup[mapid][1]));
                                                }
                                                if (Uses.ContainsKey(i.GetID()) && !Items[i.GetID()].Sources.Contains(Uses[i.GetID()]))
                                                {
                                                    Items[i.GetID()].AddSource(Uses[i.GetID()]);
                                                }
                                                //c.D_Locations.Add(new Coord(-1, X, Y, Lookup[mapid][0], Lookup[mapid][1]));

                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                Progress.StepProgressBar();
            }
            Database.Save();
        }


        /*
         *                             foreach (ISource source in i.Sources)
                            {
                                if (source.GetType() == typeof(Creature))
                                {
                                    Creature c = Creatures[source.GetID()];
                                    if (c.D_Locations.Count > 0) { continue; }
                                    foreach (DictionaryEntry member in lua.GetTable("QuestieItems"))
                                    {
                                        if (member.Key.ToString() == i.Name)
                                        {
                                            foreach (DictionaryEntry Table in (LuaTable)member.Value)
                                            {
                                                if (Table.Key.ToString() == "drop")
                                                {
                                                    foreach (DictionaryEntry NPC in (LuaTable)Table.Value)
                                                    {

                                                    }
                                                }
                                                else if(Table.Key.ToString() == "locations")
                                                {
                                                    foreach (DictionaryEntry LOC in (LuaTable)Table.Value)
                                                    {
                                                        double X = -1;
                                                        double Y = -1 ;
                                                        int mapid = -1;
                                                        foreach (DictionaryEntry A in (LuaTable)LOC.Value)
                                                        {
                                                            if((double)A.Key == 1)
                                                            {
                                                                //MapID
                                                                mapid = (int)((double)A.Value);
                                                            }
                                                            else if ((double)A.Key == 2)
                                                            {
                                                                //X
                                                                X = (double)A.Value;
                                                            }
                                                            else if ((double)A.Key == 3)
                                                            {
                                                                //Y
                                                                Y = (double)A.Value;
                                                            }
                                                        }
                                                        c.D_Locations.Add(new Coord(-1, X, Y, Lookup[mapid][0], Lookup[mapid][1]));
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                else if (source.GetType() == typeof(Item))
                                {
                                    Item c = Items[source.GetID()];
                                    if (c.Sources.Count > 0) { continue; }
                                    foreach (DictionaryEntry member in lua.GetTable("QuestieItems"))
                                    {
                                        foreach (DictionaryEntry Table in (LuaTable)member.Value)
                                        {
                                            if (Table.Key.ToString() == "locations")
                                            {
                                                foreach (DictionaryEntry LOC in (LuaTable)Table.Value)
                                                {
                                                    double X = -1;
                                                    double Y = -1;
                                                    int mapid = -1;
                                                    foreach (DictionaryEntry A in (LuaTable)LOC.Value)
                                                    {
                                                        if ((double)A.Key == 1)
                                                        {
                                                            //MapID
                                                            mapid = (int)((double)A.Value);
                                                        }
                                                        else if ((double)A.Key == 2)
                                                        {
                                                            //X
                                                            X = (double)A.Value;
                                                        }
                                                        else if ((double)A.Key == 3)
                                                        {
                                                            //Y
                                                            Y = (double)A.Value;
                                                        }
                                                    }
                                                    Uses.Add(source.GetID(), new Use(source.GetID(), new Coord(-1, X, Y, Lookup[mapid][0], Lookup[mapid][1])));
                                                    //c.D_Locations.Add(new Coord(-1, X, Y, Lookup[mapid][0], Lookup[mapid][1]));

                                                }
                                            }
                                        }
                                    }
                                }
                            }
         * */
        public void FetchCreatureCoordinates(Form1 Progress, bool forceUpdate = false)
        {
            Progress.AddProgressBarMaximum(Creatures.Count);
            Web web = new Web(true);
            foreach (KeyValuePair<int, Creature> i in Creatures)
            {
                if (i.Value.FetchDone() && !forceUpdate)
                {
                    Progress.StepProgressBar();
                    foreach(Coord c in i.Value.D_Locations)
                    {
                        c.Convert();
                    }
                    continue;
                }
                i.Value.FetchWebInformation(web);
                foreach (Coord c in i.Value.D_Locations)
                {
                    c.Convert();
                }
                Progress.StepProgressBar();
            }
            web.Quit();
            Database.Save();
        }
        public void FetchGameobjectCoordinates(Form1 Progress, bool forceUpdate = false)
        {
            Progress.AddProgressBarMaximum(Gameobjects.Count);
            Web web = new Web();
            foreach (KeyValuePair<int, Gameobject> i in Gameobjects)
            {
                if (i.Value.FetchDone() && !forceUpdate)
                {
                    Progress.StepProgressBar();
                    foreach (Coord c in i.Value.D_Locations)
                    {
                        c.Convert();
                    }
                    continue;
                }
                i.Value.FetchWebInformation(web);
                foreach (Coord c in i.Value.D_Locations)
                {
                    c.Convert();
                }
                Progress.StepProgressBar();
            }
            web.Quit();
            Database.Save();
        }
        
        public void FetchFactions(Form1 Progress,bool force = false)
        {
            Web web = new Web(true);
            Progress.SetProgressBarMaximum(Creatures.Count, true);
            foreach(KeyValuePair<int, Creature> c in Creatures)
            {
                c.Value.Faction(web, force);
                Progress.StepProgressBar();
            }
            Database.Save();
            web.Quit();
        }


        public void WriteLua(string Path)
        {
            List<int> ZoneOrSortSkip = new List<int>();
            ZoneOrSortSkip.Add(-22);//Seasonal
            ZoneOrSortSkip.Add(-364);//Darkmoon Faire
            ZoneOrSortSkip.Add(-366);//Lunar festival
            ZoneOrSortSkip.Add(-370);//Brewfest
            ZoneOrSortSkip.Add(-375);//Pilgrim's bou
            ZoneOrSortSkip.Add(-365);//Anh'qiraj war
            ZoneOrSortSkip.Add(-369);//midsummer
            ZoneOrSortSkip.Add(-374);//Nobelgarden
            ZoneOrSortSkip.Add(-376);//Love is in the Air

            StreamWriter SW = new StreamWriter(Path + "!Questie\\Database\\" + "DB_Quest.lua");
            SW.WriteLine("DB_Quests={");
            foreach(KeyValuePair<int, Quest> q in Quests)
            {
                if (q.Value.name == null) { 
                    continue; 
                }

                if (q.Value.name == "CLUCK!") { continue; }
                if (ZoneOrSortSkip.Contains(q.Value.ZoneOrSort)) { continue; }
                SW.WriteLine("[" + q.Value.QuestID + "]={");
                SW.WriteLine("\tID = " + q.Value.QuestID + ",");
                SW.WriteLine("\treqQuest = " + Math.Abs(q.Value.RequiresQuest) + ",");
                string T = q.Value.name.Replace("'", "\\'");
                SW.WriteLine("\tTitle = '" + T + "',");
                //SW.WriteLine("\t['"+q.Value.details.Replace("'","\\'")+"'] = {},");
                if (q.Value.GetQuestObjectives().Count > 0)
                {
                    SW.WriteLine("\tObjectives = {");
                    foreach (Objective o in q.Value.GetQuestObjectives())
                    {
                        SW.WriteLine("\t\t{type='" + o.GetObjectiveType().ToString().Replace("QuestieCrawler.", "").Remove(0, 1) + "', ID=" + o.GetSource().GetID() + ", Count=" + o.GetRequiredAmount() + "},");
                    }
                    SW.WriteLine("\t},");
                }
                SW.WriteLine("\tStarter = {");
                foreach(Objective s in q.Value.Starter)
                {
                    SW.WriteLine("\t\t{type='" + s.GetObjectiveType().ToString().Replace("QuestieCrawler.", "").Remove(0,1) + "', ID=" + s.GetSource().GetID()+"},");
                }
                SW.WriteLine("\t},");
                SW.WriteLine("\tFinisher = {");
                foreach (Objective s in q.Value.Finisher)
                {
                    SW.WriteLine("\t\t{type='" + s.GetObjectiveType().ToString().Replace("QuestieCrawler.", "").Remove(0, 1) + "', ID=" + s.GetSource().GetID() + "},");
                }
                SW.WriteLine("\t},");
                SW.WriteLine("\tminLevel = " + q.Value.reqLevel + ",");
                SW.WriteLine("\tLevel = " + q.Value.level + ",");
                SW.WriteLine("\treqRace = " + q.Value.reqRaces + ",");
                SW.WriteLine("\treqClass = " + q.Value.reqClasses + ",");
                SW.WriteLine("\treqSkill = " + q.Value.reqSkill + ",");
                SW.WriteLine("},");
            }
            SW.WriteLine("}");
            SW.Close();


            SW = new StreamWriter(Path + "!Questie\\Database\\" + "DB_Items.lua");
            SW.WriteLine("DB_Items={");
            foreach (KeyValuePair<int, Item> q in Items)
            {
                if (q.Value.Name == null || q.Value.GetSources().Count == 0) {
                    continue; 
                }
                SW.WriteLine("[" + q.Value.GetID() + "]={");
                SW.WriteLine("\tID = " + q.Value.GetID() + ",");
                string T = q.Value.Name.Replace("'", "\\'");
                SW.WriteLine("\tName = '" + T + "',");
                if (q.Value.GetSources().Count > 0)
                {
                    SW.Write("\tSources = {\n\t\t");
                    foreach (ISource o in q.Value.GetSources())
                    {
                        if (o.GetID() == q.Value.GetID() && o.GetType() != typeof(Use)) { continue; }
                        SW.Write("[" + o.GetID() + "] = {type='" + o.GetType().ToString().Replace("QuestieCrawler.", "").Replace("Creature", "NPC") + "', ID=" + o.GetID() + "},");
                    }
                    SW.WriteLine("\n\t},");
                }
                SW.WriteLine("},");
            }
            SW.WriteLine("}");
            SW.Close();

            SW = new StreamWriter(Path + "!Questie\\Database\\" + "DB_Uses.lua");
            SW.WriteLine("DB_Uses={");
            foreach (KeyValuePair<int, Use> q in Uses)
            {
                SW.WriteLine("[" + q.Value.GetID() + "]={");
                SW.WriteLine("\tID = " + q.Value.GetID() + ",");
                if (q.Value.D_Locations.Count > 0)
                {
                    SW.Write("\tLocations = {\n\t\t");
                    foreach (Coord o in q.Value.D_Locations)
                    {
                        SW.Write("{c=" + o.C.ToString().Replace(',', '.') + ",z=" + o.Z.ToString().Replace(',', '.') + ",x=" + (o.X).ToString().Replace(',', '.') + ",y=" + (o.Y).ToString().Replace(',', '.') + "},");
                    }
                    SW.WriteLine("\n\t},");
                }
                SW.WriteLine("},");
            }
            SW.WriteLine("}");
            SW.Close();

            SW = new StreamWriter(Path + "!Questie\\Database\\" + "DB_Creatures.lua");
            SW.WriteLine("DB_Creatures={");
            foreach (KeyValuePair<int, Creature> q in Creatures)
            {
                if (q.Value.Name == null) { continue; }
                SW.WriteLine("[" + q.Value.GetID() + "]={");
                SW.WriteLine("\tID = " + q.Value.GetID() + ",");
                string T = q.Value.Name.Replace("'", "\\'");
                SW.WriteLine("\tName = '" + T + "',");
                if (q.Value.D_Locations.Count > 0)
                {
                    SW.Write("\tLocations = {\n\t\t");
                    foreach (Coord o in q.Value.D_Locations)
                    {
                        SW.Write("{c=" + o.C.ToString().Replace(',', '.') + ",z=" + o.Z.ToString().Replace(',', '.') + ",x=" + (o.X/100).ToString().Replace(',', '.') + ",y=" + (o.Y/100).ToString().Replace(',', '.') + "},");
                    }
                    SW.WriteLine("\n\t},");
                }
                bool cont = false;
                foreach (KeyValuePair<string, int> o in q.Value.D_React)
                {
                    if(o.Value > -1)
                    {
                        cont = true;
                    }
                }
                if (cont && q.Value.D_React.Count != 0)
                {
                    SW.Write("\tReact = {\n\t\t");
                    foreach (KeyValuePair<string, int> o in q.Value.D_React)
                    {
                        SW.Write(o.Key + "=" + o.Value + ",");
                    }
                    SW.WriteLine("\n\t},");
                }
                SW.WriteLine("},");
            }
            SW.WriteLine("}");
            SW.Close();

            SW = new StreamWriter(Path + "!Questie\\Database\\" + "DB_Gameobjects.lua");
            SW.WriteLine("DB_Gameobjects={");
            foreach (KeyValuePair<int, Gameobject> q in Gameobjects)
            {
                if (q.Key == 11500)
                {

                }
                if (q.Value.Name == null || q.Value.Name == "" || q.Value.D_Locations.Count ==  + 0 && q.Value.D_Drops.Count == 0) { continue; }
                SW.WriteLine("[" + q.Value.GetID() + "]={");
                SW.WriteLine("\tID = " + q.Value.GetID() + ",");
                string T = q.Value.Name.Replace("'", "\\'");
                SW.WriteLine("\tName = '" + T + "',");
                if (q.Value.D_Locations.Count > 0)
                {
                    SW.Write("\tLocations = {\n\t\t");
                    foreach (Coord o in q.Value.D_Locations)
                    {
                        SW.Write("{c=" + o.C.ToString().Replace(',', '.') + ",z=" + o.Z.ToString().Replace(',', '.') + ",x=" + (o.X / 100).ToString().Replace(',', '.') + ",y=" + (o.Y / 100).ToString().Replace(',', '.') + "},");
                    }
                    SW.WriteLine("\n\t},");
                }
                if (q.Value.D_Drops.Count > 0)
                {
                    SW.Write("\tDrops = {\n\t\t");
                    foreach (int itemid in q.Value.D_Drops)
                    {
                        SW.Write(itemid+",");
                    }
                    SW.WriteLine("\n\t},");
                }
                SW.WriteLine("},");
            }
            SW.WriteLine("}");
            SW.Close();

            SW = new StreamWriter(Path + "!Questie\\Database\\" + "DB_Zones.lua");
            SW.WriteLine("DB_Zones={");
            foreach(KeyValuePair<int, string> i in Coord.NameConvertion)
            {
                SW.WriteLine("\t['" + i.Value.Replace("'", "\\'") + "']={");
                SW.WriteLine("\t\tName='" + i.Value.Replace("'", "\\'") + "',");
                SW.WriteLine("\t\tWoWHeadID=" + i.Key+",");
                SW.WriteLine("\t\tC=" + Coord.Convertion[i.Key][0]+",");
                SW.WriteLine("\t\tZ=" + Coord.Convertion[i.Key][1]+",");
                SW.WriteLine("\t},");
            }
            SW.WriteLine("}");
            SW.Close();

            MySql.Data.MySqlClient.MySqlConnection dbConn = new MySql.Data.MySqlClient.MySqlConnection("Persist Security Info=False;server=localhost;database=mangos;uid=root;password=");
            dbConn.Open();
            Dictionary<int, Quest> LookUp = new Dictionary<int, Quest>();
            MySqlCommand cmd = dbConn.CreateCommand();
            cmd.CommandText = "SELECT * FROM `quest_template`;";
            MySqlDataReader reader = cmd.ExecuteReader();

                while (reader.Read())
                {
                    int id = int.Parse(reader["entry"].ToString());
                    string title = reader["title"].ToString();
                    string details = reader["details"].ToString();
                    LookUp.Add(id, new Quest(id));
                    LookUp[id].details = details;
                    LookUp[id].name = title;
                }
                dbConn.Close();
            SW = new StreamWriter(Path + "!Questie\\Database\\" + "DB_QuestLookup.lua");
            List<string> Written = new List<string>();
            SW.WriteLine("DB_QuestLookup={");
            foreach (KeyValuePair<int, Quest> q in LookUp)
            {
                if (Written.Contains(q.Value.name)) { continue; }
                SW.WriteLine("\t['" + q.Value.name.Replace("'", "\\'") + "']={");
                Written.Add(q.Value.name);
                string temp = Regex.Replace(q.Value.details, @"\r\n?|\n", "\\n");
                SW.WriteLine("\t\t['" + temp.Replace("'", "\\'").Replace("$B", "\\n") + "']=" + q.Value.QuestID + ",");

                foreach (KeyValuePair<int, Quest> q2 in LookUp)
                {
                    if (q.Value.name == q2.Value.name && q.Value.QuestID != q2.Value.QuestID && q.Value.details != q2.Value.details)
                    {
                        temp = Regex.Replace(q2.Value.details, @"\r\n?|\n", "\\n");
                        SW.WriteLine("\t\t['" + temp.Replace("'", "\\'").Replace("$B", "\\n") + "']=" + q2.Value.QuestID + ",");
                    }
                }

                SW.WriteLine("\t},");
            }
            SW.WriteLine("}");
            SW.Close();
            File.Copy(Path + "!Questie\\Database\\" + "DB_QuestLookup.lua", Path + "!DataStore_Quests\\Database\\" + "DB_QuestLookup.lua", true);
            File.Copy(Path + "!Questie\\Database\\" + "DB_Quest.lua", Path + "!DataStore_Quests\\Database\\" + "DB_Quest.lua", true);
        }
        public void WriteCon(string Path)
        {
            return;
            StreamWriter SW = new StreamWriter(Path + "!Questie\\Database\\" + "DB_Quest_min.lua");
            SW.Write("Quests={");
            foreach (KeyValuePair<int, Quest> q in Quests)
            {
                SW.Write("['" + q.Value.QuestID + "']={");
                SW.Write("ID=" + q.Value.QuestID + ",");
                SW.Write("reqQuest=" + q.Value.RequiresQuest + ",");
                string T = q.Value.name.Replace("'", "\\'");
                SW.Write("Title='" + T + "',");
                if (q.Value.GetQuestObjectives().Count > 0)
                {
                    SW.Write("Objectives={");
                    foreach (Objective o in q.Value.GetQuestObjectives())
                    {
                        SW.Write("{type='" + o.GetObjectiveType().ToString().Replace("QuestieCrawler.", "").Remove(1, 1) + "',ID=" + o.GetSource().GetID() + ",Count=" + o.GetRequiredAmount() + "},");
                    }
                    SW.Write("},");
                }
                SW.Write("Starter={");
                foreach (Objective s in q.Value.Starter)
                {
                    SW.Write("{type='" + s.GetObjectiveType().ToString().Replace("QuestieCrawler.", "").Remove(0, 1) + "',ID=" + s.GetSource().GetID() + "},");
                }
                SW.Write("},");
                SW.Write("Finisher={");
                foreach (Objective s in q.Value.Finisher)
                {
                    SW.Write("{type='" + s.GetObjectiveType().ToString().Replace("QuestieCrawler.", "").Remove(0, 1) + "',ID=" + s.GetSource().GetID() + "},");
                }
                SW.Write("},");
                SW.Write("minLevel=" + q.Value.reqLevel);
                SW.Write("Level=" + q.Value.level);
                SW.Write("reqRace=" + q.Value.reqRaces);
                SW.Write("reqClass=" + q.Value.reqLevel);
                SW.Write("},");
            }
            SW.Write("}");
            SW.Close();
        }
            
        public void DeepScanWebForQuestNames(Form1 Progress)
        {
            Web web = new Web();
            Zones z = new Zones();
            z.GetZones(Progress, web);
            Progress.SetProgressBarMaximum(z.World[0].Count+z.World[1].Count, true);
            foreach(KeyValuePair<int, List<int>> Continent in z.World)
            {
                foreach(int Zone in Continent.Value)
                {
                    web.Navigate("http://db.vanillagaming.org/?quests=" + Continent.Key + "." + Zone);
                    int Length = int.Parse(web.GetVar("g_listviews['quests']['data']['length']").ToString());
                    for(int i = 0;i < Length;i++)
                    {
                        int QuestID = int.Parse(web.GetVar("g_listviews['quests']['data'][" + i + "]['id']").ToString());
                        string QuestName = web.GetVar("g_listviews['quests']['data'][" + i + "]['name']").ToString();
                        if(Quests.ContainsKey(QuestID))
                        {
                            Quests[QuestID].name = QuestName;
                        }
                        else
                        {
                            Quests.Add(QuestID, new Quest(QuestID));
                        }
                    }
                    Progress.StepProgressBar();
                }
            }
            Database.Save();
            web.Quit();
        }

        static byte[] GetBytes(string str)
        {
            byte[] bytes = new byte[str.Length * sizeof(char)];
            System.Buffer.BlockCopy(str.ToCharArray(), 0, bytes, 0, bytes.Length);
            return bytes;
        }

        public void DeepScanAll(Form1 Progress, bool forceUpdate = false)
        {

            Web web = new Web();
            Progress.Buttons(false);
            Progress.SetProgressBarMaximum(Creatures.Count + Gameobjects.Count + Items.Count + Quests.Count, true);
            //web.Init();
            foreach (KeyValuePair<int, Creature> c in Creatures)
            {
                c.Value.FetchWebInformation(web, forceUpdate);
                Progress.StepProgressBar();
                Progress.SetProgressBarMaximum(Creatures.Count + Gameobjects.Count + Items.Count + Quests.Count);
            }
            Database.Save();
            foreach (KeyValuePair<int, Quest> c in Quests)
            {
                c.Value.FetchWebInformation(web, forceUpdate);
                Progress.StepProgressBar();
                Progress.SetProgressBarMaximum(Creatures.Count + Gameobjects.Count + Items.Count + Quests.Count);
            }

            Database.Save();
            foreach (KeyValuePair<int, Gameobject> c in Gameobjects)
            {
                c.Value.FetchWebInformation(web, forceUpdate);
                Progress.StepProgressBar();
                Progress.SetProgressBarMaximum(Creatures.Count + Gameobjects.Count + Items.Count + Quests.Count);
            }
            Database.Save();
            foreach (KeyValuePair<int, Item> c in Items)
            {
                c.Value.FetchWebInformation(web, forceUpdate);
                Progress.StepProgressBar();
                Progress.SetProgressBarMaximum(Creatures.Count + Gameobjects.Count + Items.Count + Quests.Count);
            }
            Database.Save();
            Progress.Buttons(true);
        }
    }
}
