using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace QuestieCrawler
{
        [Serializable]
        public class Item : IItem, ISource {
            int ID; //Done
            public string Name; //Done
            List<int> QuestsInvolved = new List<int>(); //QuestIDS;
            public List<ISource> Sources = new List<ISource>(); //Done
 
            //Deep Info
            bool DeepFetchDone = false;
            public void RemoveDuplicates()
            {
                if (Sources != null)
                {
                    List<ISource> Distinct = new List<ISource>();
                    foreach (ISource o in Sources)
                    {
                        bool found = false;
                        foreach (ISource o2 in Distinct)
                        {

                            // 
                            if ((o.GetType() == o2.GetType() && o.GetID() == o2.GetID()) || o.GetID() == ID)
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
                    Sources = Distinct;
                }
            }

            public Item(int ID, string Name)
            {
                this.ID = ID;
                this.Name = Name;
            }

            public void AddQuestInvolved(int id)
            {

            }
 
            public void AddSource(ISource src){Sources.Add(src);}
            public List<ISource> GetSources(){return Sources;} //Todo: rethink this, doing doubles like this is retarded.
            public int ItemID(){return ID;}
 
            public void FetchWebInformation(Web web, bool forceUpdate = false){
                    if(DeepFetchDone && !forceUpdate){return;}
                    web.Navigate("http://db.vanillagaming.org/?item="+ID);
                    //TODO Do stuff
                    //Get Where it drops / where it is contained in
                    DeepFetchDone = true;
            }
 
            public List<int> RequirementFor(){return QuestsInvolved;}
            public bool FetchDone(){ return DeepFetchDone; }
 
 
            //ISource
            public Type GetBaseType(){return typeof(IItem);}
            public int GetID(){return ID;}
     }
}
