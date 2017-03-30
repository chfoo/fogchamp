package visualizer.dataset;


class Dataset {
    var callback:Bool->Void;

    public function new() {
    }

    public function load(callback:Bool->Void) {
        throw "Not implemented";
    }

    function makeRequest(url:String, callback:Bool->Void) {
        this.callback = callback;
        js.jquery.JQuery.getJSON(url).done(loadDone).fail(loadFailed);
    }

    function loadDone(data:Dynamic) {
        callback(true);
    }

    function loadFailed() {
        callback(false);
    }
}
