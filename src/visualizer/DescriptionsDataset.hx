package visualizer;


typedef AbilityInfo = {
    var name : String;
    var description : String;
}

typedef ItemInfo = {
    var name : String;
    var description : String;
}

typedef AbilityMap = Map<String,AbilityInfo>;
typedef TypeEfficacyTable = Map<String,Int>;
typedef ItemMap = Map<String,ItemInfo>;

class DescriptionsDataset extends Dataset {
    public var abilities(default, null):AbilityMap;
    public var types_efficacy(default, null):TypeEfficacyTable;
    public var items(default, null):ItemMap;

    override public function load(callback) {
        makeRequest("descriptions.json", callback);
    }

    override function loadDone(data:Dynamic) {
        abilities = new AbilityMap();
        var abilitiesDoc = Reflect.field(data, "abilities");

        for (slug in Reflect.fields(abilitiesDoc)) {
            abilities.set(slug, Reflect.field(abilitiesDoc, slug));
        }

        types_efficacy = new TypeEfficacyTable();
        var typesDoc = Reflect.field(data, "types_efficacy");

        for (firstType in Reflect.fields(typesDoc)) {
            var secondTypesDoc = Reflect.field(typesDoc, firstType);

            for (secondType in Reflect.fields(secondTypesDoc)) {
                var efficacy = Reflect.field(secondTypesDoc, secondType);
                types_efficacy.set('$firstType*$secondType', efficacy);
            }
        }

        items = new ItemMap();

        var itemsDoc = Reflect.field(data, "items");

        for (slug in Reflect.fields(itemsDoc)) {
            items.set(slug, Reflect.field(itemsDoc, slug));
        }

        super.loadDone(data);
    }

    public function getAbilityName(slug:String):String {
        return abilities.get(slug).name;
    }

    public function getItemName(slug:String):String {
        return items.get(slug).name;
    }

    public function getTypeEfficacy(user:String, foe:String, ?foeSecondary:String):Int {
        var efficacy:Int = types_efficacy.get('$user*$foe');

        if (foeSecondary == null) {
            return efficacy;
        }

        var secondaryEfficacy:Int = types_efficacy.get('$user*$foeSecondary');

        var pair = [efficacy, secondaryEfficacy];

        return switch (pair) {
            case [0, _]:
                0;
            case [_, 0]:
                0;
            case [200, 200]:
                400;
            case [50, 50]:
                25;
            case [50, 200]:
                100;
            case [200, 50]:
                100;
            case [200, 100]:
                200;
            case [100, 200]:
                200;
            case [50, 100]:
                50;
            case [100, 50]:
                50;
            default:
                100;
        }
    }
}
