from ui import *
def main():
    GUI = Server[base_theme="theme_neutral.css"]()
    var txt:String = "test"
    var todos= DynamicVector[String]()  
    var time:String = "15:00"
    var date:String = "2024-01-01"
    var color:String = "#3584E4"
    var pos = Position(256,128,2.0)
    var pos2 = Position(0,128,1.0)
    while GUI.Event():
        with GUI.Window("Test:"+txt,pos2):
            GUI.Text(str(len(todos)))
            for i in range(len(todos)): GUI.Text(todos[i])

        with GUI.Window("Test",pos,"background-color:"+color):
            GUI.Text(str(len(todos)))
            if len(todos) == 4:
                todos.clear()
                pos.x+=100
                GUI.should_re_render()
            with GUI.ScrollableArea(128):
                for i in range(len(todos)): 
                    GUI.Text(todos[i])
            GUI.NewLine()

            GUI.TimeSelector(time)
            GUI.DateSelector(date)
            GUI.TextInput("textinput",txt)
            if GUI.Button("Add"): todos.push_back(GUI.Circle.Blue+" "+time+" " + date + " " + txt)
            if GUI.Button("pop"):
                if len(todos):todos.pop_back()
            GUI.ColorSelector(color)
            if pos2.x != 0:
                pos2.x = 0
                GUI.should_re_render()



            




            
