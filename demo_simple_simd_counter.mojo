from ui import *
from math import iota, sqrt
from sys import simdwidthof
def main():
    GUI = Server()
    var counter = 0
    while GUI.NeedNewRendition(): 
        #Not necessary to create a window if not needed
        if GUI.Button("increment"): counter+=1
        if GUI.Button("decrement"): counter-=1
        GUI.Slider("Counter",counter)
        var tmp = iota[DType.float16, simdwidthof[DType.float16]()](counter)
        GUI.Text(repr(tmp))
        GUI.Text(repr(sqrt(tmp)))
