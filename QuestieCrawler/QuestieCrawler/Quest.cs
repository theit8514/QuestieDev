using MySql.Data.MySqlClient;
using OpenQA.Selenium;
using OpenQA.Selenium.PhantomJS;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace QuestieCrawler
{
    
    [Serializable]
    public class Quest
    {
        public bool Initialized = false;
        //Do convertions
        int category;
        int category2;
        public int QuestID; //Done
        public int level; //Done
        public string name; //Done
        public string details; //Done
        public int reqLevel; //Done
        public int reqRaces; //Done
        public int reqClasses;
        public int reqSkill;
        public int ZoneOrSort;
        public int NextQuestInChain;
        int type;
        int xp;

        bool DeepFetchDone = false;

        public List<Objective> Starter = new List<Objective>(); //Done
        public List<Objective> Finisher = new List<Objective>(); //Done
        public int RequiresQuest; //Done
        List<int> ItemRewards = new List<int>();
        List<String> WeirdQuestObjectives = new List<String>();


        public Quest(int category, int category2, int QuestID, int level, string name, int reqLevel, int reqRaces, int xp)
        {
            this.category = category;
            this.category2 = category2;
            this.QuestID = QuestID;
            this.level = level;
            this.name = name;
            this.reqLevel = reqLevel;
            this.reqRaces = reqRaces;
            this.type = type;
            this.xp = xp;
            //this.ItemRewards = ItemRewards;
        }

        public Quest(int QuestID)
        {
            this.QuestID = QuestID;
        }

        public void RemoveDuplicates()
        {

            if (Finisher != null)
            {
                List<Objective> Distinct = new List<Objective>();
                foreach (Objective o in Finisher)
                {
                    bool found = false;
                    foreach (Objective o2 in Distinct)
                    {

                        // 
                        if (o.GetObjectiveType() == o2.GetObjectiveType() && o.GetSource().GetID() == o2.GetSource().GetID())
                        {
                            found = true;
                            break;
                        }
                    }
                    if (!found)
                    {
                        Distinct.Add(o);
                    }
                }
                Finisher = Distinct;
            }

            if (Starter != null)
            {
                List<Objective> Distinct = new List<Objective>();
                foreach (Objective o in Starter)
                {
                    bool found = false;
                    foreach (Objective o2 in Distinct)
                    {

                        // 
                        if (o.GetObjectiveType() == o2.GetObjectiveType() && o.GetSource().GetID() == o2.GetSource().GetID())
                        {
                            found = true;
                            break;
                        }
                    }
                    if (!found)
                    {
                        Distinct.Add(o);
                    }
                }
                Starter = Distinct;
            }

            if (QuestObjectives != null)
            {
                List<Objective> Distinct = new List<Objective>();
                foreach (Objective o in QuestObjectives)
                {
                    bool found = false;
                    foreach (Objective o2 in Distinct)
                    {

                        // 
                        if (o.GetObjectiveType() == o2.GetObjectiveType() && o.GetSource().GetID() == o2.GetSource().GetID() && o.GetRequiredAmount() == o2.GetRequiredAmount())
                        {
                            found = true;
                            break;
                        }
                    }
                    if (!found)
                    {
                        Distinct.Add(o);
                    }
                }
                QuestObjectives = Distinct;
            }
        }

        public Quest(Web web, int ZoneID, int StarterNPC)
        {
            //Expects driver to be on the page already.
            if (!web.Url().ToLower().Contains("zone=" + ZoneID))
            {
                web.Navigate("http://db.vanillagaming.org/?zone=" + ZoneID);
            }
            int Length = int.Parse(web.GetVar("g_listviews['quests']['data'].length").ToString());
            //Todo: Do conversions!
            for (int i = 0; i < Length; i++)
            {
                this.category = int.Parse(web.GetVar("g_listviews['quests']['data']['" + i + "']['category']").ToString());
                this.category2 = int.Parse(web.GetVar("g_listviews['quests']['data']['" + i + "']['category2']").ToString());
                this.QuestID = int.Parse(web.GetVar("g_listviews['quests']['data']['" + i + "']['id']").ToString());
                this.level = int.Parse(web.GetVar("g_listviews['quests']['data']['" + i + "']['level']").ToString());
                this.name = web.GetVar("g_listviews['quests']['data']['" + i + "']['name']").ToString();
                this.reqLevel = int.Parse(web.GetVar("g_listviews['quests']['data']['" + i + "']['reqlevel']").ToString());
                this.reqRaces = int.Parse(web.GetVar("g_listviews['quests']['data']['" + i + "']['side']").ToString());
                this.type = int.Parse(web.GetVar("g_listviews['quests']['data']['" + i + "']['type']").ToString());
                this.xp =int.Parse( web.GetVar("g_listviews['quests']['data']['" + i + "']['xp']").ToString());
            }

            //Todo: Check if the itemrewards var even exists
            /*int ItemRewardsLength = Web.GetVar("g_listviews['quests']['data']['" + i + "']['itemrewards']['length']");
            for (int i = 0; i < ItemRewardsLength; i++)
            {
                ItemRewards.Add(int.Parse(web.GetVar("g_listviews['quests']['data']['" + i + "']['itemrewards']['" + i + "'][0]").ToString()));
            }*/
        }

        public void FetchDBInformation()
        {
         
        }

        public void FetchWebInformation(Web web, bool forceUpdate = false)
        {
            if (DeepFetchDone && !forceUpdate) { return; }
            web.Navigate("http://db.vanillagaming.org/?quest=" + QuestID);

            ParseQuestObjectives(web);

            /*IWebElement table = driver.FindElement(By.Class("infobox"));
            foreach (IWebElement table in table)
            {
                //Todo: see what information is here then use that to read this:
                /*
                        Log Levels
                        Log RequiredLevel
                        Log Side
                        Log Start (this should be written to the quest) and NPCs
                        Log End (this should be written to the quest) and NPCs
                        Log QuestSeries, Before and Next quest
 
                */
            //}*/
            web.State = WorkingState.Idle;
        }

        List<Objective> QuestObjectives = new List<Objective>();

        public void AddQuestObjective(Objective obj)
        {
            if (!QuestObjectives.Contains(obj))
            {
                QuestObjectives.Add(obj);
            }
            else
            {

            }
        }

        public List<Objective> GetQuestObjectives()
        {
            return QuestObjectives;
        }

        public void ParseQuestObjectives(Web web)
        {
            IWebElement table;
            //TODO: Create the QuestObjectives using the ISource Interface, first figure out if its NPC ITEM or Object then use that ISource
            try
            {
                table = web.driver.FindElement(By.ClassName("iconlist"));
            }
            catch { return; }

            foreach (IWebElement t in table.FindElements(By.TagName("td")))
            {
                IWebElement HrefData;
                try
                {
                    HrefData = t.FindElement(By.TagName("a"));
                }
                catch
                {
                    WeirdQuestObjectives.Add(t.Text);
                    return;
                }
                string href = HrefData.GetAttribute("href");
                int ID = int.Parse(href.Split('=')[1]);
                if (href.Contains("item"))
                {
                    //lootable Deepscan in item section
                    if (HrefData.Text.Contains("(") && HrefData.Text.Contains(")"))
                    {
                        //multi items
                        string Multi = Regex.Match(HrefData.Text, @"\((.+?)\)").Groups[1].Value;
                        if (!Database.DB.Items.ContainsKey(ID))
                        {
                            string Name = HrefData.Text.Split('(')[0].TrimEnd(' ');
                            Database.DB.Items.Add(ID, new Item(ID, Name));
                        }
                        QuestObjectives.Add(new Objective(Database.DB.Items[ID], 1));
                    }
                    else
                    {
                        //single item
                        if (!Database.DB.Items.ContainsKey(ID))
                        {
                            string Name = HrefData.Text.Split('(')[0];
                            Database.DB.Items.Add(ID, new Item(ID, Name));
                        }
                        QuestObjectives.Add(new Objective(Database.DB.Items[ID], 1));
                    }
                }
                else if (href.Contains("npc"))
                {
                    if (HrefData.Text.Contains("slain"))
                    {
                        if (HrefData.Text.Contains("(") && HrefData.Text.Contains(")"))
                        {
                            //multislay
                        }
                        else
                        {
                            //single slay
                            QuestObjectives.Add(new Objective(Database.DB.Creatures[ID], 1));
                        }
                    }
                }
                else if(href.Contains("object"))
                {
                    if (!Database.DB.Gameobjects.ContainsKey(ID))
                    {
                        Database.DB.Gameobjects.Add(ID, new Gameobject(ID,""));
                    }
                    QuestObjectives.Add(new Objective(Database.DB.Gameobjects[ID], 1));
                }
                else
                {
                    throw new System.InvalidOperationException("Unknown type: " + href);
                }
                //Todo: see what information is here then use that to read this:
                /*
                <table class="iconlist">
                <tbody><tr><th><ul><li><var>&nbsp;</var></li></ul></th><td><a href="?npc=2404">Blacksmith Verringtan</a> slain</td></tr><tr><th><ul><li><var>&nbsp;</var></li></ul></th><td><a href="?npc=2265">Hillsbrad Apprentice Blacksmith</a> slain (4)</td></tr><tr><th align="right" id="iconlist-icon0"><div class="iconsmall"><ins style='background-image: url("images/icons/small/inv_crate_01.jpg");'></ins><del></del><a href="?item=3564" rel="1"></a></div></th><td><span class="q1"><a href="?item=3564">Shipment of Iron</a></span></td></tr></tbody></table>
                Example from QID = 529
 
                If nothing can be found here log it.
                if(slain){
                        Add npc to creaturelist if it doesn't exist
                }*/
            }
        }

    }
}
