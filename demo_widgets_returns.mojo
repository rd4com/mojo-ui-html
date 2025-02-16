from ui import *

def main():
    var GUI = Server()
    var pos = Position(128,128,1.0)
    var s:String = ""
    var t:String = "23:59"
    var c:String = "#3584E4"
    var i:Int = 0
    var i2:Int = 0
    var b:Bool = False
    var message:String = "Empty"
    
    while GUI.NeedNewRendition():
        with GUI.Window(message,pos,"background-color:"+c):
            GUI.Text('s = '+s)
            GUI.Text('i = '+str(i))
            GUI.Text('b = '+str(b))
            GUI.Text('i2= '+str(i2))
            GUI.Text('t = '+str(t))
            GUI.Text('c = '+str(c))

            if GUI.ComboBox("Choice",i,"a","b"):
                message = "ComboBox: "+str(i)
            if GUI.Button("Click"): message = "Click"
            if GUI.TextInput("Edit",s):
                message = "TextInput: "+ s
            if GUI.Toggle(b,"CheckBox"):
                message = "CheckBox: "+ str(b)
            if GUI.Slider("Slider",i2):
                message = "Slider: "+ str(i2)
            if GUI.TimeSelector(t):
                message = "TimeSelector: "+t
            if GUI.ColorSelector(c):
                message = "ColorSelector: "+c
            
