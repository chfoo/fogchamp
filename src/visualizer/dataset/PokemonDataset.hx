package visualizer.dataset;

import visualizer.dataset.Dataset;
import visualizer.datastruct.PokemonStats;
import haxe.ds.Vector;


typedef DatasetDoc = {
    slugs: Vector<String>,
    stats: Map<String, PokemonStats>
};


class PokemonDataset extends Dataset {
    static public var DATASET_FILES(default, null) = ["pbr-gold.json", "pbr-platinum.json", "pbr-seel.json", "pbr-gold-1.2.json", "pbr-gold-1.2-2015-11-07.json", "pbr-2.0.json"];
    static public var DATASET_NAMES(default, null) = ["Nkekev PBR Gold", "Nkekev PBR Platinum", "TPPVisuals PBR Seel", "Addarash1/Chaos_lord PBR Gold 1.2", "Chauzu PBR Gold 1.2 2015-11-07", "Addarash1 PBR 2.0"];
    static public var DEFAULT_INDEX(default, null) = 5;

    var datasets:Array<DatasetDoc>;
    var speciesIdToSlugMap:Map<Int, String>;

    public var slugs(get, null):Vector<String>;
    public var stats(get, null):Map<String, PokemonStats>;

    public var datasetIndex = 0;

    public function new() {
        super();
        datasets = new Array<DatasetDoc>();
        speciesIdToSlugMap = new Map<Int, String>();
    }

    override public function load(callback) {
        datasetIndex = 0;
        loadOneDataset(callback);
    }

    function loadOneDataset(originalCallback) {
        var filename = DATASET_FILES[datasetIndex];

        makeRequest(filename, function (loadEvent:LoadEvent) {
            if (loadEvent.success) {
                datasetIndex += 1;

                if (datasetIndex < DATASET_FILES.length) {
                    loadOneDataset(originalCallback);
                } else {
                    if (DEFAULT_INDEX >= 0) {
                        datasetIndex = DEFAULT_INDEX;
                    } else {
                        datasetIndex -= 1;
                    }
                    originalCallback(loadEvent);
                }
            } else {
                originalCallback(loadEvent);
            }
        });
    }

    override function loadDone(data:Dynamic) {
        var slugs:Vector<String> = Reflect.field(data, "pokemon_slugs");
        var statsDoc = Reflect.field(data, "stats");
        var stats = new Map<String, PokemonStats>();

        for (slug in slugs) {
            var pokemonStats = new PokemonStats(slug);
            pokemonStats.fromJsonObject(Reflect.field(statsDoc, slug));
            stats.set(slug, pokemonStats);
            speciesIdToSlugMap.set(pokemonStats.number, slug);
        };

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

    function get_stats():Map<String, PokemonStats> {
        return datasets[datasetIndex].stats;
    }

    public function getPokemonStats(slug:String):PokemonStats {
        if (!stats.exists(slug)) {
            throw new DatasetItemNotFoundError();
        }

        var pokemonStat = new PokemonStats();
        pokemonStat.slug = slug;
        pokemonStat.update(stats.get(slug));
        return pokemonStat;
    }

    public function getSlug(pokemonNum:Int):String {
        if (speciesIdToSlugMap.exists(pokemonNum)) {
            return speciesIdToSlugMap.get(pokemonNum);
        }

        throw new DatasetItemNotFoundError();
    }
}
