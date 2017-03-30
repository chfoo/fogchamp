package visualizer.datastruct;

class VisualizerPokemonStats extends MovesetPokemonStats {
    public var extendedName:String;

    public function new(?slug:String) {
        super(slug);
    }

    override public function fromJsonObject(doc:Dynamic) {
        super.fromJsonObject(doc);

        extendedName = Reflect.field(doc, "extended_name");
    }

    override public function toJsonObject():Dynamic {
        var doc = super.toJsonObject();

        Reflect.setField(doc, "extended_name", extendedName);

        return doc;
    }
}
