package visualizer.dataset;


import visualizer.datastruct.PokemonStats;
import visualizer.api.APIFacade;
import visualizer.dataset.Dataset;


class CurrentMatchDataset implements DatasetLoadable {
    var apiFacade:APIFacade;
    public var pokemonStatsList:Array<PokemonStats>;

    public function new() {
        apiFacade = new APIFacade();
    }

    public function load(callback:DatasetLoadCallback) {
        apiFacade.getCurrentMatch(function (success:Bool, errorMessage:String, pokemonStatsList:Array<PokemonStats>) {
            if (success) {
                this.pokemonStatsList = pokemonStatsList;
            } else {
                this.pokemonStatsList = null;
            }
            callback(new LoadEvent(success, errorMessage));
        });
    }
}
