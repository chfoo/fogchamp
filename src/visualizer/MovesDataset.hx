package visualizer;


class MovesDataset extends Dataset {
    public var moves(default, null):Dynamic;

    public function new() {
        super();
    }

    override public function load(callback) {
        makeRequest("moves.json", callback);
    }

    override function loadDone(data:Dynamic) {
        moves = data;
        super.loadDone(data);
    }

    public function getMoveStats(slug:String, ?pokemonStat:Dynamic):Dynamic {
        var moveStat = Reflect.field(moves, slug);
        Reflect.setField(moveStat, "slug", slug);

        if (pokemonStat != null && slug == "hidden-power" && Reflect.hasField(pokemonStat, "move_type_override")) {
            Reflect.setField(moveStat, "move_type", pokemonStat.move_type_override);
        }

        return moveStat;
    }
}
