
from ui import *
def main():
    GUI = Server()
    var txt:String = "test"
    var todos= List[String]()  
    var time:String = "15:00"
    var date:String = "2024-01-01"
    var pos = Position(256, 128)
    while GUI.NeedNewRendition():
        with GUI.Window("Todo app",pos):
            GUI.Text(str(len(todos)))
            with GUI.ScrollableArea(128):
                for t in todos: 
                    GUI.Text(t[])
            GUI.NewLine()

            GUI.TimeSelector(time)
            GUI.DateSelector(date)
            GUI.TextInput("textinput",txt)
            
            if GUI.Button("Add"): 
                todos.append(GUI.Circle.Blue+" "+time+" " + date + " " + txt)
            if GUI.Button("pop"):
                if len(todos):todos.pop()