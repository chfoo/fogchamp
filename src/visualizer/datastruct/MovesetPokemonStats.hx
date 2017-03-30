package visualizer.datastruct;


class MovesetPokemonStats extends PokemonStats {
    public var abilitySet:Array<String>;
    public var itemSet:Array<String>;
    public var moveSets:Array<Array<String>>;
    public var movesetName:String;

    public function new() {
        super();
        abilitySet = new Array<String>();
        itemSet = new Array<String>();
        moveSets = new Array<Array<String>>();
    }

    override public function fromJsonObject(doc:Dynamic) {
        super.fromJsonObject(doc);

        abilitySet = Reflect.field(doc, "ability_set");
        itemSet = Reflect.field(doc, "item_set");
        moveSets = Reflect.field(doc, "move_sets");
        movesetName = Reflect.field(doc, "set_name");
    }

    override public function toJsonObject():Dynamic {
        var doc = super.toJsonObject();

        Reflect.setField(doc, "ability_set", abilitySet);
        Reflect.setField(doc, "item_set", itemSet);
        Reflect.setField(doc, "move_sets", moveSets);
        Reflect.setField(doc, "set_name", movesetName);

        return doc;
    }

    override public function clone():MovesetPokemonStats {
        var stat = new MovesetPokemonStats();
        stat.slug = slug;
        stat.fromJsonObject(toJsonObject());
        return stat;
    }
}
