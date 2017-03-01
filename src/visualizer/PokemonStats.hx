package visualizer;

class PokemonStats {
    public var ability:String;
    public var attack:Int;
    public var defense:Int;
    public var gender:String;
    public var happiness:Int;
    public var hp:Int;
    public var item:String;
    public var iv:Int;
    public var moveTypeOverride:String;
    public var moves:Array<String>;
    public var name:String;
    public var nature:String;
    public var number:Int;
    public var specialAttack:Int;
    public var specialDefense:Int;
    public var speed:Int;
    public var types:Array<String>;
    public var weight:Int;
    public var slug:String;

    public function new() {
    }

    static public function fromJson(slug:String, doc:Dynamic):PokemonStats {
        var stat = new PokemonStats();

        stat.ability = Reflect.field(doc, "ability");
        stat.attack = Reflect.field(doc, "attack");
        stat.defense = Reflect.field(doc, "defense");
        stat.gender = Reflect.field(doc, "gender");
        stat.happiness = Reflect.field(doc, "happiness");
        stat.hp = Reflect.field(doc, "hp");
        stat.item = Reflect.field(doc, "item");
        stat.iv = Reflect.field(doc, "iv");
        stat.moveTypeOverride = Reflect.field(doc, "move_type_override");
        stat.moves = Reflect.field(doc, "moves");
        stat.name = Reflect.field(doc, "name");
        stat.nature = Reflect.field(doc, "nature");
        stat.number = Reflect.field(doc, "number");
        stat.specialAttack = Reflect.field(doc, "special_attack");
        stat.specialDefense = Reflect.field(doc, "special_defense");
        stat.speed = Reflect.field(doc, "speed");
        stat.types = Reflect.field(doc, "types");
        stat.weight = Reflect.field(doc, "weight");
        stat.slug = slug;

        return stat;
    }

    public function toJson():Dynamic {
        return {
            "ability": ability,
            "attack": attack,
            "defense": defense,
            "gender": gender,
            "happiness": happiness,
            "hp": hp,
            "item": item,
            "iv": iv,
            "move_type_override": moveTypeOverride,
            "moves": moves,
            "name": name,
            "nature": nature,
            "number": number,
            "special_attack": specialAttack,
            "special_defense": specialDefense,
            "speed": speed,
            "types": types,
            "weight": weight
        }
    }
}
