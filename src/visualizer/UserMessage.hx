package visualizer;


import js.Browser;
import js.html.DivElement;


class UserMessage {
    var messageContainer:DivElement;

    public function new() {
        messageContainer = cast(Browser.document.getElementById('messageContainer'), DivElement);
    }

    public function showMessage(text:String) {
        messageContainer.style.display = "block";
        messageContainer.textContent = text;
    }

    public function hide() {
        messageContainer.style.display = "none";
    }
}
