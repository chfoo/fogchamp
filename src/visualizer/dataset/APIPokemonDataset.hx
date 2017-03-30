package visualizer.dataset;

import haxe.Json;
import js.Browser;
import visualizer.datastruct.MovesetPokemonStats;
import visualizer.api.APIFacade;


class StorageEmpty {
    public function new() {
    }
}

class APIPokemonDataset extends Dataset {
    static public var STORAGE_KEY = "tpp-api-moveset";
    public var slugs(default, null):Array<String>;

    var stats:Map<String, MovesetPokemonStats>;
    var apiFacade:APIFacade;

    public function new() {
        super();
        slugs = [];
        stats = new Map<String, MovesetPokemonStats>();
        this.apiFacade = new APIFacade();
    }

    override public function load(callback:Bool->Void) {
        apiFacade.getPokemonSets(
            function (success:Bool, errorMessage:String, pokemonStatsList:Array<MovesetPokemonStats>) {
                if (success) {
                    loadPokemon(pokemonStatsList);
                }
                callback(success);
            }
        );
    }

    public function getPokemonStats(slug:String):MovesetPokemonStats {
        return stats.get(slug);
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

    function loadPokemon(pokemonStatsList:Array<MovesetPokemonStats>) {
        for (pokemonStats in pokemonStatsList) {
            pokemonStats.slug = APIFacade.slugify(pokemonStats.name + "-" + pokemonStats.movesetName);
            slugs.push(pokemonStats.slug);
            stats.set(pokemonStats.slug, pokemonStats);
        }
    }

    public function loadFromStorage() {
        var slugs:Array<String> = Json.parse(
            Browser.window.localStorage.getItem('$STORAGE_KEY:slugs')
        );

        if (slugs == null) {
            throw new StorageEmpty();
        }

        for (slug in slugs) {
            var jsonStr = Browser.window.localStorage.getItem('$STORAGE_KEY:pokemon:$slug');
            var pokemonStats = new MovesetPokemonStats();
            pokemonStats.fromJson(Json.parse(jsonStr));

            stats.set(slug, pokemonStats);
        }

        this.slugs = slugs;
    }

    public function saveToStorage() {
        for (slug in stats.keys()) {
            var pokemonStats = stats.get(slug);
            Browser.window.localStorage.setItem(
                '$STORAGE_KEY:pokemon:$slug',
                Json.stringify(pokemonStats.toJson())
            );
        }

        Browser.window.localStorage.setItem(
            '$STORAGE_KEY:slugs', Json.stringify(slugs)
        );
    }
}
