package visualizer.model;

import visualizer.datastruct.MovesetPokemonStats;
import visualizer.dataset.APIPokemonDataset;
import visualizer.dataset.APIPokemonDataset;
import visualizer.datastruct.PokemonStats;
import visualizer.dataset.PokemonDataset;
import visualizer.dataset.DescriptionsDataset;
import visualizer.dataset.MovesDataset;

class PokemonDatabase {
    static public var API_EDITION = "API";

    public var pokemonDataset(default, null):PokemonDataset;
    public var movesDataset(default, null):MovesDataset;
    public var descriptionsDataset(default, null):DescriptionsDataset;
    public var apiPokemonDataset(default, null):APIPokemonDataset;

    var customStats:Map<String, PokemonStats>;
    var edition:String;

    public function new(pokemonDataset:PokemonDataset, apiPokemonDataset:APIPokemonDataset, movesDataset:MovesDataset, descriptionsDataset:DescriptionsDataset) {
        this.pokemonDataset = pokemonDataset;
        this.apiPokemonDataset = apiPokemonDataset;
        this.movesDataset = movesDataset;
        this.descriptionsDataset = descriptionsDataset;


        customStats = new Map<String, PokemonStats>();

        setEdition(PokemonDataset.DATASET_NAMES[0]);
    }

    public function getEditionNames():Array<String> {
        return PokemonDataset.DATASET_NAMES.concat([API_EDITION]);
    }

    public function getEdition():String {
        return edition;
    }

    public function getLastStaticEdition():String {
        return PokemonDataset.DATASET_NAMES[PokemonDataset.DEFAULT_INDEX];
    }

    public function setEdition(name:String) {
        edition = name;

        var editionIndex = PokemonDataset.DATASET_NAMES.indexOf(name);

        if (editionIndex >= 0) {
            pokemonDataset.datasetIndex = editionIndex;
        }
    }

    public function getPokemonSlugs():Array<String> {
        var slugs:Array<String>;

        if (edition == API_EDITION) {
            slugs = apiPokemonDataset.slugs;
        } else {
            slugs = pokemonDataset.slugs.toArray();
        }

        for (slug in customStats.keys()) {
            slugs.push(slug);
        }

        return slugs;
    }

    public function getPokemonStats(slug:String):PokemonStats {
        if (customStats.exists(slug)) {
            return customStats.get(slug).clone();
        } else if (edition == API_EDITION) {
            return apiPokemonDataset.getPokemonStats(slug);
        } else {
            return pokemonDataset.getPokemonStats(slug);
        }
    }

    public function getPokemonSlugByID(id:Int):String {
        if (edition == API_EDITION) {
            return apiPokemonDataset.getSlug(id);
        } else {
            return pokemonDataset.getSlug(id);
        }
    }

    public function setCustomPokemonStats(slug:String, stats:PokemonStats) {
        customStats.set(slug, stats.clone());
    }

    public function isCustomized(slug:String):Bool {
        return customStats.exists(slug);
    }

    public function backfillAPIMissingPokemonStats(stats:PokemonStats) {
        if (stats.slug == null) {
            stats.slug = getPokemonSlugByID(stats.number);
        }

        var originalDBIndex = getEdition();
        setEdition(getLastStaticEdition());
        var historicalStats = getPokemonStats(getPokemonSlugByID(stats.number));
        setEdition(originalDBIndex);

        stats.types = historicalStats.types;
        stats.weight = historicalStats.weight;

        if (stats.moves == null) {
            stats.moves = [];
        }
    }
}
