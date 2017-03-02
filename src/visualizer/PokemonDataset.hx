package visualizer;

import haxe.ds.Vector;


typedef DatasetDoc = {
    slugs: Vector<String>,
    stats: Map<String, Dynamic>
};


class PokemonDataset extends Dataset {
    static public var DATASET_FILES(default, null) = ["pbr-gold.json", "pbr-platinum.json", "pbr-seel.json", "pbr-gold-1.2.json", "pbr-gold-1.2-2015-11-07.json", "pbr-2.0.json", "pbr-2.0.json"];
    static public var DATASET_NAMES(default, null) = ["Nkekev PBR Gold", "Nkekev PBR Platinum", "TPPVisuals PBR Seel", "Addarash1/Chaos_lord PBR Gold 1.2", "Chauzu PBR Gold 1.2 2015-11-07", "Addarash1 PBR 2.0", "Customizable (2017)"];
    static public var DEFAULT_INDEX(default, null) = 6;
    static public var CUSTOMIZABLE_INDEX(default, null) = 6;

    var datasets:Array<DatasetDoc>;
    var customStats:Map<String, PokemonStats>;

    public var slugs(get, null):Vector<String>;
    public var stats(get, null):Map<String, Dynamic>;

    public var datasetIndex = 0;

    public function new() {
        super();
        datasets = new Array<DatasetDoc>();
        customStats = new Map<String, PokemonStats>();
    }

    override public function load(callback) {
        loadOneDataset(callback);
    }

    function loadOneDataset(originalCallback) {
        var filename = DATASET_FILES[datasetIndex];

        makeRequest(filename, function (success) {
            if (success) {
                datasetIndex += 1;

                if (datasetIndex < DATASET_FILES.length) {
                    loadOneDataset(originalCallback);
                } else {
                    if (DEFAULT_INDEX >= 0) {
                        datasetIndex = DEFAULT_INDEX;
                    } else {
                        datasetIndex -= 1;
                    }
                    originalCallback(success);
                }
            } else {
                originalCallback(success);
            }
        });
    }

    override function loadDone(data:Dynamic) {
        var slugs = Reflect.field(data, "pokemon_slugs");
        var stats = Reflect.field(data, "stats");

        var datasetDoc = {
            slugs: slugs,
            stats: stats
        }

        datasets.push(datasetDoc);

        super.loadDone(data);
    }

    function get_slugs():Vector<String> {
        return datasets[datasetIndex].slugs;
    }

    function get_stats():Map<String, Dynamic> {
        return datasets[datasetIndex].stats;
    }

    public function getPokemonStats(slug:String):PokemonStats {
        if (datasetIndex == CUSTOMIZABLE_INDEX && customStats.exists(slug)) {
            return customStats.get(slug).clone();
        } else {
            var pokemonStat = PokemonStats.fromJson(slug, Reflect.field(stats, slug));
            return pokemonStat;
        }
    }

    public function setPokemonStats(slug:String, stats:PokemonStats) {
        customStats.set(slug, stats.clone());
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
