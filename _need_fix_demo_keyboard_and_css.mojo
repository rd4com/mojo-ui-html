from ui import *
# TODO: Fix this example, it is temporarely broken
def main():
    GUI = Server()
    GUI.request_interval_second=0.0001 #control the loop throttle (careful)
    GUI.keyboard_handler = True #False by default

    MyWindow = Position(1,1)
    var buffer = String("")
    var lastK = String("None")
    var ElementPos = (0,0)

    while GUI.Event():
        k = GUI.KeyDown()
        if k.isa[Int]():
            var K = k.take[Int]()
            if K!=0 and K >=32 and K<=127: buffer+=(chr(K))   
        elif k.isa[String]():
            var K = k.take[String]()
            lastK = K
            if K == "ArrowLeft": 
                ElementPos = (ElementPos[0]-16,ElementPos[1])
            if K == "ArrowUp": ElementPos = (ElementPos[0],ElementPos[1]-16)
            if K == "ArrowDown": ElementPos = (ElementPos[0],ElementPos[1]+16)
            if K == "ArrowRight": ElementPos = (ElementPos[0]+16,ElementPos[1])
        
        with GUI.Tag(
            "Div",
            CSS(
                position="absolute",
                left=ElementPos[0],
                top=ElementPos[1],
                `font-size`=64
            )
        ): GUI.RawHtml("🗿")

        with GUI.Window("The Title",MyWindow):
            if MyWindow.opened:
                var MyCss=CSS(
                    `text-shadow` = "1px 1px 1px yellow",
                    `font-size` = "32px",
                    background = "linear-gradient(#ffff00, #f90)"
                )
                
                with GUI.Tag("span",MyCss):
                    GUI.RawHtml("🔥🐍🐉")
                with GUI.Tag("span",CSS(color="sienna")): 
                    GUI.RawHtml(" **kwargs CSS support")
                GUI.Text("Last key:"+lastK)
                GUI.TextInput("Buffer",buffer)


         
