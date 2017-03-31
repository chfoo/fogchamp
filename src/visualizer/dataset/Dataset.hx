package visualizer.dataset;

import js.jquery.JqXHR;


class DatasetItemNotFoundError {
    public function new() {

    }
}

class LoadEvent {
    public var success:Bool;
    public var errorMessage:String;

    public function new(success:Bool, ?errorMessage:String) {
        this.success = success;
        this.errorMessage = errorMessage;
    }
}

typedef DatasetLoadCallback = LoadEvent -> Void;

interface DatasetLoadable {
    public function load(callback:DatasetLoadCallback):Void;
}

class Dataset implements DatasetLoadable {
    var callback:DatasetLoadCallback;

    public function new() {
    }

    public function load(callback:DatasetLoadCallback) {
        throw "Not implemented";
    }

    function makeRequest(url:String, callback:DatasetLoadCallback) {
        this.callback = callback;
        js.jquery.JQuery.getJSON(url).done(loadDone).fail(loadFailed);
    }

    function loadDone(data:Dynamic) {
        callback(new LoadEvent(true));
    }

    function loadFailed(xhr:JqXHR, textStatus:String, error:Dynamic) {
        callback(new LoadEvent(false, '$textStatus: ${xhr.status} ${xhr.statusText}'));
    }
}
