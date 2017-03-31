package visualizer.datastruct;

class VisualizerPokemonStats extends MovesetPokemonStats {
    public function new(?slug:String) {
        super(slug);
    }

    override public function fromJsonObject(doc:Dynamic) {
        super.fromJsonObject(doc);
    }

    override public function toJsonObject():Dynamic {
        var doc = super.toJsonObject();
        return doc;
    }

    override public function copy():VisualizerPokemonStats {
        var stat = new VisualizerPokemonStats();
        stat.update(this);
        return stat;
    }
}
