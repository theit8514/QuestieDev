using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace QuestieCrawler
{
    [Serializable]
    public class Objective : IObjective
    {
        Type type;
        int ID;
        int RequireAmount;
        public ISource GetSource()
        {
            //TODO:
            if (type == typeof(INPC))
            {
                //TODO: Return the global creature var
                return Database.DB.Creatures[ID];
            }
            else if (type == typeof(IObject))
            {
                //TODO: Return the global object var
                return Database.DB.Gameobjects[ID];
            }
            else if (type == typeof(IItem))
            {
                //TODO: Return the global item var
                return Database.DB.Items[ID];
            }
            else { throw new System.ArgumentException("Invalid Type: Does not exist", type.ToString());}

            //todo: remove this
            return null;
        }
        public Type GetObjectiveType()
        {
            return type;
        }
        public int GetRequiredAmount() { return RequireAmount; }
        public Objective(ISource type, int Amount = 1)
        {
            if (type is INPC)
            {
                this.type = typeof(INPC);
            }
            else if (type is IObject)
            {
                this.type = typeof(IObject);
            }
            else if (type is IItem)
            {
                this.type = typeof(IItem);
            }
            else { throw new System.ArgumentException("Invalid Type: Does not exist", type.ToString()); }
            RequireAmount = Amount;
            ID = type.GetID();
        }
    }
}
