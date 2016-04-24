using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace QuestieCrawler
{
    [Serializable]
    public class Use : ISource
    {
        public int ID;//Arbretrary...
        public List<Coord> D_Locations = new List<Coord>();
        public Use(int ID, Coord cords)
        {
            this.ID = ID;
            D_Locations.Add(cords);
        }

        public void AddCord(Coord c)
        {
            D_Locations.Add(c);
        }

        public int GetID()
        {
            return ID;
        }

        public Type GetBaseType() { return typeof(Use); }
    }
}
