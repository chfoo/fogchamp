package visualizer;


import haxe.ds.Vector;


class PokemonDataset extends Dataset {
    public var slugs(default, null):Vector<String>;
    public var stats(default, null):Map<String, Dynamic>;

    public function new() {
        super();
    }

    override public function load(callback) {
        makeRequest("pbr-platinum.json", callback);
    }

    override function loadDone(data:Dynamic) {
        slugs = Reflect.field(data, "pokemon_slugs");
        stats = Reflect.field(data, "stats");
        super.loadDone(data);
    }

    public function getPokemonStats(slug:String):Dynamic {
        return Reflect.field(stats, slug);
    }

    public function getSlug(pokemonNum:Int):String {
        for (slug in slugs) {
            var stats = getPokemonStats(slug);
            if (stats.number == pokemonNum) {
                return slug;
            }
        }

        throw "Unknown Pokemon number.";
    }
}
