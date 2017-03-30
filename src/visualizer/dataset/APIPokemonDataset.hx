package visualizer.dataset;

import visualizer.api.APIFacade;
import visualizer.datastruct.PokemonStats;


class APIPokemonDataset extends Dataset {
    public var slugs(default, null):Array<String>;

    var stats:Map<String, PokemonStats>;
    var apiFacade:APIFacade;

    public function new() {
        super();
        stats = new Map<String, PokemonStats>();
        this.apiFacade = new APIFacade();
    }

    override public function load(callback:Bool->Void) {
        callback(false);
    }
}
