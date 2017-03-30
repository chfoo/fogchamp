package visualizer;


import visualizer.dataset.Dataset.LoadEvent;
import visualizer.dataset.APIPokemonDataset;
import js.jquery.Event;
import visualizer.model.PokemonDatabase;
import visualizer.dataset.DescriptionsDataset;
import visualizer.dataset.MovesDataset;
import visualizer.dataset.PokemonDataset;
import js.Browser;
import js.jquery.JQuery;


class Main {
    static var LOAD_FAIL_MSG = "Loading dataset failed. Reload the page.";
    var userMessage:UserMessage;
    var pokemonDataset:PokemonDataset;
    var apiPokemonDataset:APIPokemonDataset;
    var movesDataset:MovesDataset;
    var descriptionsDataset:DescriptionsDataset;
    var database:PokemonDatabase;
    var ui:UI;

    public function new() {
        userMessage = new UserMessage();
        pokemonDataset = new PokemonDataset();
        apiPokemonDataset = new APIPokemonDataset();
        movesDataset = new MovesDataset();
        descriptionsDataset = new DescriptionsDataset();
        database = new PokemonDatabase(pokemonDataset, apiPokemonDataset, movesDataset, descriptionsDataset);
    }

    static public function main() {
        var app = new Main();
        new JQuery(Browser.document.body).ready(function (event:Event) {
            app.run();
        });
    }

    function run() {
        loadPokemonDataset();
    }

    function loadPokemonDataset() {
        userMessage.showMessage("Loading Pokemon dataset.");

        pokemonDataset.load(
            function (event:LoadEvent) {
                if (event.success) {
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
            function (event:LoadEvent) {
                if (event.success) {
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
            function (event:LoadEvent) {
                if (event.success) {
                    userMessage.hide();
                    loadAPIMovesets();
                } else {
                    userMessage.showMessage(LOAD_FAIL_MSG);
                }
            }
        );
    }

    function loadAPIMovesets() {
        try {
            apiPokemonDataset.loadFromStorage();
        } catch (error:StorageEmpty) {
            callAPIForMovesets();
            return;
        }

        loadUI();
    }

    function callAPIForMovesets() {
        userMessage.showMessage("Loading Movesets from TPP... This may take a while.");
        apiPokemonDataset.load(
            function (event:LoadEvent) {
                if (event.success) {
                    userMessage.hide();
                    apiPokemonDataset.saveToStorage();
                } else {
                    userMessage.showMessage("Failed to load movesets from TPP.");
                }
                loadUI();
            }
        );
    }

    function loadUI() {
        ui = new UI(database);
        ui.setup();
    }
}
