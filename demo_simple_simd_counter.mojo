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
