package visualizer.datastruct;

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
    public var nickname:String;
    public var number:Int;
    public var specialAttack:Int;
    public var specialDefense:Int;
    public var speed:Int;
    public var types:Array<String>;
    public var weight:Int;
    public var slug:String;

    public function new() {
    }

    public function fromJsonObject(doc:Dynamic) {
        ability = Reflect.field(doc, "ability");
        attack = Reflect.field(doc, "attack");
        defense = Reflect.field(doc, "defense");
        gender = Reflect.field(doc, "gender");
        happiness = Reflect.field(doc, "happiness");
        hp = Reflect.field(doc, "hp");
        item = Reflect.field(doc, "item");
        iv = Reflect.field(doc, "iv");
        moveTypeOverride = Reflect.field(doc, "move_type_override");
        moves = Reflect.field(doc, "moves");
        name = Reflect.field(doc, "name");
        nature = Reflect.field(doc, "nature");
        nickname = Reflect.field(doc, "nickname");
        number = Reflect.field(doc, "number");
        specialAttack = Reflect.field(doc, "special_attack");
        specialDefense = Reflect.field(doc, "special_defense");
        speed = Reflect.field(doc, "speed");
        types = Reflect.field(doc, "types");
        weight = Reflect.field(doc, "weight");
    }

    public function toJsonObject():Dynamic {
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
            "nickname": nickname,
            "number": number,
            "special_attack": specialAttack,
            "special_defense": specialDefense,
            "speed": speed,
            "types": types,
            "weight": weight
        }
    }

    public function clone():PokemonStats {
        var stat = new PokemonStats();
        stat.slug = slug;
        stat.fromJsonObject(toJsonObject());
        return stat;
    }
}
