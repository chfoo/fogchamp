package visualizer;

import visualizer.PokemonDataset.DatasetDoc;
import visualizer.Formula.FormulaOptions;
import js.html.DivElement;
import js.html.OptionElement;
import js.html.SelectElement;
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
    var userMessage:UserMessage;
    static var DEFAULT_POKEMON:Vector<Int> = Vector.fromArrayCopy([493, 257, 462, 244, 441, 139]);
    var previousUrlHash:String = null;
    var formulaOptions:FormulaOptions;

    public function new(pokemonDataset:PokemonDataset, movesDataset:MovesDataset, descriptionsDataset:DescriptionsDataset) {
        this.pokemonDataset = pokemonDataset;
        this.movesDataset = movesDataset;
        this.descriptionsDataset = descriptionsDataset;
        userMessage = new UserMessage();
        formulaOptions = new FormulaOptions();
    }

    static function renderTemplate(template:String, data:Dynamic):String {
        return Mustache.render(template, data);
    }

    public function setup() {
        renderSelectionList();
        attachSelectChangeListeners();
        renderEditionSelect();
        attachUrlFragmentChangeListener();
        setSelectionByNumbers(DEFAULT_POKEMON);
        attachOptionsListeners();
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
            var jquery = new JQuery('#selectionSelect$i');

            jquery.change(function (event:JqEvent) {
                selectChanged(i);
            });

            jquery.focus(function (event:JqEvent) {
                new JQuery('.pokemonIconSlot-$i').addClass("pokemonIcon-focus");
            });
            jquery.focusout(function (event:JqEvent) {
                new JQuery('.pokemonIconSlot-$i').removeClass("pokemonIcon-focus");
            });
        }
    }

    function renderEditionSelect() {
        var selectElement = cast(Browser.document.getElementById("pokemonEditionSelect"), SelectElement);

        for (index in 0...PokemonDataset.DATASET_NAMES.length) {
            var optionElement:OptionElement = Browser.document.createOptionElement();

            optionElement.value = PokemonDataset.DATASET_FILES[index];
            optionElement.textContent = PokemonDataset.DATASET_NAMES[index];

            selectElement.add(optionElement);
        }

        if (PokemonDataset.DEFAULT_INDEX >= 0) {
            selectElement.selectedIndex = PokemonDataset.DEFAULT_INDEX;
        } else {
            selectElement.selectedIndex = PokemonDataset.DATASET_FILES.length - 1;
        }

        new JQuery("#pokemonEditionSelect").change(function (event:JqEvent) {
            pokemonDataset.datasetIndex = selectElement.selectedIndex;
            renderAll(false);
        });
    }

    function attachUrlFragmentChangeListener() {
        Browser.window.onhashchange = readUrlFragment;
    }

    function readUrlFragment() {
        var fragment = Browser.location.hash;

        if (fragment == previousUrlHash) {
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
            var slug = getSlotSlug(i);
            var pokemonNum = pokemonDataset.getPokemonStats(slug).number;

            if (i == 5) {
                fragment += '$pokemonNum';
            } else {
                fragment += '$pokemonNum-';
            }
        }

        previousUrlHash = '#$fragment';
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

        try {
            renderMatchCommand();
            renderPokemonStats();
            renderPokemonMoves();
            renderChart();
            attachHelpListeners();

            if (pokemonDataset.datasetIndex == PokemonDataset.CUSTOMIZABLE_INDEX) {
                new JQuery(".pokemonEditContainer").show();
                attachEditListeners();
            } else {
                new JQuery(".pokemonEditContainer").hide();
            }

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

    function getSlotSlug(slotNum:Int):String {
        return new JQuery('#selectionSelect$slotNum').val();
    }

    function setSlotSlug(slotNum:Int, slug:String) {
        new JQuery('#selectionSelect$slotNum').val(slug);
    }

    function renderMatchCommand() {
        var numbers = getMatchNumbers();

        var element:DivElement = cast(Browser.document.getElementById("matchCommand"), DivElement);
        element.textContent = '!match ${numbers[0]},${numbers[1]},${numbers[2]}/${numbers[3]},${numbers[4]},${numbers[5]}';
    }

    function getMatchNumbers():Array<Int> {
        var numbers = [];

        for (i in 0...6) {
            var slug = getSlotSlug(i);
            var pokemonNum = pokemonDataset.getPokemonStats(slug).number;
            numbers.push(pokemonNum);
        }

        return numbers;
    }

    function renderPokemonStats() {
        var template = new JQuery("#pokemonStatsTemplate").html();

        var rendered = renderTemplate(template, {
            pokemonStats: buildPokemonStatsRenderDocs(true)
        });

        new JQuery("#pokemonStats").html(rendered);
    }

    function getPokemonStatsSelected():Array<PokemonStats> {
        var slotNums = [0, 1, 2, 3, 4, 5];
        var statsList = new Array<PokemonStats>();

        for (slotNum in slotNums) {
            var slug = getSlotSlug(slotNum);
            var pokemonStats = pokemonDataset.getPokemonStats(slug);

            statsList.push(pokemonStats);
        }

        return statsList;
    }

    function buildPokemonStatsRenderDocs(?visualBlueHorizontalOrder:Bool):Array<Dynamic> {
        var slotNums = [0, 1, 2, 3, 4, 5];

        if (visualBlueHorizontalOrder) {
            slotNums = [2, 1, 0, 3, 4, 5];
        }

        var statsList = new Array<Dynamic>();

        for (slotNum in slotNums) {
            var slug = getSlotSlug(slotNum);
            var pokemonStats = pokemonDataset.getPokemonStats(slug);
            var abilityName = "";

            if (descriptionsDataset.abilities.exists(pokemonStats.ability)) {
                abilityName = descriptionsDataset.getAbilityName(pokemonStats.ability);
            }

            var itemName = "";

            if (descriptionsDataset.items.exists(pokemonStats.item)) {
                itemName = descriptionsDataset.getItemName(pokemonStats.item);
            }

            var renderDoc = pokemonStats.toJson();
            Reflect.setField(renderDoc, 'ability_name', abilityName);
            Reflect.setField(renderDoc, 'item_name', itemName);
            Reflect.setField(renderDoc, 'slot_number', slotNum);
            statsList.push(renderDoc);
        }

        return statsList;
    }

    function renderPokemonMoves() {
        var template = new JQuery("#pokemonMovesTemplate").html();

        var rendered = renderTemplate(template, {
            pokemonMoves: buildMovesRenderDocs()
        });

        new JQuery("#pokemonMoves").html(rendered);
    }

    function buildMovesRenderDocs():Array<MovesItem> {
        var movesList = new Array<MovesItem>();

        for (slotNum in [2, 1, 0, 3, 4, 5]) {
            var slug = getSlotSlug(slotNum);
            var pokemonStat = pokemonDataset.getPokemonStats(slug);
            var name = pokemonStat.name;
            var moveSlugs:Array<String> = pokemonStat.moves;
            var moves = new Array<Dynamic>();

            for (moveSlug in moveSlugs) {
                var moveStats = movesDataset.getMoveStats(moveSlug, pokemonStat);
                var moveRenderDoc = moveStats.toJson();
                Reflect.setField(moveRenderDoc, "move_slug", moveSlug);
                Reflect.setField(moveRenderDoc, "move_name", moveStats.name);
                var damageCategory:String = moveStats.damageCategory;
                Reflect.setField(moveRenderDoc, "damage_category_short", damageCategory.substr(0, 2));

                if (moveStats.power == null) {
                    Reflect.setField(moveRenderDoc, "power", "--");
                }

                if (moveStats.accuracy == null) {
                    Reflect.setField(moveRenderDoc, "accuracy", "--");
                }

                moves.push(moveRenderDoc);
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
            var ability = descriptionsDataset.abilities.get(slug);
            title = ability.name;
            text = ability.description;
        } else if (category == "item") {
            var item = descriptionsDataset.items.get(slug);
            title = item.name;
            text = item.description;
        } else if (category == "move") {
            var move = movesDataset.getMoveStats(slug);
            title = move.name;
            text = move.description;
        } else if (category == "damage") {
            text = 'HP damage against foe (min, max, crit):${parts[2]}–${parts[3]}–${parts[4]}%';
        }

        if (text == null || text.length == 0) {
            text = "(no help available for this item)";
        }

        var jquery = new JQuery("#helpDialog").text(text);
        untyped jquery.dialog();

        var inViewport:Bool = untyped jquery.visible();

        if (!inViewport) {
            untyped jquery.dialog({position: {my: "center top", at: "center top", of: Browser.window}});
        }

        untyped jquery.dialog("option", "title", title);
    }

    function attachEditListeners() {
        for (element in new JQuery("[data-edit-slot]")) {
            var clickElement = new JQuery("<a href=>");
            clickElement.addClass("clickEdit");
            clickElement.click(function () {
                clickedEdit(Std.parseInt(element.attr("data-edit-slot")));
                return false;
            });

            element.wrapInner(clickElement);
        }
    }

    function clickedEdit(slotNum:Int) {
        var slug = getSlotSlug(slotNum);
        var pokemonStats = pokemonDataset.getPokemonStats(slug);

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

        attachEditFormListeners(pokemonStats);

        untyped jquery.dialog("option", "title", 'Editing $slug');
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

    function buildEditAbilityRenderDoc(pokemonStats:PokemonStats):Dynamic {
        var abilityRenderList = [{"slug": "", "label": "-", "selected": ""}];

        for (abilitySlug in descriptionsDataset.abilities.keys()) {
            abilityRenderList.push({
                "slug": abilitySlug,
                "label": descriptionsDataset.abilities.get(abilitySlug).name,
                "selected": (abilitySlug == pokemonStats.ability)? "selected": ""
            });
        }

        return abilityRenderList;
    }

    function buildEditItemRenderDoc(pokemonStats:PokemonStats):Dynamic {
        var itemRenderList = [{"slug": "", "label": "-", "selected": ""}];

        for (itemSlug in descriptionsDataset.items.keys()) {
            itemRenderList.push({
                "slug": itemSlug,
                "label": descriptionsDataset.items.get(itemSlug).name,
                "selected": (itemSlug == pokemonStats.item)? "selected": ""
            });
        }

        return itemRenderList;
    }

    function buildEditMoveRenderDoc(pokemonStats:PokemonStats, slot:Int):Dynamic {
        var moveRenderList = [{"slug": "", "label": "-", "selected": ""}];

        for (moveSlug in movesDataset.moves.keys()) {
            moveRenderList.push({
                "slug": moveSlug,
                "label": movesDataset.getMoveStats(moveSlug).name,
                "selected": (moveSlug == pokemonStats.moves[slot])? "selected": ""
            });
        }

        return moveRenderList;
    }

    function attachEditFormListeners(pokemonStats:PokemonStats) {
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

        function readValues(event:JqEvent) {
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

            trace(pokemonStats);
            applyCustomPokemon(pokemonStats);
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

    function applyCustomPokemon(pokemonStats:PokemonStats) {
        pokemonDataset.setPokemonStats(pokemonStats.slug, pokemonStats);
        renderAll(false);
    }

    function renderChart() {
        var matchupChart = new MatchupChart(pokemonDataset, movesDataset, descriptionsDataset, formulaOptions);
        matchupChart.setPokemon(getPokemonStatsSelected());
        var tableElement = matchupChart.renderTable();

        new JQuery("#pokemonDiamond").empty().append(tableElement);
    }

    function attachOptionsListeners() {
        new JQuery("#formulaOptions-typeImmunities").change(function (event:JqEvent) {
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
