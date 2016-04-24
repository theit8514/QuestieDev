using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using OpenQA.Selenium.PhantomJS;
using OpenQA.Selenium.Firefox;
using OpenQA.Selenium;

namespace QuestieCrawler
{
    public interface ISource
    {
        Type GetBaseType();
        int GetID();
    }

    public interface IItem
    {
        int ItemID();
        bool FetchDone();
        void FetchWebInformation(Web web, bool forceUpdate = false);
        List<int> RequirementFor();
        void AddSource(ISource src);
        List<ISource> GetSources();
    }

    public interface IQuestItem
    {
        int QuestID();
    }

    public interface IQuestObjective
    {
        List<Coord> Locations();
        string Name();
        int RequiredCount();
    }


    public interface INPC
    {
        int WoWheadMapID();
        int NpcID();
        bool FetchDone();
        List<Coord> NPCLocations();
        void FetchWebInformation(Web web, bool forceUpdate = false);
        List<int> RequirementFor();
    }

    public interface IObject
    {
        int WoWheadMapID();
        int ObjectID();
        bool FetchDone();
        List<Coord> ObjectLocations();
        List<int> RequirementFor();
        void FetchWebInformation(Web web, bool forceUpdate = false);
        bool IsContainer();
        List<int> Contains();
    }

    public interface IObjective
    {
        int GetRequiredAmount();
        ISource GetSource();
    }
}
