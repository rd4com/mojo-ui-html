from ui import *

def main():
    var GUI = Server()
    GUI.request_interval_second = 0 #no Time.sleep between events
    GUI.keyboard_handler = True
    var pos = SIMD[DType.int32, 2](0)   #[x, y]
    while GUI.NeedNewRendition(): 
        k = GUI.KeyDown()
        if not k.isa[NoneType]():
            # if k.isa[Int]():
            #     print(k[Int])# example: ord('a'), ..
            if k.isa[String]():
                var k_tmp = k[String] 
                if k_tmp == "ArrowUp": pos[1] -= 10
                elif k_tmp == "ArrowDown": pos[1] += 10
                elif k_tmp == "ArrowLeft": pos[0] -= 10
                elif k_tmp == "ArrowRight": pos[0] += 10
        GUI.RawHtml(String(
            "<div style='position:absolute;",
            "left:",pos[0],";",
            "top:", pos[1],";"
            "'>🚙</div>"
        ))
