from sys import param_env
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
    var scale:Float64
    fn __init__(inout self,x:Int,y:Int,scale:Float64=1.0):
        self.x =x
        self.y =y
        self.scale = scale

@value
struct Server[base_theme:StringLiteral=param_env.env_get_string["mojo_ui_html_theme","theme.css"](), exit_if_request_not_from_localhost:Bool = True]:
    alias Circle = Circles
    alias Square = Squares
    alias Arrow = Arrow
    alias Accessibility = Accessibility

    var server: PythonObject
    var client: PythonObject
    var response: PythonObject
    var request: PythonObject

    var last_rendition: String
    var total_renditions: Int
    var re_render_current: Bool

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
        
        self.last_rendition = " "
        self.re_render_current=False
        self.total_renditions = 0
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
    
    fn _response_init(inout self):
        try:
            self.response = PythonObject('HTTP/1.0 200 OK\n\n')
            self.response += "<html  ondrop='drop(event)' ondragover='preventDefaults(event)'><head><link rel='icon' href='data:;base64,='><script>"+self.base_js+"</script><style>"+self.base_styles+"</style><meta charset='UTF-8'></head><body>"
        except e: print("error, _reponse_init:"+str(e))
    def should_re_render(inout self): self.re_render_current = True
    
    fn Event(inout self) -> Bool: 

        if self.send_response == True: 
            self.total_renditions+=1
            var current_rendition:String=" "
            try:
                current_rendition = str(self.response.encode())
                var different = False
                if len(current_rendition)!=len(self.last_rendition): 
                    different=True
                else:
                    for c in range(len(current_rendition)):
                        if current_rendition[c] != self.last_rendition[c]: different = True
                
                if self.re_render_current:
                    different=True
                    self.re_render_current=False
                
                if self.total_renditions >10:
                    different=False
                
                if different:
                    self.last_rendition = current_rendition
                    self._response_init()
                    self.send_response=True
                    # need counter to stop the loop after 
                    return True
                else:
                    self.response += "<div class='rendition_box' id='_rendition_status'>"+str(self.total_renditions)+"</div>"
                    self.response+= "</body></html>"
                    self.client[0].sendall(self.response.encode())
                    self.client[0].close()
                    self.send_response=False
                    self.last_rendition = current_rendition
                    
            except e: print(e)
            

        try: #if error is raised in the block, no request or an error
            self.client = self.server.accept()
            self.total_renditions = 0
            self._response_init()
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
            print(e)
            self.send_response=False 
        if self.request_interval_second != 0: sleep(self.request_interval_second)
        return True #todo: should return self.Running: bool to exit the loop
    
    def SetNoneRequest(inout self):
        self.request = PythonObject(None)
    
    def Button(inout self,txt:String,CSS:String="") ->Bool:
        var id:String = ""
        var ptr = txt._as_ptr().bitcast[DType.uint8]()
        for c in range(len(txt)):
            id+=str(ptr[c])
            id+="-"
        _=txt
        self.response = str(self.response)+"<div data-click='true' class='Button_' style='"+CSS+"' id='"+id+"'"+">" + txt + "</div>"
        if self.request and self.request[1] == "/click_"+id:
            self.should_re_render()
            self.SetNoneRequest()
            return True
        return False
    
    def Toggle(inout self,inout val:Bool,label:String)->Bool:
        var res:Bool = False
        var val_repr = "ToggleOff_"
        var id:String = self._ID(val)
        if self.request and self.request[1] == "/click_"+id:
            val = not val
            self.should_re_render()
            self.SetNoneRequest()
            res = True

        if val: val_repr = "ToggleOn_"
        self.response = str(self.response)+"<div data-click='true' class='"+val_repr+"' id='"+id+"'"+">"+label+ "</div>"
        return res

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
            self.should_re_render()
            retval=True
        self.response = str(self.response)+"<div class='SliderBox_' style='"+CSSBox+"'><div><span class='SliderLabel_' style='"+CSSLabel+"'>"+label+"</span> "+str(val)+"</div>"
        self.response = str(self.response)+"<input data-change='true' type='range' min='"+min+"' max='"+max+"' value='"+str(val)+"' style='max-width: fit-content;' id='"+id+"'>"
        self.response = str(self.response)+"</div>"
        return retval

    fn TextInput[maxlength:Int=32](inout self,label:String,inout val:String,CSSBox:String="")->Bool:
        var ret_val = False
        try:
            var id:String = self._ID(val)
            var tmp2 = "/change_"+id+"/"
            if self.request and self.request[1] == tmp2:
                val = "" #empty
                self.should_re_render()
                self.SetNoneRequest()
                ret_val = True
            else:
                if self.request and self.request[1].startswith(tmp2):  
                    var tmp3 = str(self.request[1].split(tmp2)[1]).split("-") 
                    var tmp4 = String("")
                    for i in range(len(tmp3)):
                        tmp4+=chr(atol(tmp3[i]))
                    val = tmp4
                    self.should_re_render()
                    self.SetNoneRequest()
                    ret_val = True
            
            self.response = str(self.response)+"<div class='TextInputBox_' style='"+CSSBox+"'>"
            if label!="":
                self.response = str(self.response)+"<span>"+label+"</span>"
            self.response = str(self.response)+"<input maxlength='"+str(maxlength)+"' class='TextInputElement_' data-textinput='true' value='"+val+"' type='text' id='"+id+"'>"
            self.response = str(self.response)+"</div>"
        except e: print("Error TextInput widget: "+ str(e))
        return ret_val
        
    def ComboBox(inout self,label:String,values:DynamicVector[String],inout selection:Int)->Bool:
        var ret_val = False
        var id:String = self._ID(selection)
        var tmp2 = "/combobox_"+id+"/"
        if self.request and self.request[1].startswith(tmp2):    
            selection = atol(str(self.request[1].split(tmp2)[1]))
            self.should_re_render()
            self.SetNoneRequest()
            ret_val = True
        

        self.response = str(self.response)+"<div class='ComboBox_' style=''>"
        self.response = str(self.response)+"<span>"+label+" </span>"
        self.response = str(self.response)+"<select data-combobox='true' class='ComboBoxSelect_' id='" +id+"'>"
        for s in range(len(values)):
            var selected:String = ""
            if s == selection : selected = "selected"
            self.response +=  "<option "+ selected +" value='" + values[s] +"'>"+values[s]+"</option>"
        self.response += "</select>"
        self.response = str(self.response)+"</div>"
        return ret_val
    
    def ComboBox(inout self,label:String,inout selection:Int,*selections:StringLiteral)->Bool:
        var ret_val = False
        var id:String = self._ID(selection)
        var tmp2 = "/combobox_"+id+"/"
        if self.request and self.request[1].startswith(tmp2):    
            selection = atol(str(self.request[1].split(tmp2)[1]))
            self.should_re_render()
            self.SetNoneRequest()
            ret_val = True
        

        self.response = str(self.response)+"<div class='ComboBox_'>"
        self.response = str(self.response)+"<span>"+label+" </span>"
        self.response = str(self.response)+"<select data-combobox='true' class='ComboBoxSelect_' id='" +id+"'>"
        for s in range(len(selections)):
            var selected:String = ""
            if s == selection : selected = "selected"
            self.response +=  "<option "+ selected +" value='" + selections[s] +"'>"+selections[s]+"</option>"
        self.response += "</select>"
        self.response = str(self.response)+"</div>"
        return ret_val

    def TextChoice(inout self, label:String,inout selected: String, *selections:StringLiteral):
        var id:String = self._ID(selected)
        var tmp2 = "/text_choice/"+id+"/"
        if self.request and self.request[1].startswith(tmp2): 
            try:
                result = atol(str(self.request[1].split(tmp2)[1]))
                if result >= len(selections): raise Error("Selected index >= len(selections)")
                selected = String(selections[result])
                self.should_re_render()
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
    def _Ticker(inout self,t:String)->String:
        return "<marquee>"+t+"</marquee>"
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
    def Table(inout self)->WithTag: return WithTag(__get_lvalue_as_address(self.response),"table","margin:4px;border:1px solid black;"," ")
    def Row(inout self)->WithTag: return WithTag(__get_lvalue_as_address(self.response),"tr","border:1px solid black;"," ") 
    def Cell(inout self)->WithTag: return WithTag(__get_lvalue_as_address(self.response),"td","border:1px solid black;"," ") 
    def ScrollableArea(inout self,height:Int=128)->ScrollableArea: return ScrollableArea(__get_lvalue_as_address(self.response),height)
    
    def ColorSelector(inout self, inout arg:String)->Bool:
        var ret_val = False
        var id:String = self._ID(arg)
        var tmp3 = "/colorselector_"+id+"/"
        if self.request and self.request[1].startswith(tmp3): 
            try:
                result = "#"+str(self.request[1].split(tmp3)[1])
                arg=result
                self.should_re_render()
                self.SetNoneRequest()
                ret_val = True
            except e: print("Error ColorSelector widget: "+str(e))
        self.response += "<input class='ColorSelector_' data-colorselector='true' type='color' id='"+id+"' value='"+arg+"'>" 
        return ret_val
        
    def TimeSelector(inout self, inout arg:String)->Bool:
        var ret_val = False
        var id = self._ID(arg)
        var tmp3 = "/timeselector_"+id+"/"
        if self.request and self.request[1].startswith(tmp3): 
            try:
                result = str(self.request[1].split(tmp3)[1])
                arg=result
                self.should_re_render()
                self.SetNoneRequest()
                ret_val = True
            except e: print("Error TimeSelector widget: "+str(e))
        
        self.response += "<input class='DateSelector_' data-callbackurl='"+tmp3+"' type='time' id='"+id+"' value='"+arg+"' onblur='send_element_value(event)'>" 
        return ret_val

    #⚠️ not sure at all about the date format (see readme.md)
    def DateSelector(inout self, inout arg:String)->Bool:
        var ret_val = False
        var id = self._ID(arg)
        var tmp3 = "/dateselector_"+id+"/"
        if self.request and self.request[1].startswith(tmp3): 
            try:
                result = str(self.request[1].split(tmp3)[1])
                arg=result
                self.should_re_render()
                self.SetNoneRequest()
                ret_val = True
            except e: print("Error DateSelector widget: "+str(e))
        self.response += "<input class='DateSelector_' data-dateselector='true' type='date' id='"+id+"' value='"+arg+"'>" 
        return ret_val
    def NewLine(inout self): self.response+="</br>"
    fn _ID[T:AnyRegType](inout self,inout arg:T)->String:
        var tmp:Pointer[T] = __get_lvalue_as_address(arg)
        var tmp2:Int = tmp.__as_index()
        var id:String = str(tmp2)
        return id
    fn Tag(inout self,tag:String,style:String="",_additional_attributes:String=" ")->WithTag:
        return WithTag(__get_lvalue_as_address(self.response),tag,style,_additional_attributes)

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
    var _additional_attributes:String
    fn __enter__(self):
        try : __get_address_as_lvalue(self.data.address) += "<"+self.tag+" "+self._additional_attributes+" style='" + self.style + "'>"
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
            
            if req and req[1].startswith("/window_scale_"+id): 
                var val = req[1].split("/window_scale_"+id)[1].split("/")
                if val[1] == "1":
                    __get_address_as_lvalue(self.pos.address).scale+=0.1
                else:
                    if __get_address_as_lvalue(self.pos.address).scale >=0.2:
                        __get_address_as_lvalue(self.pos.address).scale-=0.1
                __get_address_as_lvalue(self.request.address) = PythonObject(None) #possibly not good
            else:
                if req and req[1].startswith("/window_"+id): 
                    var val = req[1].split("/window_"+id)[1].split("/")
                    __get_address_as_lvalue(self.pos.address).x += atol(str(val[1])) #todo try: block for atol
                    __get_address_as_lvalue(self.pos.address).y += atol(str(val[2]))
                    __get_address_as_lvalue(self.request.address) = PythonObject(None) #possibly not good
            positions += "left:"+str(__get_address_as_lvalue(self.pos.address).x)+"px;"
            positions += "top:"+str(__get_address_as_lvalue(self.pos.address).y)+"px;"
            var scale:String = str(__get_address_as_lvalue(self.pos.address).scale)
            __get_address_as_lvalue(self.content.address) += "<div  ondragstart='drag(event)' class='Window_' style='transform-origin: 0% 0% 0px;transform:scale("+scale+");" +positions+ ";' id='"+id +"'>"
            __get_address_as_lvalue(self.content.address) += "<div data-zoomlevel='1.O' onwheel='zoom_window(event)' onmouseover='DragOn(event)'  onmouseout='DragOff(event)' data-istitlebar='true' class='WindowTitle_' style='cursor:grab;"+self.titlecss+"'>➖ ❌ " + self.name + "&nbsp;</div>"
            __get_address_as_lvalue(self.content.address) += "<div class='WindowContent_' style=''>"
        except e: print("Window __enter__ widget:"+str(e))
    fn __exit__( self): self.close()
    fn close(self) -> Bool:
        try:
            __get_address_as_lvalue(self.content.address) += "</div></div>"
        except e: print("Window close() widget:"+str(e)) 
        return True
    fn __exit__( self, err:Error)->Bool: return self.close()