from ui import *
def main():
    GUI = Server()
    while GUI.NeedNewRendition(): 
        with GUI.HorizontalGrow():
            with GUI.VerticalGrow():
                GUI.Text("First column")
                for i in range(3):
                    GUI.Button(GUI.Digitize(i))
            with GUI.VerticalGrow():
                GUI.Text("Second column")
                for i in range(3):
                    GUI.Button(repr(i))

#Result:
# First column Second column
# 0️⃣           0
# 1️⃣           1
# 2️⃣           2
