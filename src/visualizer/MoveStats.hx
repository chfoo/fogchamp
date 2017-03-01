package visualizer;

class MoveStats {
    public var accuracy:Int;
    public var damageCategory:String;
    public var description:String;
    public var maxHits:Int;
    public var minHits:Int;
    public var moveType:String;
    public var name:String;
    public var power:Int;
    public var pp:Int;
    public var slug:String;


    public function new() {
    }

    static public function fromJson(slug:String, doc:Dynamic):MoveStats {
        var stat = new MoveStats();

        stat.accuracy = Reflect.field(doc, "accuracy");
        stat.damageCategory = Reflect.field(doc, "damage_category");
        stat.description = Reflect.field(doc, "description");
        stat.maxHits = Reflect.field(doc, "max_hits");
        stat.minHits = Reflect.field(doc, "min_hits");
        stat.moveType = Reflect.field(doc, "move_type");
        stat.name = Reflect.field(doc, "name");
        stat.power = Reflect.field(doc, "power");
        stat.pp = Reflect.field(doc, "pp");
        stat.slug = slug;

        return stat;
    }

    public function toJson():Dynamic {
        return {
            "accuracy": accuracy,
            "damage_category": damageCategory,
            "description": description,
            "max_hits": maxHits,
            "min_hits": minHits,
            "move_type": moveType,
            "name": name,
            "power": power,
            "pp": pp,
            "slug": slug
        }
    }

    public function clone():MoveStats {
        return MoveStats.fromJson(slug, toJson());
    }
}

