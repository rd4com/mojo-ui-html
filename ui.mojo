from python import Python
from time import sleep

struct Accessibility:
    alias Success:String = "✅"
    alias Info:String = "ℹ️"
    alias Warning: String = "⚠️"

struct Circles:
    alias Green: String = "🟢"
    alias Red: String = "🔴"
    alias Yellow:String = "🟡"
    alias Black:String = "⚫"
    alias Blue:String = "🔵"
    alias Purple: String = "🟣"
    alias White:String = "⚪"
    alias Orange: String = "🟠"
    alias Brown:String= "🟤"

struct Squares:
    alias Green: String = "🟩"
    alias Red: String = "🟥"
    alias Yellow:String = "🟨"
    alias Black:String = "⬛"
    alias Blue:String = "🟦"
    alias Purple: String = "🟪"
    alias White:String = "⬜"
    alias Orange: String = "🟧"
    alias Brown:String= "🟫"


struct Arrow:
    alias Up: String = "⬆️"
    alias Down:String = "⬇️"
    alias Left:String = "⬅️"
    alias Right:String = "➡️"

@value
struct Position:
    var x:Int
    var y:Int

#Todo: parameter of type GuiConfig {non_blocking:Bool = False, more}
@value
struct Server[base_theme:String="theme.css", exit_if_request_not_from_localhost:Bool = True]:
    alias Circle = Circles
    alias Square = Squares
    alias Arrow = Arrow
    alias Accessibility = Accessibility

    var server: PythonObject
    var client: PythonObject
    var response: PythonObject
    var request: PythonObject
    var data: String
    var send_response : Bool
    var request_interval_second: Float64
    var base_styles: String
    var base_js: String
    
    fn __init__(inout self) raises:
        try:
            with open(self.base_theme,"r") as f:
                self.base_styles = f.read()
        except e:
            print("Error importing theme.css: " + str(e))
            self.base_styles = ""
            raise(e)
        try:
            with open("base.js","r") as f:
                self.base_js = f.read()
        except e:
            print("Error importing base.js: " + str(e))
            self.base_js = ""
            raise(e)       
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
        #self.server.setblocking(0) #Blocking by default
        self.server.listen(1)
        print("http://"+str(host)+":"+port)
    fn __del__(owned self):
        try: self.server.close() except e: print(e)
    
    fn Event(inout self) -> Bool: 
        
        if self.send_response == True: #non blocking loop, if previous iteration generated response, do send
            try:
                self.response+="</body></html>"
                self.client[0].sendall(self.response.encode())
                self.client[0].close()
            except e: print(e)
        try:
            self.response = PythonObject('HTTP/1.0 200 OK\n\n')
            self.response += "<html  ondrop='drop(event)' ondragover='preventDefaults(event)'><head><script>"+self.base_js+"</script><style>"+self.base_styles+"</style><meta charset='UTF-8'></head><body>"
        except e: print(e)    
        try: #if error is raised in the block, no request or an error
            self.client = self.server.accept()
            @parameter
            if exit_if_request_not_from_localhost:
                if self.client[1][0] != '127.0.0.1': 
                    print("Exit, request from: "+str(self.client[1][0]))
                    return False
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
    
    def Button(inout self,txt:String,CSS:String="") ->Bool:
        self.response = str(self.response)+"<div data-click='true' class='Button_' style='"+CSS+"' id='"+txt+"'"+">" + txt + "</div>"
        if self.request and self.request[1] == "/click_"+txt:
            self.SetNoneRequest()
            return True
        return False
    
    def Toggle(inout self,inout val:Bool,label:String):
        var val_repr = "ToggleOff_"
        var id:String = self._ID(val)
        if self.request and self.request[1] == "/click_"+id:
            val = not val
            self.SetNoneRequest()

        if val: val_repr = "ToggleOn_"
        self.response = str(self.response)+"<div data-click='true' class='"+val_repr+"' id='"+id+"'"+">"+label+ "</div>"

    fn Text(inout self:Self, txt:String):
        try:
            self.response = str(self.response)+"<div class='Text_'>"+txt+"</div>" 
        except e: print(e)
  
    def Window(inout self, name: String,inout pos:Position,CSSTitle:String="")->Window:
        let ptr:Pointer[PythonObject] = __get_lvalue_as_address(self.request)
        return Window(__get_lvalue_as_address(self.response), name,__get_lvalue_as_address(pos),ptr,CSSTitle)

    def Slider(inout self,label:String,inout val:Int, min:Int = 0, max:Int = 100,CSSLabel:String="",CSSBox:String="")->Bool:
        #Todo: if new_value > max: new_value = max, check if min<max 
        var id:String = self._ID(val)
        var retval = False
        if self.request and self.request[1].startswith("/change_"+id):
            val = atol(str(self.request[1].split("/")[2])) #split by "/change_"+id ?
            self.SetNoneRequest()
            retval=True
        self.response = str(self.response)+"<div class='SliderBox_' style='"+CSSBox+"'><div><span class='SliderLabel_' style='"+CSSLabel+"'>"+label+"</span> "+str(val)+"</div>"
        self.response = str(self.response)+"<input data-change='true' type='range' min='"+min+"' max='"+max+"' value='"+str(val)+"' style='max-width: fit-content;' id='"+id+"'>"
        self.response = str(self.response)+"</div>"
        return retval

    fn TextInput[maxlength:Int=32](inout self,label:String,inout val:String,CSSBox:String=""):
        try:
            var id:String = self._ID(val)
            var tmp2 = "/change_"+id+"/"
            if self.request and self.request[1] == tmp2:
                val = "" #empty
                self.SetNoneRequest()
            else:
                if self.request and self.request[1].startswith(tmp2):  
                    var tmp3 = str(self.request[1].split(tmp2)[1]).split("-") 
                    var tmp4 = String("")
                    for i in range(len(tmp3)):
                        tmp4+=chr(atol(tmp3[i]))
                    val = tmp4
                    self.SetNoneRequest()
            
            self.response = str(self.response)+"<div class='TextInputBox_' style='"+CSSBox+"'>"
            if label!="":
                self.response = str(self.response)+"<span>"+label+"</span>"
            self.response = str(self.response)+"<input maxlength='"+str(maxlength)+"' class='TextInputElement_' data-textinput='true' value='"+val+"' type='text' id='"+id+"'>"
            self.response = str(self.response)+"</div>"
        except e: print("Error TextInput widget: "+ str(e))
        
    def ComboBox(inout self,label:String,values:DynamicVector[String],inout selection:Int):
        var id:String = self._ID(selection)
        var tmp2 = "/combobox_"+id+"/"
        if self.request and self.request[1].startswith(tmp2):    
            selection = atol(str(self.request[1].split(tmp2)[1]))
            self.SetNoneRequest()
        

        self.response = str(self.response)+"<div class='ComboBox_' style=''>"
        self.response = str(self.response)+"<span>"+label+" </span>"
        self.response = str(self.response)+"<select data-combobox='true' class='ComboBoxSelect_' id='" +id+"'>"
        for s in range(len(values)):
            var selected:String = ""
            if s == selection : selected = "selected"
            self.response +=  "<option "+ selected +" value='" + values[s] +"'>"+values[s]+"</option>"
        self.response += "</select>"
        self.response = str(self.response)+"</div>"
    
    def ComboBox(inout self,label:String,inout selection:Int,*selections:StringLiteral):
        var id:String = self._ID(selection)
        var tmp2 = "/combobox_"+id+"/"
        if self.request and self.request[1].startswith(tmp2):    
            selection = atol(str(self.request[1].split(tmp2)[1]))
            self.SetNoneRequest()
        

        self.response = str(self.response)+"<div class='ComboBox_'>"
        self.response = str(self.response)+"<span>"+label+" </span>"
        self.response = str(self.response)+"<select data-combobox='true' class='ComboBoxSelect_' id='" +id+"'>"
        for s in range(len(selections)):
            var selected:String = ""
            if s == selection : selected = "selected"
            self.response +=  "<option "+ selected +" value='" + selections[s] +"'>"+selections[s]+"</option>"
        self.response += "</select>"
        self.response = str(self.response)+"</div>"

    def TextChoice(inout self, label:String,inout selected: String, *selections:StringLiteral):
        var id:String = self._ID(selected)
        var tmp2 = "/text_choice/"+id+"/"
        if self.request and self.request[1].startswith(tmp2): 
            try:
                result = atol(str(self.request[1].split(tmp2)[1]))
                if result >= len(selections): raise Error("Selected index >= len(selections)")
                selected = String(selections[result])
                self.SetNoneRequest()
            except e: print("Error TextChoice widget: "+str(e))

        self.response+="""
            <fieldset class='TextChoiceFieldset_'>
            <legend class='TextChoiceLegend_'>""" + label + "</legend>"
        for i in range(len(selections)):
            var current = str(selections[i])
            var url = "/text_choice/"+id+"/"+str(i)
            if current == selected:
                self.response+= "<span id='0' data-textchoice='"+url+"'>▪️<b>" + (current)+'</b></span><br>'
            else:
                self.response+= "<span id='0' data-textchoice='"+url+"'>▪️" + (current)+'</span><br>'
        self.response += "</fieldset>"

    def Bold(inout self, t:String)->String: return "<b>"+t+"</b>"
    def Highlight(inout self, t:String)->String: return "<mark>"+t+"</mark>"
    def Small(inout self, t:String)->String: return "<small>"+t+"</small>"
    def Ticker(inout self,t:String,width:Int=200):
        self.response+="<div class='Ticker_' style='width:"+str(width)+"px'><marquee>"+t+"</marquee></div>"
    def Digitize(inout self, number: Int)->String :
        var digits = StaticTuple[10,StringLiteral]("0️⃣","1️⃣","2️⃣","3️⃣","4️⃣","5️⃣","6️⃣","7️⃣","8️⃣","9️⃣")
        tmp = str(number)
        var res:String = ""
        for i in range(len(tmp)):
            res+=digits[(ord(tmp[i])-48)]
        return(res)

    def Collapsible(inout self,title:String,CSS:String="")->Collapsible: return Collapsible(title,__get_lvalue_as_address(self.response),CSS)
    def Table(inout self)->WithTag: return WithTag(__get_lvalue_as_address(self.response),"table","margin:4px;border:1px solid black;")
    def Row(inout self)->WithTag: return WithTag(__get_lvalue_as_address(self.response),"tr","border:1px solid black;") 
    def Cell(inout self)->WithTag: return WithTag(__get_lvalue_as_address(self.response),"td","border:1px solid black;") 
    def ScrollableArea(inout self,height:Int=128)->ScrollableArea: return ScrollableArea(__get_lvalue_as_address(self.response),height)
    
    def ColorSelector(inout self, inout arg:String):
        var id:String = self._ID(arg)
        var tmp3 = "/colorselector_"+id+"/"
        if self.request and self.request[1].startswith(tmp3): 
            try:
                result = "#"+str(self.request[1].split(tmp3)[1])
                arg=result
                self.SetNoneRequest()
            except e: print("Error ColorSelector widget: "+str(e))
        self.response += "<input class='ColorSelector_' data-colorselector='true' type='color' id='"+id+"' value='"+arg+"'>" 
    
    #⚠️ not sure at all about the date format (see readme.md)
    def DateSelector(inout self, inout arg:String):
        var id = self._ID(arg)
        var tmp3 = "/dateselector_"+id+"/"
        if self.request and self.request[1].startswith(tmp3): 
            try:
                result = str(self.request[1].split(tmp3)[1])
                arg=result
                self.SetNoneRequest()
            except e: print("Error ColorSelector widget: "+str(e))
        self.response += "<input class='DateSelector_' data-dateselector='true' type='date' id='"+id+"' value='"+arg+"'>" 
    def NewLine(inout self): self.response+="</br>"
    fn _ID[T:AnyRegType](inout self,inout arg:T)->String:
        var tmp:Pointer[T] = __get_lvalue_as_address(arg)
        var tmp2:Int = tmp.__as_index()
        var id:String = str(tmp2)
        return id
    fn Tag(inout self,tag:String,style:String="")->WithTag:
        return WithTag(__get_lvalue_as_address(self.response),tag,style)

@value
struct ScrollableArea:
    var reponse: Pointer[PythonObject]
    var height: Int
    fn __enter__(self):
        try:
            __get_address_as_lvalue(self.reponse.address) += "<div class='ScrollableArea_' style='height:"+str(self.height)+"px;'>"
        except e: print("Error ScrollableArea __enter__ widget:"+str(e))
    fn __exit__( self): self.close()
    fn close(self) -> Bool:
        try:
            __get_address_as_lvalue(self.reponse.address) += "</div>"
        except e: print("Error ScrollableArea() widget:"+str(e)) 
        return True
    fn __exit__( self, err:Error)->Bool: return self.close()
@value
struct Collapsible:
    var title: String
    var reponse: Pointer[PythonObject]
    var CSS: String
    fn __enter__(self):
        try:
            __get_address_as_lvalue(self.reponse.address) += "<details><summary class='Collapsible_' style='"+self.CSS+"'>"+self.title+"</summary>"
        except e: print("Window __enter__ widget:"+str(e))
    fn __exit__( self): self.close()
    fn close(self) -> Bool:
        try:
            __get_address_as_lvalue(self.reponse.address) += "</details>"
        except e: print("Error Collapsible() widget:"+str(e)) 
        return True
    fn __exit__( self, err:Error)->Bool: return self.close()

@value
struct WithTag:
    var data: Pointer[PythonObject]
    var tag:String
    var style:String
    fn __enter__(self):
        try : __get_address_as_lvalue(self.data.address) += "<"+self.tag+" style='" + self.style + "'>"
        except e: print(e)
    fn __exit__( self): self.close()
    fn __exit__( self, err:Error)->Bool: 
        self.close()
        print(err)
        return False
    fn close(self):
        try : __get_address_as_lvalue(self.data.address) += "</"+self.tag+">"
        except e: print(e)

@value
struct Window:
    var content: Pointer[PythonObject]
    var name: String
    var pos: Pointer[Position]
    var request: Pointer[PythonObject]
    var titlecss: String
    fn __enter__(self):
        try:
            var id = str(self.pos.__as_index())#str(hash(self.name._as_ptr(),len(self.name)))
            var positions:String = ""
            var req = __get_address_as_lvalue(self.request.address)
            if req and req[1].startswith("/window_"+id): 
                var val = req[1].split("/window_"+id)[1].split("/")
                __get_address_as_lvalue(self.pos.address).x += atol(str(val[1])) #todo try: block for atol
                __get_address_as_lvalue(self.pos.address).y += atol(str(val[2]))
                __get_address_as_lvalue(self.request.address) = PythonObject(None) #possibly not good
            positions += "left:"+str(__get_address_as_lvalue(self.pos.address).x)+"px;"
            positions += "top:"+str(__get_address_as_lvalue(self.pos.address).y)+"px;"
            __get_address_as_lvalue(self.content.address) += "<div draggable='true' ondragstart='drag(event)' class='Window_' style='" +positions+ ";' id='"+id +"'>"
            __get_address_as_lvalue(self.content.address) += "<div class='WindowTitle_' style='"+self.titlecss+"'>➖ ❌ " + self.name + "&nbsp;</div>"
            __get_address_as_lvalue(self.content.address) += "<div class='WindowContent_' style=''>"
        except e: print("Window __enter__ widget:"+str(e))
    fn __exit__( self): self.close()
    fn close(self) -> Bool:
        try:
            __get_address_as_lvalue(self.content.address) += "</div></div>"
        except e: print("Window close() widget:"+str(e)) 
        return True
    fn __exit__( self, err:Error)->Bool: return self.close()


def main():
    #⚠️ see readme.md in order to be aware about challenges and limitations!
    val = 50
    txt = String("Naïve UTF8 🥳")
    boolval = True
    multichoicevalue = String("First")
    colorvalue = String("#1C71D8")
    datevalue = String("2024-01-01")

    GUI = Server() #Server[base_theme="theme_neutral.css"]()
    
    POS = Position(1,1)
    POS2 = Position(1,350)
    POS3 = Position(32,512)
    POS4 = Position(512,16)

    combovalues = DynamicVector[String]()
    for i in range(5): combovalues.push_back("Value "+str(i))
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
