package visualizer.dataset;


import visualizer.datastruct.MovesetPokemonStats;
import visualizer.datastruct.PokemonStats;
import visualizer.api.APIFacade;
import visualizer.dataset.Dataset;


class CurrentMatchDataset implements DatasetLoadable {
    var apiFacade:APIFacade;
    public var pokemonStatsList:Array<MovesetPokemonStats>;
    public var slugs:Array<String>;

    public function new() {
        apiFacade = new APIFacade();
    }

    public function load(callback:DatasetLoadCallback) {
        apiFacade.getCurrentMatch(function (success:Bool, errorMessage:String, pokemonStatsList:Array<MovesetPokemonStats>) {
            if (success) {
                this.pokemonStatsList = pokemonStatsList;

                slugs = new Array<String>();

                for (stats in pokemonStatsList) {
                    stats.slug = APIFacade.slugify('${stats.name}-current');
                    stats.movesetName = "Current";
                    slugs.push(stats.slug);
                }

            } else {
                this.pokemonStatsList = null;
            }
            callback(new LoadEvent(success, errorMessage));
        });
    }

    public function getPokemonStats(slug:String):PokemonStats {
        for (stats in pokemonStatsList) {
            if (stats.slug == slug) {
                return stats;
            }
        }

        throw "Not found";
    }
}
