from ui import *

def main():
    #⚠️ see readme.md in order to be aware about challenges and limitations!
    val = 50
    txt = String("Naïve UTF8 🥳")
    boolval = True
    multichoicevalue = String("First")
    colorvalue = String("#1C71D8")
    datevalue = String("2024-01-01")

    GUI = Server()  #Server[base_theme="theme_neutral.css"]()

    POS = Position(1,1)
    POS2 = Position(1,350)
    POS3 = Position(32,512)
    POS4 = Position(512,16)

    combovalues = List[String]()
    for i in range(5): combovalues.append("Value "+str(i))
    selection = 1

    while GUI.Event():
        with GUI.Window("Debug window",POS):
            GUI.Text("Hello world 🔥")
            if GUI.Button("Button"): val = 50 
            if GUI.Slider("Slider",val): 
                print("Changed")
            GUI.TextInput("Input",txt) #⚠️ ```maxlength='32'``` attribute by default.
            GUI.ComboBox("ComboBox",combovalues,selection)
            GUI.Toggle(boolval,"Checkbox")

        with GUI.Window("Fun features",POS3):
            GUI.Text(GUI.Circle.Green + " Green circle")
            GUI.Text(GUI.Square.Blue + " Blue square")
            GUI.Text(GUI.Accessibility.Info + " Some icons")
            GUI.Text(GUI.Bold("Bold() ")+GUI.Highlight("Highlight()"))
            GUI.Text(GUI.Small("small") + " text")

            with GUI.Collapsible("Collapsible()"):
                GUI.Text("Content")

        with GUI.Window("More widgets",POS4):
            GUI.TextChoice("Multi Choice",multichoicevalue,"First","Second")
            GUI.Ticker("⬅️♾️ cycling left in a 128 pixels area",width=128)

            with GUI.Table():
                for r in range(3):
                    with GUI.Row():
                        for c in range(3): 
                            with GUI.Cell():
                                GUI.Text(str(r) + "," + str(c))
    
            with GUI.ScrollableArea(123):
                GUI.Text(GUI.Bold("ScrollableArea()"))
                GUI.ColorSelector(colorvalue)
                GUI.NewLine()
                GUI.DateSelector(datevalue) #⚠️ format is unclear (see readme.md)
                for i in range(10): GUI.Text(str(i))
        

        with GUI.Window("Values",POS2,CSSTitle="background-color:"+colorvalue): 
            GUI.Text(txt)
            if selection < len(combovalues):                #manual bound check for now
                GUI.Text(combovalues[selection])
            with GUI.Tag("div","background-color:"+colorvalue):
                GUI.Text(colorvalue)
            GUI.Text(datevalue)
            with GUI.Tag("div","padding:0px;margin:0px;font-size:100"):
                GUI.Text("❤️‍🔥")
            GUI.Button("ok",CSS="font-size:32;background-color:"+colorvalue)
            