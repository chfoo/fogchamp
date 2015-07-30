package visualizer;

import haxe.ds.Vector;
import js.Browser;
import js.JQuery;


typedef SelectionItem = {
    name:String, slug:String
}
typedef MovesItem = {
    name:String, moves:Dynamic
}


class UI {
    static var Mustache = untyped __js__("Mustache");
    var jquery:JQuery;
    var pokemonDataset:PokemonDataset;
    var movesDataset:MovesDataset;
    var descriptionsDataset:DescriptionsDataset;
    static var DEFAULT_POKEMON:Vector<Int> = Vector.fromArrayCopy([493, 257, 462, 244, 441, 139]);

    public function new(pokemonDataset:PokemonDataset, movesDataset:MovesDataset, descriptionsDataset:DescriptionsDataset) {
        this.pokemonDataset = pokemonDataset;
        this.movesDataset = movesDataset;
        this.descriptionsDataset = descriptionsDataset;
    }

    static function renderTemplate(template:String, data:Dynamic):String {
        return Mustache.render(template, data);
    }

    public function setup() {
        renderSelectionList();
        attachSelectChangeListeners();
        attachUrlFragmentChangeListener();
        setSelectionByNumbers(DEFAULT_POKEMON);
        readUrlFragment();
        renderAll();
    }

    function renderSelectionList() {
        var template = new JQuery("#pokemonSelectionTemplate").html();

        var rendered = renderTemplate(template, {
            selections: buildSelectionList(),
            slots: [0, 1, 2]
        });

        new JQuery("#pokemonSelectionBlue").html(rendered);

        var rendered = renderTemplate(template, {
            selections: buildSelectionList(),
            slots: [3, 4, 5]
        });

        new JQuery("#pokemonSelectionRed").html(rendered);
    }

    function buildSelectionList():Array<SelectionItem> {
        var list = new Array<SelectionItem>();

        for (slug in pokemonDataset.slugs) {
            list.push({
                slug: slug,
                name: pokemonDataset.getPokemonStats(slug).name
            });
        }

        list.sort(function (x:SelectionItem, y:SelectionItem):Int {
            return Reflect.compare(x.name.toLowerCase(), y.name.toLowerCase());
        });

        return list;
    }

    function attachSelectChangeListeners() {
        for (i in 0...6) {
            new JQuery('#selectionSelect$i').change(function (event:JqEvent) {
                selectChanged(i);
            });
        }
    }

    function attachUrlFragmentChangeListener() {
        Browser.window.onhashchange = readUrlFragment;
    }

    function readUrlFragment() {
        var fragment = Browser.location.hash;
        var pattern = new EReg("([0-9]+)[^0-9]+([0-9]+)[^0-9]+([0-9]+)[^0-9]+([0-9]+)[^0-9]+([0-9]+)[^0-9]+([0-9]+)", "");

        if (pattern.match(fragment)) {
            var pokemonNums = new Vector<Int>(6);
            for (i in 0...6) {
                pokemonNums.set(i, Std.parseInt(pattern.matched(i + 1)));
            }
            setSelectionByNumbers(pokemonNums);
            renderAll(false);
        }
    }

    function writeUrlFragment() {
        var fragment = "#";

        for (i in 0...6) {
            var slug = getSlotSlug(i);
            var pokemonNum = pokemonDataset.getPokemonStats(slug).number;

            if (i == 5) {
                fragment += '$pokemonNum';
            } else {
                fragment += '$pokemonNum-';
            }
        }

        Browser.location.hash = fragment;
    }

    function setSelectionByNumbers(pokemonNums:Vector<Int>) {
        for (i in 0...6) {
            var slug = pokemonDataset.getSlug(pokemonNums.get(i));
            setSlotSlug(i, slug);
        }
    }

    function selectChanged(slotNum:Int) {
        renderAll();
    }

    function renderAll(?updateUrlFragment:Bool) {
        if (updateUrlFragment == null) {
            updateUrlFragment = true;
        }

        renderPokemonStats();
        renderPokemonMoves();
        renderChart();
        attachHelpListeners();

        if (updateUrlFragment) {
            writeUrlFragment();
        }
    }

    function getSlotSlug(slotNum:Int):String {
        return new JQuery('#selectionSelect$slotNum').val();
    }

    function setSlotSlug(slotNum:Int, slug:String) {
        new JQuery('#selectionSelect$slotNum').val(slug);
    }

    function renderPokemonStats() {
        var template = new JQuery("#pokemonStatsTemplate").html();

        var rendered = renderTemplate(template, {
            pokemonStats: buildStats(true)
        });

        new JQuery("#pokemonStats").html(rendered);
    }

    function buildStats(?visualBlueHorizontalOrder:Bool) {
        var slotNums = [0, 1, 2, 3, 4, 5];

        if (visualBlueHorizontalOrder) {
            slotNums = [2, 1, 0, 3, 4, 5];
        }

        var statsList = new Array<Dynamic>();

        for (slotNum in slotNums) {
            var slug = getSlotSlug(slotNum);
            var pokemonStats = pokemonDataset.getPokemonStats(slug);
            var abilityName = descriptionsDataset.getAbilityName(pokemonStats.ability);
            Reflect.setField(pokemonStats, 'ability_name', abilityName);
            Reflect.setField(pokemonStats, 'slot_number', slotNum);
            statsList.push(pokemonStats);
        }

        return statsList;
    }

    function renderPokemonMoves() {
        var template = new JQuery("#pokemonMovesTemplate").html();

        var rendered = renderTemplate(template, {
            pokemonMoves: buildMoves()
        });

        new JQuery("#pokemonMoves").html(rendered);
    }

    function buildMoves():Array<MovesItem> {
        var movesList = new Array<MovesItem>();

        for (slotNum in [2, 1, 0, 3, 4, 5]) {
            var slug = getSlotSlug(slotNum);
            var name = pokemonDataset.getPokemonStats(slug).name;
            var moveSlugs:Array<String> = pokemonDataset.getPokemonStats(slug).moves;
            var moves = new Array<Dynamic>();

            for (moveSlug in moveSlugs) {
                var moveStats = movesDataset.getMoveStats(moveSlug);
                Reflect.setField(moveStats, "move_slug", moveSlug);
                Reflect.setField(moveStats, "move_name", moveStats.name);
                var damageCategory:String = moveStats.damage_category;
                Reflect.setField(moveStats, "damage_category_short", damageCategory.substr(0, 2));
                moves.push(moveStats);
            }

            movesList.push({
                name: name,
                moves: moves
            });
        }

        return movesList;
    }

    function attachHelpListeners() {
        for (element in new JQuery("[data-help-slug]")) {
            var clickElement = new JQuery("<a href=>");
            clickElement.addClass("clickHelp");
            clickElement.click(function () {
                clickedHelp(element.attr("data-help-slug"));
                return false;
            });

            element.wrapInner(clickElement);
        }
    }

    function clickedHelp(helpSlug:String) {
        var parts = helpSlug.split(":");
        var category = parts[0];
        var slug = parts[1];
        var title = slug;
        var text = "";

        if (category == "ability") {
            var ability = Reflect.field(descriptionsDataset.abilities, slug);
            title = ability.name;
            text = ability.description;
        } else if (category == "move") {
            var move = movesDataset.getMoveStats(slug);
            title = move.name;
            text = move.description;
        }

        if (text == null || text.length == 0) {
            text = "(no help available for this item)";
        }

        var jquery = new JQuery("#helpDialog").text(text);
        untyped jquery.dialog();
        untyped jquery.dialog("option", "title", title);
    }

    function renderChart() {
        var matchupChart = new MatchupChart(pokemonDataset, movesDataset, descriptionsDataset);
        matchupChart.setPokemon(buildStats());
        var tableElement = matchupChart.renderTable();

        new JQuery("#pokemonDiamond").empty().append(tableElement);
    }
}
