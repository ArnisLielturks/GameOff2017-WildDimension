namespace AchievementsBranch {
    Array<Achievements::AchievementItem> GetAchievments()
    {
        Array<Achievements::AchievementItem> items;
        int count = 1;
        while(true) {
            Achievements::AchievementItem item;
            item.eventName = "GetWood";
            item.name = "Get wood " + count;
            item.current = 0.0f;
            item.target = count;
            item.completed = false;
            items.Push(item);

            item.eventName = "GetRock";
            item.name = "Get rock " + count;
            item.current = 0.0f;
            item.target = count;
            item.completed = false;
            items.Push(item);

            count *= 10;
            
            if (count > 100) {
                break;
            }
        }
        return items;
    }
}