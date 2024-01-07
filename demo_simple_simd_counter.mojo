from ui import *
from math import iota, sqrt
def main():
    GUI = Server[base_theme="theme_neutral.css"]()
    var counter = 0
    while GUI.Event(): 
        #Not necessary to create a window if not needed
        if GUI.Button("increment"): counter+=1
        if GUI.Button("decrement"): counter-=1
        GUI.Slider("Counter",counter)
        var tmp = iota[DType.float16,SIMD[DType.float16].size](counter)
        GUI.Text(tmp)
        GUI.Text(sqrt(tmp))

        #There is a refresh challenge if events occurs after value drawn
        #If buttons are here, previously drawn GUI.Text won't reflect the new value
        #Temporary fix: if GUI.Button("Refresh"): ...