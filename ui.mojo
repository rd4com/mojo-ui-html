from python import Python
from time import sleep

alias JS = """<script>
['click','input','change'].forEach(function(evt) {
    document.addEventListener(evt, function (event) {         
        var id = event.target.getAttribute('id'); 
        if (id){
            if (evt == "click") {
                if (event.target.dataset.click == "true"){
                    window.location.href = "/"+evt+"_"+id
                } else {
                    
                }
            }
            if (evt == "change") {
                if (event.target.dataset.change == "true"){
                    window.location.href = "/"+evt+"_"+id+"/"+event.target.value
                }
                 if (event.target.dataset.combobox == "true"){
                    window.location.href = "/combobox_"+id+"/"+event.target.selectedIndex
                }
            }
            if (evt == "input") {
                if (event.target.dataset.hasOwnProperty('input')){
                    window.location.href = "/"+evt+"_"+id+"/"+event.target.value
                }
            }
        }
    });
})
        
var dragx = 0
var dragy = 0
var dragid = 0

function preventDefaults(e) {
  e.preventDefault();
}

function drag(e) {
    dragx = e.clientX
    dragy = e.clientY
    dragid = e.target.id;
}

function drop(e) {
    var x_delta = e.clientX-dragx
    var y_delta = e.clientY-dragy
    //console.log(dragid,e.clientX-dragx,e.clientY-dragy)
    window.location.href = "/window_"+dragid+"/"+x_delta+"/"+y_delta
    e.preventDefault();
}
</script>"""
@value
struct Position:
    var x:Int
    var y:Int
@value
struct Server:
    var server: PythonObject
    var client: PythonObject
    var response: PythonObject
    var request: PythonObject
    var data: String
    var send_response : Bool
    var request_interval_second: Float64
    fn __init__(inout self) raises:
        self.server  = PythonObject(None)
        self.client = PythonObject(None)
        self.response = PythonObject(None)
        self.request = PythonObject(None)
        self.data = ""
        self.send_response=False
        self.request_interval_second=0.1
        self.start()

    def start(inout self, host:StringLiteral = "127.0.0.1", port:Int = 8000):
        var socket = Python.import_module("socket")
        self.server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.server.bind((host, port))
        self.server.setblocking(0)
        self.server.listen(1)
        print("http://"+str(host)+":"+port)
    fn __del__(owned self):
        try: self.server.close() except e: print(e)
    def Event(inout self)->Bool: 
        if self.send_response == True: #non blocking loop, if previous iteration generated response, do send
            self.response+="</body></html>"
            self.client[0].sendall(self.response.encode())
            self.client[0].close()
        self.response = PythonObject('HTTP/1.0 200 OK\n\n')+"<html  ondrop='drop(event)' ondragover='preventDefaults(event)'><head>"+JS+"<style>"+Theme.Css()+"</style><meta charset='UTF-8'></head><body>"
        try: #if error is raised in the block, no request or an error
            self.client = self.server.accept()
            self.request = self.client[0].recv(1024).decode()
            self.request = self.request.split('\n')[0].split(" ")
           #print(self.request) # for debug
            self.send_response=True
        except e:
            self.send_response=False 
        if self.request_interval_second != 0: sleep(self.request_interval_second)
        return True #todo: should return self.Running: bool to exit the loop
    def SetNoneRequest(inout self):
        self.request = PythonObject(None) #None means event handled (if self.request == True)
    @staticmethod
    def TagBuild(T:String,content:String,CSS:String="",id:String="")->String:
        return String("<"+T)+ " style='"+CSS+"' id='"+id+"'"+">" + content + "</"+T+">"
    def Button(inout self,txt:String) ->Bool:
        self.response = str(self.response)+"<div data-click='true' style='"+Theme.Button+"' id='"+txt+"'"+">" + txt + "</div>"
        if self.request and self.request[1] == "/click_"+txt:
            self.SetNoneRequest()
            return True
        return False
    def Toggle(inout self,inout val:Bool,label:String):
        var tmp:Pointer[Bool] = __get_lvalue_as_address(val)
        t = tmp.__as_index()
        var val_repr = String("border-width: 4px;color: black;border-color: black;border-style: solid;background-color: red;max-width: fit-content;")
        
        var id:String = str(t)
        if self.request and self.request[1] == "/click_"+id:
            val = not val
            self.SetNoneRequest()

        if val: val_repr = "border-width: 4px;color: black;border-color: black;border-style: solid;background-color: green;max-width: fit-content;"
        self.response = str(self.response)+"<div data-click='true' style='"+val_repr+"' id='"+id+"'"+">"+label+ "</div>"

    def Text(inout self, txt:String):
        self.response = str(self.response)+Self.TagBuild("Div",txt,Theme.Text)

    def Window(inout self, name: String,inout pos:Position)->Window:
        let ptr:Pointer[PythonObject] = __get_lvalue_as_address(self.request)
        return Window(__get_lvalue_as_address(self.response), name,__get_lvalue_as_address(pos),ptr)
    def Slider(inout self,label:String,inout val:Int):
        var tmp:Pointer[Int] = __get_lvalue_as_address(val)
        t = tmp.__as_index()
        var id:String = str(t)
        var retval = False
        if self.request and self.request[1].startswith("/change_"+id):
            val = atol(str(self.request[1].split("/")[2])) #split by "/change_"+id ?
            self.SetNoneRequest()
            retval=True
        self.response = str(self.response)+"<div style='"+Theme.SliderBox+"'><div><b>"+label+"</b> "+str(val)+"</div>"
        self.response = str(self.response)+"<input data-change='true' type='range' min='1' max='100' value='"+str(val)+"' style='"+Theme.SliderSlider+"' id='"+id+"'>"
        self.response = str(self.response)+"</div>"
        
        return retval

    def TextInput(inout self,label:String,inout val:String):
        var focus = ""
        var tmp:Pointer[String] = __get_lvalue_as_address(val)
        t = tmp.__as_index()
        var id:String = str(t)
        tmp2 = "/change_"+id+"/"

        if self.request and self.request[1].startswith(tmp2):    
            val = str(self.request[1].split(tmp2)[1])
            self.SetNoneRequest()

        self.response = str(self.response)+"<div style='"+Theme.TextInputBox+"'>"
        if label!="":
            self.response = str(self.response)+"<b>"+label+" </b>"
        self.response = str(self.response)+"<input data-change='true' value='"+val+"'"+ focus +" type='text' style='"+Theme.TextInput+"'id='"+id+"'>"
        self.response = str(self.response)+"</div>"
    
    def ComboBox(inout self,label:String,values:DynamicVector[String],inout selection:Int):
        var tmp:Pointer[Int] = __get_lvalue_as_address(selection)
        t = tmp.__as_index()
        var id:String = str(t)
        var tmp2 = "/combobox_"+id+"/"
        if self.request and self.request[1].startswith(tmp2):    
            selection = atol(str(self.request[1].split(tmp2)[1]))
            self.SetNoneRequest()
        

        self.response = str(self.response)+"<div style='"+Theme.ComboBoxBox+"'>"
        self.response = str(self.response)+"🔽<b>"+label+" </b>"
        self.response = str(self.response)+"<select data-combobox='true' style='"+Theme.ComboBox+"' id='" +id+"'>"
        for s in range(len(values)):
            var selected:String = ""
            if s == selection : selected = "selected"
            self.response +=  "<option "+ selected +" value='" + values[s] +"'>"+values[s]+"</option>"
        self.response += "</select>"
        self.response = str(self.response)+"</div>"
        
@value
struct Window:
    var content: Pointer[PythonObject]
    var name: String
    var pos: Pointer[Position]
    var request: Pointer[PythonObject]
    fn __enter__(self):
        try:
            var id = str(self.pos.__as_index())#str(hash(self.name._as_ptr(),len(self.name)))
            var positions:String = "position: absolute;"
            var req = __get_address_as_lvalue(self.request.address)
            if req and req[1].startswith("/window_"+id): 
                var val = req[1].split("/window_"+id)[1].split("/")
                __get_address_as_lvalue(self.pos.address).x += atol(str(val[1]))
                __get_address_as_lvalue(self.pos.address).y += atol(str(val[2]))
                __get_address_as_lvalue(self.request.address) = PythonObject(None) #possibly not good
            positions += "left:"+str(__get_address_as_lvalue(self.pos.address).x)+"px;"
            positions += "top:"+str(__get_address_as_lvalue(self.pos.address).y)+"px;"
            __get_address_as_lvalue(self.content.address) += "<div draggable='true' ondragstart='drag(event)' style='" +Theme.Window+positions+ "' id='"+id +"'>"
            __get_address_as_lvalue(self.content.address) += "<div style='" + Theme.WindowTitle + "'>➖ ❌ " + self.name + "&nbsp;</div>"
            __get_address_as_lvalue(self.content.address) += "<div style='" + Theme.WindowContent +"'>"
        except e: print(e)
    fn __exit__( self): self.close()
    fn close(self) -> Bool:
        try:
            __get_address_as_lvalue(self.content.address) += "</div></div>"
        except e: print(e) 
        return True
    fn __exit__( self, err:Error)->Bool: return self.close()

alias Theme = MojoTheme #DefaultTheme

struct MojoTheme:
    alias Button = """border-width: 4px;color: blue;border-color: black;border-style: solid;background-color: yellow;max-width: fit-content;"""
    alias Toggle = """max-width: fit-content;"""
    alias Text = """padding:4px;color: black;max-width: fit-content;"""
    alias SliderBox = """border: 4px dotted black;margin:1px;max-width: fit-content;"""
    alias SliderSlider = """height: 4px;max-width: fit-content;"""
    alias ComboBoxBox = """border: 4px solid black;margin:1px;max-width: fit-content;"""
    alias ComboBox = """font-size: 75%;border: 0px;max-width: fit-content;"""
    alias TextInputBox = """border: 4px dashed black;margin:1px;max-width: fit-content;"""
    alias TextInput = """font-size: 75%;border: 0px;max-width: fit-content;"""
    alias Window = "border-width: 4px;border-color: black;border-style: solid;;max-width: fit-content;"
    alias WindowContent= "padding:1px;background-color: white"
    alias WindowTitle= "background-color: rgb(255,127,0);color: white;border-bottom: 4px solid black;"
    @staticmethod
    def Css(BaseTextSize:Int=200)->String:
        var res:String = "body {"
        res+= "margin: 0px;padding:1px;"
        res += "font-family:monospace;"
        res += "font-size: "+str(BaseTextSize)+"%;"
        res += "min-height: 100%;"
        res += "background: rgb(255,254,0);"
        res += "background: linear-gradient(0deg, rgba(255,255,0,1) 0%, rgba(255,255,0,1) 15%, rgba(255,0,0,1) 100%);"      
        res += "}"
        res += "html {min-height: 100%;}"
        return res

def main():
    val = 50
    txt = String("Some value")
    boolval = True
    GUI = Server() #GUI.request_interval_second = 0.05 for faster refreshes
    POS = Position(1,1)
    POS2 = Position(1,350)

    combovalues = DynamicVector[String]()
    for i in range(5): combovalues.push_back("Value "+str(i))
    selection = 1

    while GUI.Event():
        with GUI.Window("Debug window",POS):
            GUI.Text("Hello world 🔥")
            if GUI.Button("Button"): val = 50 
            if GUI.Slider("Slider",val): 
                print("Changed")
            GUI.TextInput("Edit",txt)                       #spaces not supported yet
            GUI.ComboBox("ComboBox",combovalues,selection)
            GUI.Text("value:"+txt)
            GUI.Toggle(boolval,"Checkbox")
        with GUI.Window("Test",POS2): 
            GUI.Text(txt)
            if selection < len(combovalues):                #manual bound check for now
                GUI.Text("Selected:" + combovalues[selection])
