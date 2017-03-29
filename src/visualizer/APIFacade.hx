package visualizer;

import js.jquery.JQuery;
import js.jquery.JqXHR;

using StringTools;

typedef AjaxCallback = Dynamic -> String -> JqXHR -> Void;
typedef FailedAjaxCallback = JqXHR -> String -> Dynamic -> Void;
typedef CurrentMatchCallback = Bool -> String -> Array<PokemonStats> -> Void;
typedef PokemonSetsCallback = Bool -> String -> Array<PokemonStats> -> Void;

class APIFacade {
    static var CURRENT_MATCH_API_URL(default, null) = "https://twitchplayspokemon.tv/api/current_match";
//    static var CURRENT_MATCH_API_URL(default, null) = "/test_data/match.json";
    static var POKEMON_SETS_API_URL(default, null) = "https://twitchplayspokemon.tv/api/pokemon_sets?id&limit=100";
    static var CONSUME_CURSOR_API_URL(default, null) = "https://twitchplayspokemon.tv/api/cursor/";
    var pokemonDataset:PokemonDataset;
    var callInProgress = false;

    public function new(pokemonDataset:PokemonDataset) {
        this.pokemonDataset = pokemonDataset;
    }

    public function getCurrentMatch(callback:CurrentMatchCallback) {
        function successHandler(jsonResult:Dynamic, textStatus:String, xhr:JqXHR) {
            if (Reflect.hasField(jsonResult, "message")) {
                callback(false, Reflect.field(jsonResult, "message"), null);
            } else {
                var pokemonResults;

                try {
                    pokemonResults = parseMatchPokemon(jsonResult);
                } catch (error:Dynamic) {
                    callback(false, null, null);
                    return;
                }

                callback(true, null, pokemonResults);
            }
        }

        function errorHandler(xhr:JqXHR, textStatus:String, error:Dynamic) {
            var jsonResult = untyped xhr.responseJSON;
            if (jsonResult != null && Reflect.hasField(jsonResult, "message")) {
                callback(false, Reflect.field(jsonResult, "message"), null);
            } else {
                callback(false, xhr.statusText, null);
            }
        }

        callAPI(
            CURRENT_MATCH_API_URL,
            successHandler,
            errorHandler
        );
    }

    public function getPokemonSets(callback:PokemonSetsCallback) {
        var token:String;
        var pokemonResults = [];

        function callbackResults() {
            // TODO:
        }

        function errorHandler(xhr:JqXHR, textStatus:String, error:Dynamic) {
            var jsonResult = untyped xhr.responseJSON;
            if (jsonResult != null && Reflect.hasField(jsonResult, "message")) {
                callback(false, Reflect.field(jsonResult, "message"), null);
            } else {
                callback(false, xhr.statusText, null);
            }
        }

        function cursorErrorHandler(xhr:JqXHR, textStatus:String, error:Dynamic) {
            if (xhr.status == 410) {
                callbackResults();
            } else {
                errorHandler(xhr, textStatus, error);
            }
        }

        function cursorPaginateSuccessHandler(jsonResult:Dynamic, textStatus:String, xhr:JqXHR) {
            callAPI(
                CONSUME_CURSOR_API_URL + token,
                cursorPaginateSuccessHandler,
                cursorErrorHandler
            );
        }

        function cursorCreateSuccessHandler(jsonResult:Dynamic, textStatus:String, xhr:JqXHR) {
            token = jsonResult;

            callAPI(
                CONSUME_CURSOR_API_URL + token,
                cursorPaginateSuccessHandler,
                cursorErrorHandler
            );
        }

        callAPI(
            POKEMON_SETS_API_URL + "&create_cursor=true",
            cursorCreateSuccessHandler,
            errorHandler
        );
    }

    function callAPI(url:String, done:AjaxCallback, error:FailedAjaxCallback, ?post:Bool) {
        if (callInProgress) {
            throw "Call already in progress";
        }
        callInProgress = true;
        var xhr:JqXHR;

        if (!post) {
            xhr = JQuery.getJSON(url);
        } else {
            xhr = JQuery.post({"url": url, "dataType": "json"});
        }

        xhr.done(done).fail(error).always(function () {
            callInProgress = false;
        });
    }

    function parseMatchPokemon(jsonDoc:Dynamic):Array<PokemonStats> {
        var teams:Array<Dynamic> = Reflect.field(jsonDoc, "teams");
        var teamBlue:Array<Dynamic> = teams[0];
        var teamRed:Array<Dynamic> = teams[1];
        var pokemonStats = [];

        for (pokemonDoc in teamBlue) {
            pokemonStats.push(parsePokemonStats(pokemonDoc));
        }
        for (pokemonDoc in teamRed) {
            pokemonStats.push(parsePokemonStats(pokemonDoc));
        }

        return pokemonStats;
    }

    function parsePokemonStats(jsonDoc:Dynamic):PokemonStats {
        var stats = new PokemonStats();
        var speciesId:Int = Reflect.field(Reflect.field(jsonDoc, "species"), "id");
        var effectiveStats = Reflect.field(jsonDoc, "stats");
        stats.slug = pokemonDataset.getSlug(speciesId);
        var originalDBIndex = pokemonDataset.datasetIndex;
        pokemonDataset.datasetIndex = 5;
        var historicalStats = pokemonDataset.getPokemonStats(stats.slug);
        pokemonDataset.datasetIndex = originalDBIndex;

        if (Reflect.hasField(jsonDoc, "ability") && Reflect.field(jsonDoc, "ability") != null) {
            var rawName = Reflect.field(Reflect.field(jsonDoc, "ability"), "name");
            if (rawName != null) {
                stats.ability = slugify(rawName);
            }
        }

        stats.attack = Reflect.field(effectiveStats, "atk");
        stats.defense = Reflect.field(effectiveStats, "def");
        stats.gender = Reflect.field(jsonDoc, "gender");
        stats.happiness = Reflect.field(jsonDoc, "happiness");
        stats.hp = Reflect.field(effectiveStats, "hp");

        if (Reflect.hasField(jsonDoc, "item") && Reflect.field(jsonDoc, "item") != null) {
            var rawName = Reflect.field(Reflect.field(jsonDoc, "item"), "name");
            if (rawName != null) {
                stats.item = slugify(rawName);
            }
        }

        // TODO: load iv
        // stats.iv

        stats.moves = [];

        var moveDocList:Array<Dynamic> = Reflect.field(jsonDoc, "moves");
        for (moveDoc in moveDocList) {
            var moveSlug = slugify(Reflect.field(moveDoc, "name"));
            stats.moves.push(moveSlug);

            if (moveSlug == "hidden-power") {
                stats.moveTypeOverride = slugify(Reflect.field(moveDoc, "type"));
            }
        }

        stats.name = Reflect.field(jsonDoc, "ingamename");

        if (Reflect.hasField(jsonDoc, "nature") && Reflect.field(jsonDoc, "nature") != null) {
            stats.nature = slugify(Reflect.field(Reflect.field(jsonDoc, "nature"), "name"));
        }

        stats.number = speciesId;
        stats.specialAttack = Reflect.field(effectiveStats, "spA");
        stats.specialDefense = Reflect.field(effectiveStats, "spD");
        stats.speed = Reflect.field(effectiveStats, "spe");
        stats.types = historicalStats.types;
        stats.weight = historicalStats.weight;

        return stats;
    }

    static function slugify(text:String, ?noDash:Bool):String {
        text = text.toLowerCase()
            .replace("♀", "f")
            .replace("♂", "m")
            .replace(" ", "-")
            .replace("é", "e");

        if (noDash) {
            text = text.replace('-', '');
        }

        var asciiRegex = new EReg("[^a-zA-Z-]", "g");
        text = asciiRegex.replace(text, "");

        return text;
    }
}
