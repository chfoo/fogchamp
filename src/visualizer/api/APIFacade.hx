package visualizer.api;

import visualizer.datastruct.MovesetPokemonStats;
import js.Browser;
import visualizer.datastruct.PokemonStats;
import js.jquery.JQuery;
import js.jquery.JqXHR;

using StringTools;

typedef AjaxCallback = Dynamic -> String -> JqXHR -> Void;
typedef FailedAjaxCallback = JqXHR -> String -> Dynamic -> Void;
typedef CurrentMatchCallback = Bool -> String -> Array<MovesetPokemonStats> -> Void;
typedef PokemonSetsCallback = Bool -> String -> Array<MovesetPokemonStats> -> Void;

class APIFacade {
    static var CURRENT_MATCH_API_URL(default, null) = "https://twitchplayspokemon.tv/api/current_match";
//    static var CURRENT_MATCH_API_URL(default, null) = "/test_data/match.json";
    static var POKEMON_SETS_API_URL(default, null) = "https://twitchplayspokemon.tv/api/pokemon_sets?id&limit=1000";
    static var CONSUME_CURSOR_API_URL(default, null) = "https://twitchplayspokemon.tv/api/cursor/";
    var callInProgress = false;
    public var progressCallback:Int->Void;

    public function new() {
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
            progressCallback = null;
            callback(true, null, pokemonResults);
        }

        function errorHandler(xhr:JqXHR, textStatus:String, error:Dynamic) {
            progressCallback = null;
            var jsonResult = untyped xhr.responseJSON;
            if (jsonResult != null && Reflect.hasField(jsonResult, "message")) {
                callback(false, Reflect.field(jsonResult, "message"), null);
            } else {
                callback(false, xhr.statusText, null);
            }
        }

        function cursorErrorHandler(xhr:JqXHR, textStatus:String, error:Dynamic) {
            progressCallback = null;
            if (xhr.status == 410) {
                callbackResults();
            } else {
                errorHandler(xhr, textStatus, error);
            }
        }

        function cursorPaginateSuccessHandler(jsonResult:Dynamic, textStatus:String, xhr:JqXHR) {
            try {
                for (stats in parseMovesetPokemon(jsonResult)) {
                    pokemonResults.push(stats);
                }
            } catch (error:Dynamic) {
                callback(false, null, null);
                return;
            }

            progressCallback(pokemonResults.length);

            Browser.window.setTimeout(function () {
                callAPI(
                    CONSUME_CURSOR_API_URL + token + "?limit=1000",
                    cursorPaginateSuccessHandler,
                    cursorErrorHandler,
                    true
                );
            }, 1);
        }

        function cursorCreateSuccessHandler(jsonResult:Dynamic, textStatus:String, xhr:JqXHR) {
            token = jsonResult;

            Browser.window.setTimeout(function () {
                callAPI(
                    CONSUME_CURSOR_API_URL + token + "?limit=1000",
                    cursorPaginateSuccessHandler,
                    cursorErrorHandler,
                    true
                );
            }, 1);
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
            xhr = JQuery.post(url, "Kappa", null, "json");
        }

        xhr.done(done).fail(error).always(function () {
            callInProgress = false;
        });
    }

    function parseMatchPokemon(jsonDoc:Dynamic):Array<MovesetPokemonStats> {
        var teams:Array<Dynamic> = Reflect.field(jsonDoc, "teams");
        var teamBlue:Array<Dynamic> = teams[0];
        var teamRed:Array<Dynamic> = teams[1];
        var pokemonStats = [];

        for (pokemonDoc in teamBlue) {
            var stats = new MovesetPokemonStats();
            parsePokemonStats(pokemonDoc, stats);
            pokemonStats.push(stats);
        }
        for (pokemonDoc in teamRed) {
            var stats = new MovesetPokemonStats();
            parsePokemonStats(pokemonDoc, stats);
            pokemonStats.push(stats);
        }

        return pokemonStats;
    }

    function parseMovesetPokemon(jsonDoc:Dynamic):Array<MovesetPokemonStats> {
        var movesetInfoDoc:Array<Dynamic> = jsonDoc;
        var statsList = [];

        for (entryInfoDoc in movesetInfoDoc) {
            var statsDoc = Reflect.field(entryInfoDoc, "data");
            var stats = new MovesetPokemonStats();
            parseMovesetPokemonStats(statsDoc, stats);
            statsList.push(stats);
        }

        return statsList;
    }

    function parseCommonPokemonStats(jsonDoc:Dynamic, stats:PokemonStats) {
        var speciesId:Int = Reflect.field(Reflect.field(jsonDoc, "species"), "id");
        var effectiveStats = Reflect.field(jsonDoc, "stats");

        stats.name = Reflect.field(Reflect.field(jsonDoc, "species"), "name");
        stats.nickname = Reflect.field(jsonDoc, "ingamename");
        stats.attack = Reflect.field(effectiveStats, "atk");
        stats.defense = Reflect.field(effectiveStats, "def");
        stats.gender = Reflect.field(jsonDoc, "gender");
        stats.happiness = Reflect.field(jsonDoc, "happiness");
        stats.hp = Reflect.field(effectiveStats, "hp");

        // TODO: load iv
        // stats.iv

        if (Reflect.hasField(jsonDoc, "nature") && Reflect.field(jsonDoc, "nature") != null) {
            stats.nature = slugify(Reflect.field(Reflect.field(jsonDoc, "nature"), "name"));
        }

        stats.number = speciesId;
        stats.specialAttack = Reflect.field(effectiveStats, "spA");
        stats.specialDefense = Reflect.field(effectiveStats, "spD");
        stats.speed = Reflect.field(effectiveStats, "spe");
    }

    function parsePokemonStats(jsonDoc:Dynamic, stats:PokemonStats) {
        parseCommonPokemonStats(jsonDoc, stats);

        if (Reflect.hasField(jsonDoc, "ability") && Reflect.field(jsonDoc, "ability") != null) {
            var rawName = Reflect.field(Reflect.field(jsonDoc, "ability"), "name");
            if (rawName != null) {
                stats.ability = slugify(rawName);
            }
        }

        if (Reflect.hasField(jsonDoc, "item") && Reflect.field(jsonDoc, "item") != null) {
            var rawName = Reflect.field(Reflect.field(jsonDoc, "item"), "name");
            if (rawName != null) {
                stats.item = slugify(rawName);
            }
        }

        stats.moves = [];

        var moveDocList:Array<Dynamic> = Reflect.field(jsonDoc, "moves");
        for (moveDoc in moveDocList) {
            var moveSlug = slugify(Reflect.field(moveDoc, "name"));
            stats.moves.push(moveSlug);

            if (moveSlug == "hidden-power") {
                stats.moveTypeOverride = slugify(Reflect.field(moveDoc, "type"));
            }
        }
    }

    function parseMovesetPokemonStats(jsonDoc:Dynamic, stats:MovesetPokemonStats) {
        parseCommonPokemonStats(jsonDoc, stats);
        var abilitiesDoc:Array<Dynamic> = Reflect.field(jsonDoc, "ability");
        var itemsDoc:Array<Dynamic> = Reflect.field(jsonDoc, "item");
        var movesDoc:Array<Array<Dynamic>> = Reflect.field(jsonDoc, "moves");
        var genders:Array<String> = Reflect.field(jsonDoc, "gender");

        stats.movesetName = Reflect.field(jsonDoc, "setname");

        stats.gender = null;
        stats.genderSet = new Array<String>();
        for (gender in genders) {
            if (gender != null) {
                stats.genderSet.push(gender);
            }
        }

        for (doc in abilitiesDoc) {
            var rawName = Reflect.field(doc, "name");
            if (rawName != null) {
                stats.abilitySet.push(slugify(rawName));
            }
        }

        for (doc in itemsDoc) {
            var rawName = Reflect.field(doc, "name");
            if (rawName != null) {
                stats.itemSet.push(slugify(rawName));
            }
        }

        for (slotDoc in movesDoc) {
            var slotMoves = [];

            for (moveDoc in slotDoc) {
                var moveSlug = slugify(Reflect.field(moveDoc, "name"));
                slotMoves.push(moveSlug);

                if (moveSlug == "hidden-power") {
                    stats.moveTypeOverride = slugify(Reflect.field(moveDoc, "type"));
                }
            }

            stats.moveSets.push(slotMoves);
        }
    }

    static public function slugify(text:String, ?noDash:Bool):String {
        text = text.toLowerCase()
            .replace("♀", "f")
            .replace("♂", "m")
            .replace(" ", "-")
            .replace("é", "e");

        if (noDash) {
            text = text.replace('-', '');
        }

        var asciiRegex = new EReg("[^a-zA-Z0-9-]", "g");
        text = asciiRegex.replace(text, "");

        return text;
    }
}
