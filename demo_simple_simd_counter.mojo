from ui import *
from math import iota, sqrt
def main():
    GUI = Server[base_theme="theme_neutral.css"]()
    var counter = 0
    while GUI.Event(): 
        #Not necessary to create a window if not needed
        if GUI.Button("increment"): counter+=1
        if GUI.Button("decrement"): counter-=1
        GUI.Slider("Counter", counter)
        var tmp = iota[simd_width=simdwidthof[DType.float16]()](
            SIMD[DType.int64, 1](counter).cast[DType.float16]()
        )
        GUI.Text(str(tmp))
        GUI.Text(str(sqrt(tmp)))
