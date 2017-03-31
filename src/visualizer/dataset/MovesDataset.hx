package visualizer.dataset;

import visualizer.datastruct.PokemonStats;
import visualizer.datastruct.MoveStats;

typedef MovesMap = Map<String,MoveStats>;

class MovesDataset extends Dataset {
    public var moves(default, null):MovesMap;

    public function new() {
        super();
    }

    override public function load(callback) {
        makeRequest("moves.json", callback);
    }

    override function loadDone(data:Dynamic) {
        moves = new MovesMap();

        for (slug in Reflect.fields(data)) {
            var moveStats = new MoveStats(slug);
            moveStats.fromJsonObject(Reflect.field(data, slug));
            moves.set(slug, moveStats);
        }

        super.loadDone(data);
    }

    public function getMoveStats(slug:String, ?pokemonStat:PokemonStats):MoveStats {
        var moveStat = moves.get(slug).copy();

        if (pokemonStat != null && slug == "hidden-power" && pokemonStat.moveTypeOverride != null) {
            moveStat.moveType = pokemonStat.moveTypeOverride;
        }

        return moveStat;
    }
}
