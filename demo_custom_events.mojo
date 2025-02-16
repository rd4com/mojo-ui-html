# Not ready yet, just a start! 
from ui import *
def main():
    GUI = Server()
    var counter = 0
    while GUI.NeedNewRendition(): 
        var MyCustomEvent = GUI.CustomEvent("MyEvent")
        if MyCustomEvent:
            counter+=1
            print(MyCustomEvent.take() == "ok")
        GUI.RawHtml(String(
            "<a onmouseover=\"event_and_refresh('/custom_event_MyEvent/ok')\" >",
            "➡️ mouse hover ⬅️",
            "</a>"
        ))
        GUI.Text(repr(counter)) #Increments 