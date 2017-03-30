package visualizer.datastruct;

class MoveStats implements Copyable<MoveStats> {
    public var slug:String;

    public var accuracy:Int;
    public var damageCategory:String;
    public var description:String;
    public var maxHits:Int;
    public var minHits:Int;
    public var moveType:String;
    public var name:String;
    public var power:Int;
    public var pp:Int;

    public function new(?slug:String) {
        this.slug = slug;
    }

    public function fromJsonObject(doc:Dynamic) {
        accuracy = Reflect.field(doc, "accuracy");
        damageCategory = Reflect.field(doc, "damage_category");
        description = Reflect.field(doc, "description");
        maxHits = Reflect.field(doc, "max_hits");
        minHits = Reflect.field(doc, "min_hits");
        moveType = Reflect.field(doc, "move_type");
        name = Reflect.field(doc, "name");
        power = Reflect.field(doc, "power");
        pp = Reflect.field(doc, "pp");

        if (Reflect.hasField(doc, "slug")) {
            slug = Reflect.field(doc, "slug");
        }
    }

    public function toJsonObject():Dynamic {
        return {
            "slug": slug,
            "accuracy": accuracy,
            "damage_category": damageCategory,
            "description": description,
            "max_hits": maxHits,
            "min_hits": minHits,
            "move_type": moveType,
            "name": name,
            "power": power,
            "pp": pp
        }
    }

    public function copy():MoveStats {
        var stats = new MoveStats();
        stats.fromJsonObject(toJsonObject());
        return stats;
    }
}

