package visualizer.dataset;

import visualizer.dataset.Dataset;
import haxe.Json;
import js.Browser;
import visualizer.datastruct.MovesetPokemonStats;
import visualizer.api.APIFacade;

using StringTools;


class StorageEmpty {
    public function new() {
    }
}

class APIPokemonDataset extends Dataset {
    static public var STORAGE_KEY = "tpp-api-moveset";
    static public var STORAGE_VERISON = 2;
    static public var MIN_STORAGE_VERSION = 2;
    public var slugs(default, null):Array<String>;

    var stats:Map<String, MovesetPokemonStats>;
    var speciesIdToSlugMap:Map<Int, String>;
    public var apiFacade(default, null):APIFacade;

    public function new() {
        super();
        slugs = [];
        stats = new Map<String, MovesetPokemonStats>();
        speciesIdToSlugMap = new Map<Int, String>();
        this.apiFacade = new APIFacade();
    }

    override public function load(callback) {
        slugs = [];
        stats = new Map<String, MovesetPokemonStats>();

        apiFacade.getPokemonSets(
            function (success:Bool, errorMessage:String, pokemonStatsList:Array<MovesetPokemonStats>) {
                if (success) {
                    loadPokemon(pokemonStatsList);
                }
                callback(new LoadEvent(success, errorMessage));
            }
        );
    }

    public function getPokemonStats(slug:String):MovesetPokemonStats {
        return stats.get(slug);
    }

    public function getSlug(pokemonNum:Int):String {
        if (speciesIdToSlugMap.exists(pokemonNum)) {
            return speciesIdToSlugMap.get(pokemonNum);
        }

        throw new DatasetItemNotFoundError();
    }

    function loadPokemon(pokemonStatsList:Array<MovesetPokemonStats>) {
        for (pokemonStats in pokemonStatsList) {
            pokemonStats.slug = APIFacade.slugify(pokemonStats.name + "-" + pokemonStats.movesetName);
            slugs.push(pokemonStats.slug);
            stats.set(pokemonStats.slug, pokemonStats);
        }

        buildSpeciesIdSlugMap();
    }

    public function loadFromStorage() {
        var versionStr = Browser.window.localStorage.getItem('$STORAGE_KEY:version');

        if (versionStr == null) {
            throw new StorageEmpty();
        }

        var version = Json.parse(versionStr);

        if (version < MIN_STORAGE_VERSION) {
            throw new StorageEmpty();
        }

        var slugs:Array<String> = Json.parse(
            Browser.window.localStorage.getItem('$STORAGE_KEY:slugs')
        );

        if (slugs == null) {
            throw new StorageEmpty();
        }

        for (slug in slugs) {
            var jsonStr = Browser.window.localStorage.getItem('$STORAGE_KEY:pokemon:$slug');

            if (jsonStr == null) {
                trace(jsonStr, "not found in storage. corrupted?");
                throw new StorageEmpty();
            }

            var pokemonStats = new MovesetPokemonStats();
            pokemonStats.fromJsonObject(Json.parse(jsonStr));

            stats.set(slug, pokemonStats);
        }

        this.slugs = slugs;

        buildSpeciesIdSlugMap();
    }

    public function saveToStorage() {
        for (slug in stats.keys()) {
            var pokemonStats = stats.get(slug);
            Browser.window.localStorage.setItem(
                '$STORAGE_KEY:pokemon:$slug',
                Json.stringify(pokemonStats.toJsonObject())
            );
        }

        Browser.window.localStorage.setItem(
            '$STORAGE_KEY:slugs', Json.stringify(slugs)
        );

        Browser.window.localStorage.setItem(
            '$STORAGE_KEY:version', Json.stringify(STORAGE_VERISON)
        );
    }

    public function clearStorage() {
        var deleteKeys = [];

        for (i in 0...Browser.window.localStorage.length) {
            var key = Browser.window.localStorage.key(i);

            if (key.startsWith(STORAGE_KEY)) {
                deleteKeys.push(key);
            }
        }

        for (key in deleteKeys) {
            Browser.window.localStorage.removeItem(key);
        }
    }

    function buildSpeciesIdSlugMap() {
        for (pokemonStats in stats.iterator()) {
            speciesIdToSlugMap.set(pokemonStats.number, pokemonStats.slug);
        }
    }
}
