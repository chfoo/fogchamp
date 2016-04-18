package visualizer;


class DescriptionsDataset extends Dataset {
    public var abilities(default, null):Dynamic;
    public var types_efficacy(default, null):Dynamic;
    public var items(default, null):Dynamic;

    override public function load(callback) {
        makeRequest("descriptions.json", callback);
    }

    override function loadDone(data:Dynamic) {
        abilities = data.abilities;
        types_efficacy = data.types_efficacy;
        items = data.items;
        super.loadDone(data);
    }

    public function getAbilityName(slug:String):Dynamic {
        return Reflect.field(abilities, slug).name;
    }

    public function getItemName(slug:String):Dynamic {
        return Reflect.field(items, slug).name;
    }

    public function getTypeEfficacy(user:String, foe:String, ?foeSecondary:String):Int {
        var efficacy:Int = Reflect.field(Reflect.field(types_efficacy, user), foe);

        if (foeSecondary == null) {
            return efficacy;
        }

        var secondaryEfficacy:Int = Reflect.field(Reflect.field(types_efficacy, user), foeSecondary);

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
