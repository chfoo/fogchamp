package visualizer;


import visualizer.dataset.DescriptionsDataset;
import visualizer.dataset.MovesDataset;
import visualizer.dataset.PokemonDataset;
import js.Browser;
import js.JQuery;


class Main {
    static var LOAD_FAIL_MSG = "Loading dataset failed. Reload the page.";
    var userMessage:UserMessage;
    var pokemonDataset:PokemonDataset;
    var movesDataset:MovesDataset;
    var descriptionsDataset:DescriptionsDataset;
    var ui:UI;

    public function new() {
        userMessage = new UserMessage();
        pokemonDataset = new PokemonDataset();
        movesDataset = new MovesDataset();
        descriptionsDataset = new DescriptionsDataset();
    }

    static public function main() {
        var app = new Main();
        new JQuery(Browser.document.body).ready(function (event:JqEvent) {
            app.run();
        });
    }

    function run() {
        loadPokemonDataset();
    }

    function loadPokemonDataset() {
        userMessage.showMessage("Loading Pokemon dataset.");

        pokemonDataset.load(
            function (success:Bool) {
                if (success) {
                    userMessage.hide();
                    loadMovesDataset();
                } else {
                    userMessage.showMessage(LOAD_FAIL_MSG);
                }
            }
        );
    }

    function loadMovesDataset() {
        userMessage.showMessage("Loading Moves dataset.");

        movesDataset.load(
            function (success:Bool) {
                if (success) {
                    userMessage.hide();
                    loadDescriptionsDataset();
                } else {
                    userMessage.showMessage(LOAD_FAIL_MSG);
                }
            }
        );
    }

    function loadDescriptionsDataset() {
        userMessage.showMessage("Loading Descriptions dataset.");

        descriptionsDataset.load(
            function (success:Bool) {
                if (success) {
                    userMessage.hide();
                    loadUI();
                } else {
                    userMessage.showMessage(LOAD_FAIL_MSG);
                }
            }
        );
    }

    function loadUI() {
        ui = new UI(pokemonDataset, movesDataset, descriptionsDataset);
        ui.setup();
    }
}
