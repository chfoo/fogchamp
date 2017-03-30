package visualizer;

import visualizer.model.PokemonDatabase;
import visualizer.datastruct.MoveStats;
import visualizer.datastruct.PokemonStats;
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
    var pokemonStats:Array<PokemonStats>;
    var tableElement:TableElement;
    var formulaOptions:FormulaOptions;

    public function new(pokemonDatabase:PokemonDatabase, formulaOptions:FormulaOptions) {
        database = pokemonDatabase;
        this.formulaOptions = formulaOptions;
    }

    public function setPokemon(pokemonStats:Array<PokemonStats>) {
        this.pokemonStats = pokemonStats;
    }

    public function renderTable():TableElement {
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
            var pokemonStat = pokemonStats[slotNum];
            var labelCell = cast(rowElement.insertCell(-1), TableCellElement);
            labelCell.colSpan = DIVIDER + NUM_MOVES_PER_POKEMON;
            processPokemonLabelCell(pokemonStat, labelCell, "top");
        }
    }

    function renderTopPokemonMovesRow(rowElement:TableRowElement) {
        for (slotNum in [3, 4, 5]) {
            var pokemonStat = pokemonStats[slotNum];

            renderDividerCell(rowElement);

            for (moveIndex in 0...NUM_MOVES_PER_POKEMON) {
                renderMoveLabelCell(pokemonStat, moveIndex, rowElement, "top");
            }
        }
    }

    function renderMoveRow(rowIndex:Int, rowElement:TableRowElement) {
        var cellLength = DIVIDER + NUM_MOVES_PER_POKEMON;
        var leftSlotNum = Std.int(rowIndex / cellLength);
        var leftMoveIndex = Std.int(rowIndex % cellLength) - 1;
        var leftPokemonStat = pokemonStats[leftSlotNum];

        if (rowIndex % cellLength == 0) {
            renderLeftPokemonLabel(leftPokemonStat, rowElement);

            renderDividerCell(rowElement);
        }

        if (leftMoveIndex >= 0) {
            renderMoveLabelCell(leftPokemonStat, leftMoveIndex, rowElement, "left");
        }

        for (topSlotNum in 3...6) {
            var topPokemonStat = pokemonStats[topSlotNum];
            renderVersusMatrix(rowElement, leftMoveIndex, leftPokemonStat, topPokemonStat);
        }

    }

    function renderVersusMatrix(rowElement:TableRowElement, leftMoveIndex:Int, leftPokemonStat:PokemonStats, topPokemonStat:PokemonStats) {
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
                }
            }
        } else {
            var cell = cast(rowElement.insertCell(-1), TableCellElement);
            cell.colSpan = leftMoveIndex + 1;

            var leftPokemonMoveSlugs:Array<String> = leftPokemonStat.moves;

            if (leftMoveIndex < leftPokemonMoveSlugs.length) {
                var moveStat = database.movesDataset.getMoveStats(leftPokemonMoveSlugs[leftMoveIndex], leftPokemonStat);

                processCellEfficacy(cell, moveStat, leftPokemonStat, topPokemonStat, "left");
            }

            if (leftMoveIndex == 3) {
                renderDividerCell(rowElement, "last");
            } else {
                renderDividerCell(rowElement);
            }

        }
    }

    function renderLeftPokemonLabel(pokemonStat:Dynamic, rowElement:TableRowElement) {
        var labelCell = cast(rowElement.insertCell(-1), TableCellElement);
        labelCell.rowSpan = DIVIDER + NUM_MOVES_PER_POKEMON;
        processPokemonLabelCell(pokemonStat, labelCell, "left");
    }

    function renderMoveLabelCell(pokemonStat:PokemonStats, moveIndex:Int, rowElement:TableRowElement, position:String) {
        var labelCell = cast(rowElement.insertCell(-1), TableCellElement);
        var moveSlugs:Array<String> = pokemonStat.moves;

        if (moveIndex < moveSlugs.length) {
            var moveSlug = moveSlugs[moveIndex];
            var moveStats = database.movesDataset.getMoveStats(moveSlug, pokemonStat);

            processMoveLabelCell(moveStats, labelCell, position);
        }
    }

    function processPokemonLabelCell(pokemonStat:PokemonStats, cell:TableCellElement, position:String) {
        var container:DivElement = Browser.document.createDivElement();
        container.classList.add('matchupChartLabel-$position');

        var span:SpanElement = Browser.document.createSpanElement();
        span.classList.add('matchupChartLabelRotate-$position');

        var pokemonTypes = pokemonStat.types;

        for (pokemonType in pokemonTypes) {
            var typeIcon:SpanElement = Browser.document.createSpanElement();
            typeIcon.classList.add('pokemonType-$pokemonType');
            typeIcon.classList.add("miniPokemonTypeIcon");
            typeIcon.textContent = " ";
            span.appendChild(typeIcon);
        }

        var labelText:SpanElement = Browser.document.createSpanElement();
        labelText.textContent = pokemonStat.name;
        span.appendChild(labelText);

        container.appendChild(span);
        cell.appendChild(container);
    }

    function processMoveLabelCell(moveStats:MoveStats, cell:TableCellElement, position:String) {
        cell.classList.add('matchupChartMoveCell-$position');

        var container:DivElement = Browser.document.createDivElement();
        container.classList.add('matchupChartMoveLabel-$position');

        var span:SpanElement = Browser.document.createSpanElement();
        span.classList.add('matchupChartMoveLabelRotate-$position');

        var typeIcon:SpanElement = Browser.document.createSpanElement();
        typeIcon.classList.add('pokemonType-${moveStats.moveType}');
        typeIcon.classList.add("miniPokemonTypeIcon");
        typeIcon.textContent = " ";
        span.appendChild(typeIcon);

        var moveLabelText:SpanElement = Browser.document.createSpanElement();
        moveLabelText.textContent = moveStats.name;
        span.appendChild(moveLabelText);

        container.appendChild(span);
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

    function processCellEfficacy(cell:TableCellElement, userMoveStat:MoveStats, userPokemonStat:PokemonStats, foePokemonStat:PokemonStats, ?position:String) {
        cell.classList.add('matchupChartEfficacyCell-$position');

        if (userMoveStat.accuracy == null && userMoveStat.power == null) {
            return;
        }

        var container:DivElement = Browser.document.createDivElement();
        container.classList.add('matchupChartEfficacy-$position');

        var span:SpanElement = Browser.document.createSpanElement();
        span.classList.add('matchupChartEfficacyRotate-$position');

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
                    span.textContent = "✕";
                } else {
                    span.textContent = "○";
                }
            } else {
                span.textContent = '×$factorString';
            }

            span.classList.add('damageEfficacy-$factor');
        } else {
            var damageResultPercent = Formula.resultsToPercentages(damageResult, foePokemonStat.hp);

            span.innerHTML = '<span class="damageEfficacy-$factor matchupChartSubEfficacy">×$factorString</span>
                <span class=matchupChartSubEfficacy
                data-help-slug="damage:
                ${userPokemonStat.name} ${userMoveStat.name}:
                ${damageResultPercent.minHPPercent}:${damageResultPercent.maxHPPercent}:${damageResultPercent.critHPPercent}"
                >${damageResultPercent.maxHPPercent}<span class=dimLabel>%</span>
                </span>';
        }

        container.appendChild(span);
        cell.appendChild(container);
    }
}
