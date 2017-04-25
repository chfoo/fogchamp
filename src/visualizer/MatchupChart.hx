package visualizer;

import js.html.Element;
import visualizer.datastruct.VisualizerPokemonStats;
import visualizer.model.PokemonDatabase;
import visualizer.datastruct.MoveStats;
import visualizer.Formula.FormulaOptions;
import js.html.SpanElement;
import js.html.DivElement;
import js.html.TableRowElement;
import js.html.TableCellElement;
import js.html.TableElement;
import js.Browser;


enum Orientation {
    Vertical;
    Horizontal;
}


class MatchupChart {
    static var NUM_POKEMON_PER_TEAM = 3;
    static var NUM_MOVES_PER_POKEMON = 4;
    static var POKEMON_LABEL = 1;
    static var POKEMON_MOVES_LABEL = 1;
    static var DIVIDER = 1;

    var database:PokemonDatabase;
    var pokemonStatsList:Array<VisualizerPokemonStats>;
    var tableElement:TableElement;
    var formulaOptions:FormulaOptions;

    public function new(pokemonDatabase:PokemonDatabase, formulaOptions:FormulaOptions) {
        database = pokemonDatabase;
        this.formulaOptions = formulaOptions;
    }

    public function setPokemon(pokemonStatsList:Array<VisualizerPokemonStats>) {
        this.pokemonStatsList = pokemonStatsList;
    }

    public function renderTable():TableElement {
        // Table is rendered with red team as top label
        // and blue team on the left side label
        // In other words, blue team is rows and red team is columns
        tableElement = Browser.document.createTableElement();
        tableElement.classList.add("matchupChart");

        var maxWidth = POKEMON_LABEL + POKEMON_MOVES_LABEL + NUM_POKEMON_PER_TEAM * NUM_MOVES_PER_POKEMON;

        renderTopPokemonLabelRow(cast(tableElement.insertRow(-1), TableRowElement));
        renderTopPokemonMovesRow(cast(tableElement.insertRow(-1), TableRowElement));

        for (moveRowIndex in 0...NUM_POKEMON_PER_TEAM * (NUM_MOVES_PER_POKEMON + DIVIDER)) {
            renderMoveRow(moveRowIndex, cast(tableElement.insertRow(-1), TableRowElement));
        }

        return tableElement;
    }

    function renderTopPokemonLabelRow(rowElement:TableRowElement) {
        var cornerCell = cast(rowElement.insertCell(-1), TableCellElement);
        cornerCell.colSpan = cornerCell.rowSpan = POKEMON_LABEL + POKEMON_MOVES_LABEL;

        for (slotNum in [3, 4, 5]) {
            var pokemonStat = pokemonStatsList[slotNum];
            var labelCell = cast(rowElement.insertCell(-1), TableCellElement);
            labelCell.colSpan = DIVIDER + NUM_MOVES_PER_POKEMON;
            processPokemonLabelCell(pokemonStat, labelCell, "top", slotNum);
        }
    }

    function renderTopPokemonMovesRow(rowElement:TableRowElement) {
        for (slotNum in [3, 4, 5]) {
            var pokemonStat = pokemonStatsList[slotNum];

            renderMoveDividerCell(rowElement, pokemonStat, "top");

            for (moveIndex in 0...NUM_MOVES_PER_POKEMON) {
                renderMoveLabelCell(pokemonStat, moveIndex, rowElement, "top");
            }
        }
    }

    function renderMoveRow(rowIndex:Int, rowElement:TableRowElement) {
        var cellLength = DIVIDER + NUM_MOVES_PER_POKEMON;
        var leftSlotNum = Std.int(rowIndex / cellLength);
        var leftMoveIndex = Std.int(rowIndex % cellLength) - 1;
        var leftPokemonStat = pokemonStatsList[leftSlotNum];

        if (rowIndex % cellLength == 0) {
            var slotNum = Std.int(rowIndex / cellLength);
            renderLeftPokemonLabel(leftPokemonStat, rowElement, slotNum);
            renderMoveDividerCell(rowElement, leftPokemonStat, "left");
        }

        if (leftMoveIndex >= 0) {
            renderMoveLabelCell(leftPokemonStat, leftMoveIndex, rowElement, "left");
        }

        for (topSlotNum in 3...6) {
            var topPokemonStat = pokemonStatsList[topSlotNum];
            renderVersusMatrix(rowElement, leftMoveIndex, leftPokemonStat, topPokemonStat);
        }

    }

    function renderVersusMatrix(rowElement:TableRowElement, leftMoveIndex:Int, leftPokemonStat:VisualizerPokemonStats, topPokemonStat:VisualizerPokemonStats) {
        if (leftMoveIndex == -1) {
            var dividerCell = renderDividerCell(rowElement, "first");
            var dividerCellWhoFaster;

            if (leftPokemonStat.speed > topPokemonStat.speed) {
                dividerCellWhoFaster = "blue";
            } else if (leftPokemonStat.speed < topPokemonStat.speed) {
                dividerCellWhoFaster = "red";
            } else {
                dividerCellWhoFaster = "tie";
            }
            dividerCell.classList.add('matchupChartDividerCellSpeed-$dividerCellWhoFaster');

            var topPokemonMoveSlugs:Array<String> = topPokemonStat.moves;

            for (topMoveIndex in 0...NUM_MOVES_PER_POKEMON) {
                var cell = cast(rowElement.insertCell(-1), TableCellElement);
                cell.rowSpan = topMoveIndex + 1;

                if (topMoveIndex < topPokemonMoveSlugs.length) {
                    var moveStat = database.movesDataset.getMoveStats(topPokemonMoveSlugs[topMoveIndex], topPokemonStat);

                    processCellEfficacy(cell, moveStat, topPokemonStat, leftPokemonStat, "top");
                } else {
                    processCellEfficacy(cell, null, topPokemonStat, leftPokemonStat, "top");
                }
            }
        } else {
            var cell = cast(rowElement.insertCell(-1), TableCellElement);
            cell.colSpan = leftMoveIndex + 1;

            var leftPokemonMoveSlugs:Array<String> = leftPokemonStat.moves;

            if (leftMoveIndex < leftPokemonMoveSlugs.length) {
                var moveStat = database.movesDataset.getMoveStats(leftPokemonMoveSlugs[leftMoveIndex], leftPokemonStat);

                processCellEfficacy(cell, moveStat, leftPokemonStat, topPokemonStat, "left");
            } else {
                processCellEfficacy(cell, null, leftPokemonStat, topPokemonStat, "left");
            }

            if (leftMoveIndex == 3) {
                renderDividerCell(rowElement, "last");
            } else {
                renderDividerCell(rowElement);
            }

        }
    }

    function renderLeftPokemonLabel(pokemonStat:VisualizerPokemonStats, rowElement:TableRowElement, slotNum:Int) {
        var labelCell = cast(rowElement.insertCell(-1), TableCellElement);
        labelCell.rowSpan = DIVIDER + NUM_MOVES_PER_POKEMON;
        processPokemonLabelCell(pokemonStat, labelCell, "left", slotNum);
    }

    function renderMoveLabelCell(pokemonStat:VisualizerPokemonStats, moveIndex:Int, rowElement:TableRowElement, position:String) {
        var labelCell = cast(rowElement.insertCell(-1), TableCellElement);
        var moveSlugs:Array<String> = pokemonStat.moves;

        if (moveIndex < moveSlugs.length) {
            var moveSlug = moveSlugs[moveIndex];
            var moveStats = database.movesDataset.getMoveStats(moveSlug, pokemonStat);

            processMoveLabelCell(moveStats, labelCell, position);
        } else {
            processMoveLabelCell(null, labelCell, position);
        }
    }

    function processPokemonLabelCell(pokemonStats:VisualizerPokemonStats, cell:TableCellElement, position:String, slotNum:Int) {
        var container = Browser.document.createDivElement();
        container.classList.add('matchupChartPokemonLabelContainer-$position');

        var subContainer = Browser.document.createDivElement();
        subContainer.classList.add('matchupChartPokemonLabelSubContainer-$position');
        subContainer.classList.add("matchupChartPokemonLabel");

        renderPokemonIcon(subContainer, pokemonStats, slotNum);

        for (pokemonType in pokemonStats.types) {
            var typeIcon:SpanElement = Browser.document.createSpanElement();
            renderMiniTypeIcon(typeIcon, pokemonType);
            subContainer.appendChild(typeIcon);
        }

        var labelText = Browser.document.createSpanElement();
        renderPokemonName(labelText, pokemonStats);
        subContainer.appendChild(labelText);

        subContainer.appendChild(Browser.document.createTextNode(" "));

        var editText = Browser.document.createSpanElement();
        editText.textContent = "✏";
        editText.title = "Edit";
        editText.setAttribute("data-edit-slot", Std.string(slotNum));
        subContainer.appendChild(editText);

        subContainer.appendChild(Browser.document.createBRElement());

        renderAttackStats(subContainer, pokemonStats);

        container.appendChild(subContainer);
        cell.appendChild(container);
    }

    function processMoveLabelCell(moveStats:MoveStats, cell:TableCellElement, position:String) {
        cell.classList.add('matchupChartMoveLabelCell-$position');

        var container = Browser.document.createDivElement();
        container.classList.add('matchupChartMoveLabelContainer-$position');

        var subContainer = Browser.document.createDivElement();
        subContainer.classList.add('matchupChartMoveLabelSubContainer-$position');
        subContainer.classList.add("matchupChartMoveLabel");

        if (moveStats != null) {
            var typeIcon = Browser.document.createSpanElement();
            renderMiniTypeIcon(typeIcon, moveStats.moveType);
            subContainer.appendChild(typeIcon);

            var moveLabelText = Browser.document.createSpanElement();
            renderMoveText(moveLabelText, moveStats);
            subContainer.appendChild(moveLabelText);

            var moveCategoryText = Browser.document.createElement("sup");
            renderMoveCategoryShortText(moveCategoryText, moveStats);
            subContainer.appendChild(moveCategoryText);

            subContainer.appendChild(Browser.document.createBRElement());

            var accuracyText = (moveStats.accuracy != null)? Std.string(moveStats.accuracy) : "-";
            var ppText = (moveStats.pp != null)? Std.string(moveStats.pp) : "-";
            var powerText = (moveStats.power != null)? Std.string(moveStats.power) : "-";

            var moveAccText = Browser.document.createSpanElement();
            moveAccText.innerHTML = '
            $accuracyText<span class="dimLabel">%</span>
            $ppText<span class="dimLabel">pp</span>
            $powerText<span class="dimLabel">pwr</span>
            ';

            subContainer.appendChild(moveAccText);

            var priorityElement = Browser.document.createSpanElement();
            renderMovePriority(priorityElement, moveStats);
            subContainer.appendChild(priorityElement);
        }

        container.appendChild(subContainer);
        cell.appendChild(container);
    }

    function renderDividerCell(rowElement:TableRowElement, ?classSuffix:String):TableCellElement {
        var dividerCell = cast(rowElement.insertCell(-1), TableCellElement);
        dividerCell.classList.add("matchupChartDividerCell");

        if (classSuffix != null) {
            dividerCell.classList.add('matchupChartDividerCell-$classSuffix');
        }

        return dividerCell;
    }

    function renderMoveDividerCell(rowElement:TableRowElement, pokemonStats:VisualizerPokemonStats, ?classSuffix:String):TableCellElement {
        var dividerCell = renderDividerCell(rowElement, classSuffix);

        var container = Browser.document.createDivElement();
        container.classList.add('matchupChartMoveDividerContainer-$classSuffix');
        dividerCell.appendChild(container);

        var subContainer = Browser.document.createDivElement();
        subContainer.classList.add('matchupChartMoveDividerSubContainer-$classSuffix');
        subContainer.classList.add("matchupChartMoveDivider");
        container.appendChild(subContainer);

        var abilityText = Browser.document.createSpanElement();
        renderAbilityText(abilityText, pokemonStats);
        subContainer.appendChild(abilityText);

        subContainer.appendChild(Browser.document.createBRElement());

        var itemText = Browser.document.createSpanElement();
        renderItemText(itemText, pokemonStats);
        subContainer.appendChild(itemText);

        return dividerCell;
    }

    function processCellEfficacy(cell:TableCellElement, userMoveStat:MoveStats, userPokemonStat:VisualizerPokemonStats, foePokemonStat:VisualizerPokemonStats, ?position:String) {
        cell.classList.add('matchupChartEfficacyCell-$position');

        if (userMoveStat == null || userMoveStat.accuracy == null && userMoveStat.power == null) {
            return;
        }

        var container = Browser.document.createDivElement();
        container.classList.add('matchupChartEfficacyContainer-$position');

        var subContainer = Browser.document.createDivElement();
        subContainer.classList.add('matchupChartEfficacySubContainer-$position');
        subContainer.classList.add("matchupChartEfficacy");

        var damageResult = Formula.computeResult(userPokemonStat, foePokemonStat, userMoveStat, database.descriptionsDataset, formulaOptions);
        var factor = damageResult.factor;
        var factorString;

        switch (factor) {
            case 0:
                factorString = "0";
            case 25:
                factorString = "¼";
            case 50:
                factorString = "½";
            case 100:
                factorString = "1";
            case 200:
                factorString = "2";
            case 400:
                factorString = "4";
            default:
                factorString = "Err";
        }


        if (damageResult.maxHP == null) {
            if (userMoveStat.damageCategory == "status") {
                if (factor == 0) {
                    subContainer.textContent = "✕";
                } else {
                    subContainer.textContent = "○";
                }
            } else {
                subContainer.textContent = '×$factorString';
            }

            subContainer.classList.add('damageEfficacy-$factor');
        } else {
            var damageResultPercent = Formula.resultsToPercentages(damageResult, foePokemonStat.hp);

            subContainer.innerHTML = '<span class="damageEfficacy-$factor matchupChartSubEfficacy">×$factorString</span>
                <br>
                <span class=matchupChartSubEfficacy
                data-help-slug="damage:
                ${userPokemonStat.name} ${userMoveStat.name}:'+
                '${damageResultPercent.minHPPercent}:'+
                '${damageResultPercent.maxHPPercent}:'+
                '${damageResultPercent.critHPPercent}:'+
                '${damageResultPercent.minHP}:'+
                '${damageResultPercent.maxHP}:'+
                '${damageResultPercent.critHP}"
                >${damageResultPercent.maxHPPercent}<span class=dimLabel>%</span>
                </span>';
        }

        container.appendChild(subContainer);
        cell.appendChild(container);
    }

    function renderMiniTypeIcon(element:Element, pokemonType:String) {
        element.classList.add('pokemonType-$pokemonType');
        element.classList.add("miniPokemonTypeIcon");
        element.textContent = pokemonType.charAt(0);
        element.setAttribute("aria-label", pokemonType);
        element.setAttribute("title", pokemonType);
    }

    function renderPokemonName(element:Element, pokemonStats:VisualizerPokemonStats) {
        element.textContent = pokemonStats.name;
        element.classList.add("pokemonStatsName");
    }

    function renderAbilityText(element:Element, pokemonStats:VisualizerPokemonStats) {
        if (pokemonStats.ability != null && pokemonStats.ability != "") {
            element.textContent = database.descriptionsDataset.getAbilityName(pokemonStats.ability);
            element.setAttribute("data-help-slug", 'ability:${pokemonStats.ability}');
        } else {
            element.textContent = "-";
        }
    }

    function renderItemText(element:Element, pokemonStats:VisualizerPokemonStats) {
        if (pokemonStats.item != null && pokemonStats.item != "") {
            element.textContent = database.descriptionsDataset.getItemName(pokemonStats.item);
            element.setAttribute("data-help-slug", 'item:${pokemonStats.item}');
        } else {
            element.textContent = "-";
        }
    }

    function renderMoveText(element:Element, moveStats:MoveStats) {
        element.textContent = moveStats.name;
        element.setAttribute("data-help-slug", 'move:${moveStats.slug}');
    }

    function renderMoveCategoryShortText(element:Element, moveStats:MoveStats) {
        element.textContent = moveStats.damageCategory.substr(0, 2);
        element.classList.add('damageCategory-${moveStats.damageCategory}');
        element.title = moveStats.damageCategory;
    }

    function renderMovePriority(element:Element, moveStats:MoveStats) {
        if (moveStats.priority != 0) {
            if (moveStats.priority > 0) {
                element.textContent = '+${moveStats.priority}';
                element.classList.add("movePriority-high");
            } else {
                element.textContent = Std.string(moveStats.priority);
                element.classList.add("movePriority-low");
            }
            element.title = "Priority";
        }
    }

    function renderAttackStats(element:Element, pokemonStats:VisualizerPokemonStats) {
        var subElement = element.ownerDocument.createSpanElement();
        subElement.classList.add("pokemonHP");
        subElement.textContent = Std.string(pokemonStats.hp);
        subElement.title = "HP";
        element.appendChild(subElement);

        element.appendChild(element.ownerDocument.createTextNode(" "));

        subElement = element.ownerDocument.createSpanElement();
        subElement.classList.add("pokemonAttack");
        subElement.textContent = Std.string(pokemonStats.attack);
        subElement.title = "Attack";
        element.appendChild(subElement);

        element.appendChild(element.ownerDocument.createTextNode("·"));

        subElement = element.ownerDocument.createSpanElement();
        subElement.classList.add("pokemonDefense");
        subElement.textContent = Std.string(pokemonStats.defense);
        subElement.title = "Defense";
        element.appendChild(subElement);

        element.appendChild(element.ownerDocument.createTextNode(" "));

        subElement = element.ownerDocument.createSpanElement();
        subElement.classList.add("pokemonSpecialAttack");
        subElement.textContent = Std.string(pokemonStats.specialAttack);
        subElement.title = "Special Attack";
        element.appendChild(subElement);

        element.appendChild(element.ownerDocument.createTextNode("·"));

        subElement = element.ownerDocument.createSpanElement();
        subElement.classList.add("pokemonSpecialDefense");
        subElement.textContent = Std.string(pokemonStats.specialDefense);
        subElement.title = "Special Defense";
        element.appendChild(subElement);

        element.appendChild(element.ownerDocument.createTextNode(" "));

        subElement = element.ownerDocument.createSpanElement();
        subElement.classList.add("pokemonSpeed");
        subElement.textContent = Std.string(pokemonStats.speed);
        subElement.title = "Speed";
        element.appendChild(subElement);
    }

    function renderPokemonIcon(element:Element, pokemonStats:VisualizerPokemonStats, slotNum:Int) {
        var img = element.ownerDocument.createImageElement();
        img.classList.add("pokemonIcon");
        img.classList.add("pokemonIconChart");
        img.classList.add('pokemonIconSlot-${slotNum}');
        img.src = 'static/veekun/icons/${pokemonStats.number}.png';

        element.appendChild(img);
    }
}
