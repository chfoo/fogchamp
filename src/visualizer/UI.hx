package visualizer;

import visualizer.datastruct.VisualizerPokemonStats;
import visualizer.datastruct.VisualizerPokemonStats;
import visualizer.dataset.Dataset.LoadEvent;
import visualizer.datastruct.MovesetPokemonStats;
import js.jquery.Event;
import visualizer.model.PokemonDatabase;
import visualizer.datastruct.PokemonStats;
import visualizer.Formula.FormulaOptions;
import js.html.DivElement;
import js.html.OptionElement;
import js.html.SelectElement;
import haxe.ds.Vector;
import js.Browser;
import js.jquery.JQuery;

using StringTools;


typedef SelectionItem = {
    name:String, slug:String
}
typedef MovesItem = {
    name:String, moves:Dynamic
}


class UI {
    static var Mustache = untyped __js__("Mustache");
    var database:PokemonDatabase;
    var userMessage:UserMessage;
    static var DEFAULT_POKEMON:Vector<Int> = Vector.fromArrayCopy([493, 257, 462, 244, 441, 139]);
    var currentPokemon:Vector<VisualizerPokemonStats>;
    var currentUrlHash:String;
    var formulaOptions:FormulaOptions;

    public function new(pokemonDatabase:PokemonDatabase) {
        database = pokemonDatabase;
        userMessage = new UserMessage();
        currentPokemon = new Vector(6);
        formulaOptions = new FormulaOptions();
    }

    static function renderTemplate(template:String, data:Dynamic):String {
        return Mustache.render(template, data);
    }

    public function setup() {
        renderSelectionList();
        attachSelectChangeListeners();
        renderEditionSelect();
        attachEditionSelectListener();
        attachUrlFragmentChangeListener();
        attachFetchFromAPIButtonListener();
        attachMovesetDownloadButtonLisenter();
        readUrlFragment();
        if (currentPokemon.get(0) == null) {
            setSelectionByNumbers(DEFAULT_POKEMON);
        }
        var editions = database.getEditionNames();
        selectEdition(editions[editions.length - 2]);
        attachOptionsListeners();
        renderAll();
        promptToDownloadMovesets();
    }

    function renderSelectionList() {
        var template = new JQuery("#pokemonSelectionTemplate").html();
        var selections = buildSelectionList();

        var rendered = renderTemplate(template, {
            selections: selections,
            slots: [0, 1, 2]
        });

        new JQuery("#pokemonSelectionBlue").html(rendered);

        var rendered = renderTemplate(template, {
            selections: selections,
            slots: [3, 4, 5]
        });

        new JQuery("#pokemonSelectionRed").html(rendered);
    }

    function buildSelectionList():Array<SelectionItem> {
        var list = new Array<SelectionItem>();

        for (slug in database.getPokemonSlugs()) {
            var stats = database.getPokemonStats(slug);
            var name = stats.name;
            if (stats.nickname != null && name.toLowerCase() != stats.nickname.toLowerCase()) {
                name += ' (${stats.nickname})';
            }

            if (stats.movesetName != null) {
                name += ' - ${stats.movesetName}';
            }

            list.push({
                slug: slug,
                name: name
            });
        }

        list.sort(function (x:SelectionItem, y:SelectionItem):Int {
            return Reflect.compare(x.name.toLowerCase(), y.name.toLowerCase());
        });

        return list;
    }

    function attachSelectChangeListeners() {
        for (i in 0...6) {
            var jquery = new JQuery('#selectionSelect$i');

            jquery.change(function (event:Event) {
                selectChanged(i, jquery.val());
            });

            jquery.focus(function (event:Event) {
                new JQuery('.pokemonIconSlot-$i').addClass("pokemonIcon-focus");
            });
            jquery.focusout(function (event:Event) {
                new JQuery('.pokemonIconSlot-$i').removeClass("pokemonIcon-focus");
            });
        }
    }

    function renderEditionSelect() {
        var selectElement = cast(Browser.document.getElementById("pokemonEditionSelect"), SelectElement);
        var names = database.getEditionNames();

        for (name in names) {
            var optionElement:OptionElement = Browser.document.createOptionElement();

            optionElement.value = name;
            optionElement.textContent = name;

            selectElement.add(optionElement);
        }
    }

    function attachEditionSelectListener() {
        var selectElement = cast(Browser.document.getElementById("pokemonEditionSelect"), SelectElement);

        new JQuery("#pokemonEditionSelect").change(function (event:Event) {
            selectEdition(new JQuery(selectElement).val());
        });
    }

    function selectEdition(name:String) {
        if (name == PokemonDatabase.API_EDITION) {
            new JQuery("#downloadMovesetsButton").prop("disabled", false);
        } else {
            new JQuery("#downloadMovesetsButton").prop("disabled", "disabled");
        }

        database.setEdition(name);
        var selectElement = cast(Browser.document.getElementById("pokemonEditionSelect"), SelectElement);
        selectElement.selectedIndex = database.getEditionNames().indexOf(name);
        reloadSelectionList();
        updateCurrentToNearestStatsByEdition();
        renderAll();
    }

    function attachUrlFragmentChangeListener() {
        Browser.window.onhashchange = readUrlFragment;
    }

    function readUrlFragment() {
        var fragment = Browser.location.hash;

        if (fragment == currentUrlHash) {
            return;
        }

        var pattern = new EReg("([0-9]+)[^0-9]+([0-9]+)[^0-9]+([0-9]+)[^0-9]+([0-9]+)[^0-9]+([0-9]+)[^0-9]+([0-9]+)", "");

        if (pattern.match(fragment)) {
            var pokemonNums = new Vector<Int>(6);
            for (i in 0...6) {
                pokemonNums.set(i, Std.parseInt(pattern.matched(i + 1)));
            }
            setSelectionByNumbers(pokemonNums);
            renderAll(false);
        } else {
            userMessage.showMessage("The URL fragment (stuff after the hash symbol) isn't valid.");
        }
    }

    function writeUrlFragment() {
        var fragment = "#";

        for (i in 0...6) {
            var pokemonNum = currentPokemon[i].number;

            if (i == 5) {
                fragment += '$pokemonNum';
            } else {
                fragment += '$pokemonNum-';
            }
        }

        // Setting the hash will trigger hashchange event.
        // Disabling the hander while setting the hash does not work since
        // it is asynchronous. As a result, we need to keep state and ignore
        // the event if we see that we set the hash ourselves.
        currentUrlHash = fragment;
        Browser.location.hash = fragment;
    }

    function attachFetchFromAPIButtonListener() {
        new JQuery("#fetchMatchFromAPIButton").click(function (event:Event) {
            fetchFromAPI();
        });
    }

    function attachMovesetDownloadButtonLisenter() {
        new JQuery("#downloadMovesetsButton").click(function (event:Event) {
            new JQuery("#downloadMovesetsButton").prop("disabled", "disabled");
            fetchMovesetsFromAPI();
        });
    }

    function fetchFromAPI() {
        userMessage.showMessage("Fetching current match from TPP API...");

        database.currentMatchDataset.load(function (loadEvent:LoadEvent) {
            new JQuery("#fetchMatchFromAPIButton").prop("disabled", false);
            if (loadEvent.success) {
                setSelectionByAPI(database.getCurrentMatchPokemonStats());
            } else {
                if (loadEvent.errorMessage != null) {
                    userMessage.showMessage('An error occurred fetching current match: "${loadEvent.errorMessage}". Complain to Felk if error persists.');
                } else {
                    userMessage.showMessage("An error occured while attempting to parse the data. File a bug report if this persists.");
                }
            }
        });
    }

    function promptToDownloadMovesets() {
        if (database.apiPokemonDataset.slugs.length == 0) {
            untyped new JQuery("#promptDialog").html("
            <p>
            <big><strong>Download the latest movesets from TPP?</strong></big>
            </p>
            <p>Downloading will take a while but this only has to be done once.</p>
            ")
            .dialog({
                modal: true,
                buttons: {
                    "Skip": function () {
                        new JQuery("#promptDialog").dialog("close");
                    },
                    "Download": function() {
                        new JQuery("#downloadMovesetsButton").prop("disabled", "disabled");
                        fetchMovesetsFromAPI();
                        new JQuery("#promptDialog").dialog("close");
                    }
                },
                open: function () {
                    new JQuery(".ui-dialog-buttonset button:nth-child(2)").focus();
                }
            });
        }
    }

    function fetchMovesetsFromAPI() {
        userMessage.showMessage("Loading Movesets from TPP. This may take a while...");

        function showProgressCallback(value:Int) {
            userMessage.showMessage('Loading Movesets from TPP. Progress: $value movesets loaded');
        }

        database.apiPokemonDataset.clearStorage();
        database.apiPokemonDataset.apiFacade.progressCallback = showProgressCallback;
        database.apiPokemonDataset.load(
            function (event:LoadEvent) {
                if (event.success) {
                    userMessage.hide();
                    database.apiPokemonDataset.saveToStorage();
                } else {
                    userMessage.showMessage('Failed to load movesets from TPP: ${event.errorMessage}');
                }
            }
        );
    }

    function setSelectionByNumbers(pokemonNums:Vector<Int>) {
        for (i in 0...6) {
            var slug = database.getPokemonSlugByID(pokemonNums.get(i));
            currentPokemon.set(i, database.getPokemonStats(slug));
        }
        syncSelectionListToCurrent();
    }

    function updateCurrentToNearestStatsByEdition() {
        for (i in 0...6) {
            var pokemonStats;

            try {
                pokemonStats = database.getPokemonStats(currentPokemon.get(i).slug);
            } catch (error:StatsNotFoundError) {
                try {
                    var slug = database.getPokemonSlugByID(currentPokemon.get(i).number);
                    pokemonStats = database.getPokemonStats(slug);
                } catch (error:StatsNotFoundError) {
                    userMessage.showMessage("The dataset for this edition is corrupt, unrecognized, or not yet loaded.");
                    throw "Missing dataset";
                }
            }
            currentPokemon.set(i, pokemonStats);
        }
        syncSelectionListToCurrent();
    }

    function setSelectionByAPI(pokemonStatsList:Array<MovesetPokemonStats>) {
        var selectElement = cast(Browser.document.getElementById("pokemonEditionSelect"), SelectElement);

        for (slotNum in 0...6) {
            var pokemonStats = new VisualizerPokemonStats();
            pokemonStats.update(pokemonStatsList[slotNum]);
            currentPokemon.set(slotNum, pokemonStats);

        }
        reloadSelectionList();
        syncSelectionListToCurrent();
        renderAll();
    }

    function selectChanged(slotNum:Int, slug:String) {
        currentPokemon.set(slotNum, database.getPokemonStats(slug));

        renderAll();
    }

    function reloadSelectionList() {
        renderSelectionList();
        attachSelectChangeListeners();
    }

    function syncSelectionListToCurrent() {
        for (i in 0...6) {
            var stats = currentPokemon.get(i);
            // Disable to prevent onchange firing while setting
            new JQuery('#selectionSelect$i')
                .prop("disabled", "disabled")
                .val(stats.slug)
                .prop("disabled", false);
        }
    }

    function renderAll(?updateUrlFragment:Bool) {
        if (updateUrlFragment == null) {
            updateUrlFragment = true;
        }

        try {
            renderMatchCommand();
            renderChart();
            attachHelpListeners();

            new JQuery(".pokemonEditContainer").show();
            attachEditListeners();

            if (updateUrlFragment) {
                writeUrlFragment();
            }

            renderExtraUrls();

            userMessage.hide();
        } catch (error:Dynamic) {
            userMessage.showMessage("An error occured while attempting to render the data. File a bug report if this persists.");

            throw error;
        }
    }

    function renderMatchCommand() {
        var numbers = getMatchNumbers();

        var element:DivElement = cast(Browser.document.getElementById("matchCommand"), DivElement);
        element.textContent = '!match ${numbers[0]},${numbers[1]},${numbers[2]}/${numbers[3]},${numbers[4]},${numbers[5]}';
    }

    function getMatchNumbers():Array<Int> {
        var numbers = [];

        for (i in 0...6) {
            var pokemonNum = currentPokemon.get(i).number;
            numbers.push(pokemonNum);
        }

        return numbers;
    }

    function attachHelpListeners() {
        for (element in new JQuery("[data-help-slug]").elements()) {
            var clickElement = new JQuery("<a href=>");
            clickElement.addClass("clickHelp");
            clickElement.click(function (event:Event) {
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
            var ability = database.descriptionsDataset.getAbility(slug);
            title = ability.name;
            text = ability.description;
        } else if (category == "item") {
            var item = database.descriptionsDataset.getItem(slug);
            title = item.name;
            text = item.description;
        } else if (category == "move") {
            var move = database.movesDataset.getMoveStats(slug);
            title = move.name;
            text = move.description;
        } else if (category == "damage") {
            text = 'HP damage against foe (min, max, crit):
                ${parts[2]}–${parts[3]}–${parts[4]}%
                ${parts[5]}–${parts[6]}–${parts[7]}pts';
        }

        if (text == null || text.length == 0) {
            text = "(no help available for this item)";
        }

        text = text.replace("✻", "\n✻");

        var jquery = new JQuery("#helpDialog").text(text);
        untyped jquery.dialog();

        var inViewport:Bool = untyped jquery.visible();

        if (!inViewport) {
            untyped jquery.dialog({position: {my: "center top", at: "center top", of: Browser.window}});
        }

        untyped jquery.dialog("option", "title", title);
    }

    function attachEditListeners() {
        for (element in new JQuery("[data-edit-slot]").elements()) {
            var clickElement = new JQuery("<a href=>");
            clickElement.addClass("clickEdit");
            clickElement.click(function (event:Event) {
                clickedEdit(Std.parseInt(element.attr("data-edit-slot")));
                return false;
            });

            element.wrapInner(clickElement);
        }
    }

    function clickedEdit(slotNum:Int) {
        var pokemonStats = currentPokemon.get(slotNum);

        var template = new JQuery("#pokemonEditTemplate").html();
        var html = renderTemplate(
            template, {
                "gender": buildEditGenderRenderDoc(pokemonStats),
                "ability": buildEditAbilityRenderDoc(pokemonStats),
                "item": buildEditItemRenderDoc(pokemonStats),
                "hp": pokemonStats.hp,
                "attack": pokemonStats.attack,
                "defense": pokemonStats.defense,
                "special_attack": pokemonStats.specialAttack,
                "special_defense": pokemonStats.specialDefense,
                "speed": pokemonStats.speed,
                "move1": buildEditMoveRenderDoc(pokemonStats, 0),
                "move2": buildEditMoveRenderDoc(pokemonStats, 1),
                "move3": buildEditMoveRenderDoc(pokemonStats, 2),
                "move4": buildEditMoveRenderDoc(pokemonStats, 3)
            }
        );

        var jquery = new JQuery("#editDialog").html(html);
        untyped jquery.dialog({"maxHeight": 500});

        var inViewport:Bool = untyped jquery.visible();

        if (!inViewport) {
            untyped jquery.dialog({position: {my: "center top", at: "center top", of: Browser.window}});
        }

        attachEditFormListeners(slotNum);

        untyped jquery.dialog("option", "title", 'Editing ${pokemonStats.name}');
    }

    function buildEditGenderRenderDoc(pokemonStats:PokemonStats):Dynamic {
        var genderRenderList = [];

        for (genderSlug in ["-", "m", "f"]) {
            genderRenderList.push({
                "slug": genderSlug,
                "label": genderSlug,
                "selected": (genderSlug == pokemonStats.gender)? "selected": ""
            });
        }

        return genderRenderList;
    }

    function buildEditAbilityRenderDoc(pokemonStats:VisualizerPokemonStats):Dynamic {
        var abilityRenderList = [{"slug": "", "label": "-", "selected": ""}];
        var setList;

        if (pokemonStats.abilitySet != null) {
            setList = pokemonStats.abilitySet.iterator();
        } else {
            setList = database.descriptionsDataset.abilities.keys();
        }

        for (abilitySlug in setList) {
            abilityRenderList.push({
                "slug": abilitySlug,
                "label": database.descriptionsDataset.getAbilityName(abilitySlug),
                "selected": (abilitySlug == pokemonStats.ability)? "selected": ""
            });
        }

        return abilityRenderList;
    }

    function buildEditItemRenderDoc(pokemonStats:VisualizerPokemonStats):Dynamic {
        var itemRenderList = [{"slug": "", "label": "-", "selected": ""}];
        var setList;

        if (pokemonStats.itemSet != null) {
            setList = pokemonStats.itemSet.iterator();
        } else {
            setList = database.descriptionsDataset.items.keys();
        }

        for (itemSlug in setList) {
            itemRenderList.push({
                "slug": itemSlug,
                "label": database.descriptionsDataset.getItemName(itemSlug),
                "selected": (itemSlug == pokemonStats.item)? "selected": ""
            });
        }

        return itemRenderList;
    }

    function buildEditMoveRenderDoc(pokemonStats:VisualizerPokemonStats, slot:Int):Dynamic {
        var moveRenderList = [{"slug": "", "label": "-", "selected": ""}];

        var setList;

        if (pokemonStats.itemSet != null && slot <= pokemonStats.moveSets.length - 1) {
            setList = pokemonStats.moveSets[slot].iterator();
        } else {
            setList = database.movesDataset.moves.keys();
        }

        for (moveSlug in setList) {
            moveRenderList.push({
                "slug": moveSlug,
                "label": database.movesDataset.getMoveStats(moveSlug).name,
                "selected": (moveSlug == pokemonStats.moves[slot])? "selected": ""
            });
        }

        return moveRenderList;
    }

    function attachEditFormListeners(slotNum:Int) {
        var genderInput = new JQuery("#pokemonEditGender");
        var abilityInput = new JQuery("#pokemonEditAbility");
        var itemInput = new JQuery("#pokemonEditItem");
        var hpInput = new JQuery("#pokemonEditHP");
        var attackInput = new JQuery("#pokemonEditAttack");
        var defenseInput = new JQuery("#pokemonEditDefense");
        var specialAttackInput = new JQuery("#pokemonEditSpecialAttack");
        var specialDefenseInput = new JQuery("#pokemonEditSpecialDefense");
        var speedInput = new JQuery("#pokemonEditSpeed");
        var move1Input = new JQuery("#pokemonEditMove1");
        var move2Input = new JQuery("#pokemonEditMove2");
        var move3Input = new JQuery("#pokemonEditMove3");
        var move4Input = new JQuery("#pokemonEditMove4");

        function readValues(event:Event) {
            var pokemonStats = currentPokemon.get(slotNum);
            pokemonStats.gender = genderInput.find("option:selected").attr("name");
            pokemonStats.ability = abilityInput.find("option:selected").attr("name");
            pokemonStats.item = itemInput.find("option:selected").attr("name");
            pokemonStats.hp = Std.parseInt(hpInput.val());
            pokemonStats.attack = Std.parseInt(attackInput.val());
            pokemonStats.defense = Std.parseInt(defenseInput.val());
            pokemonStats.specialAttack = Std.parseInt(specialAttackInput.val());
            pokemonStats.specialDefense = Std.parseInt(specialDefenseInput.val());
            pokemonStats.speed = Std.parseInt(speedInput.val());

            var moves = [
                move1Input.find("option:selected").attr("name"),
                move2Input.find("option:selected").attr("name"),
                move3Input.find("option:selected").attr("name"),
                move4Input.find("option:selected").attr("name")
            ];
            moves = moves.filter(function (item:String) { return item != "";});
            pokemonStats.moves = moves;

            applyCustomPokemon(pokemonStats, slotNum);
        }

        genderInput.change(readValues);
        abilityInput.change(readValues);
        itemInput.change(readValues);
        hpInput.change(readValues);
        attackInput.change(readValues);
        defenseInput.change(readValues);
        specialAttackInput.change(readValues);
        specialDefenseInput.change(readValues);
        speedInput.change(readValues);
        move1Input.change(readValues);
        move2Input.change(readValues);
        move3Input.change(readValues);
        move4Input.change(readValues);
    }

    function applyCustomPokemon(pokemonStats:VisualizerPokemonStats, slotNum:Int) {
        var newCustomization = !database.isCustomized(pokemonStats.slug);

        if (newCustomization) {
            pokemonStats = pokemonStats.copy();
            pokemonStats.slug = '${pokemonStats.slug}-custom$slotNum';
            pokemonStats.movesetName = 'Custom $slotNum';
        }

        currentPokemon.set(slotNum, pokemonStats);
        database.setCustomPokemonStats(pokemonStats.slug, pokemonStats);

        if (newCustomization) {
            reloadSelectionList();
            syncSelectionListToCurrent();
        }

        renderAll(false);
    }

    function renderChart() {
        var matchupChart = new MatchupChart(database, formulaOptions);
        matchupChart.setPokemon(currentPokemon.toArray());
        var tableElement = matchupChart.renderTable();

        new JQuery("#pokemonDiamond").empty().append(tableElement);
    }

    function attachOptionsListeners() {
        new JQuery("#formulaOptions-typeImmunities").change(function (event:Event) {
            var checked:Bool = new JQuery("#formulaOptions-typeImmunities").prop("checked");
            formulaOptions.typeImmunities = checked;
            renderAll(false);
        });
    }

    function renderExtraUrls() {
        var numbers = getMatchNumbers();

        new JQuery("#extraUrls").html('
            View
            <a href="http://www.tppvisuals.com/pbr/visualizer.htm#${numbers[0]}-${numbers[1]}-${numbers[2]}-${numbers[3]}-${numbers[4]}-${numbers[5]}">
            Dhason</a> /
            <a href="http://fe1k.de/tpp/visualize#${numbers[0]}-${numbers[1]}-${numbers[2]}-${numbers[3]}-${numbers[4]}-${numbers[5]}">
            FelkCraft</a>
            visualizer
        ');
    }
}
