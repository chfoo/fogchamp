package visualizer.datastruct;


class MovesetPokemonStats extends PokemonStats {
    public var abilitySet:Array<String>;
    public var itemSet:Array<String>;
    public var moveSets:Array<Array<String>>;
    public var movesetName:String;

    public function new(?slug:String) {
        super(slug);
        abilitySet = new Array<String>();
        itemSet = new Array<String>();
        moveSets = new Array<Array<String>>();
    }

    public function fillDefaultSets() {
        if (ability == null && abilitySet != null && abilitySet.length > 0) {
            ability = abilitySet[0];
        }

        if (item == null && itemSet != null && itemSet.length > 0) {
            item = itemSet[0];
        }

        if ((moves == null || moves != null && moves.length == 0) && moveSets != null) {
            moves = new Array<String>();
            for (slotMovesSet in moveSets) {
                moves.push(slotMovesSet[0]);
            }
        }
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

    override public function copy():MovesetPokemonStats {
        var stat = new MovesetPokemonStats();
        stat.update(this);
        return stat;
    }
}
