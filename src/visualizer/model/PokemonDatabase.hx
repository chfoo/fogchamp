package visualizer.model;

import visualizer.dataset.Dataset;
import visualizer.datastruct.VisualizerPokemonStats;
import visualizer.dataset.CurrentMatchDataset;
import visualizer.datastruct.MovesetPokemonStats;
import visualizer.dataset.APIPokemonDataset;
import visualizer.datastruct.PokemonStats;
import visualizer.dataset.PokemonDataset;
import visualizer.dataset.DescriptionsDataset;
import visualizer.dataset.MovesDataset;

class StatsNotFoundError {
    public function new() {

    }
}

class PokemonDatabase {
    static public var API_EDITION = "API";

    public var pokemonDataset(default, null):PokemonDataset;
    public var movesDataset(default, null):MovesDataset;
    public var descriptionsDataset(default, null):DescriptionsDataset;
    public var apiPokemonDataset(default, null):APIPokemonDataset;
    public var currentMatchDataset(default, null):CurrentMatchDataset;

    var customStats:Map<String, PokemonStats>;
    var edition:String;

    public function new(pokemonDataset:PokemonDataset, apiPokemonDataset:APIPokemonDataset, movesDataset:MovesDataset, descriptionsDataset:DescriptionsDataset) {
        this.pokemonDataset = pokemonDataset;
        this.apiPokemonDataset = apiPokemonDataset;
        this.movesDataset = movesDataset;
        this.descriptionsDataset = descriptionsDataset;
        currentMatchDataset = new CurrentMatchDataset();

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
            slugs = apiPokemonDataset.slugs.copy();
        } else {
            slugs = pokemonDataset.slugs.toArray();
        }

        for (slug in customStats.keys()) {
            slugs.push(slug);
        }

        if (currentMatchDataset.slugs != null) {
            for (slug in currentMatchDataset.slugs) {
                slugs.push(slug);
            }
        }

        return slugs;
    }

    public function getPokemonStats(slug:String):VisualizerPokemonStats {
        var pokemonStats = new VisualizerPokemonStats();

        if (customStats.exists(slug)) {
            pokemonStats.update(customStats.get(slug));
            return pokemonStats;
        } else if (currentMatchDataset.slugs != null && currentMatchDataset.slugs.indexOf(slug) >= 0) {
            pokemonStats.update(currentMatchDataset.getPokemonStats(slug));
            return pokemonStats;
        } else if (edition == API_EDITION) {
            var stats = apiPokemonDataset.getPokemonStats(slug);
            if (stats != null) {
                pokemonStats.update(stats);
                backfillMissingPokemonStats(pokemonStats);
                pokemonStats.fillDefaultSets();
                return pokemonStats;
            } else {
                throw new StatsNotFoundError();
            }
        } else {
            try {
                var stats = pokemonDataset.getPokemonStats(slug);
                pokemonStats.update(stats);
                return pokemonStats;
            } catch (error:DatasetItemNotFoundError) {
                throw new StatsNotFoundError();
            }
        }
    }

    public function getPokemonSlugByID(id:Int, ?movesetName:String):String {
        try {
            if (edition == API_EDITION) {
                return apiPokemonDataset.getSlug(id, movesetName);
            } else {
                return pokemonDataset.getSlug(id);
            }
        } catch (error:DatasetItemNotFoundError) {
            throw new StatsNotFoundError();
        }
    }

    public function setCustomPokemonStats(slug:String, stats:PokemonStats) {
        customStats.set(slug, stats.copy());
    }

    public function isCustomized(slug:String):Bool {
        return customStats.exists(slug);
    }

    public function getCurrentMatchPokemonStats():Array<MovesetPokemonStats> {
        for (stats in currentMatchDataset.pokemonStatsList) {
            backfillMissingPokemonStats(stats);
        }

        return currentMatchDataset.pokemonStatsList;
    }

    function backfillMissingPokemonStats(stats:PokemonStats) {
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
