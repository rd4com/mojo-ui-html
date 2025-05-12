from sys import param_env
from python import Python, PythonObject
from time import sleep
from utils.variant import Variant
from collections import Optional
from memory import UnsafePointer

# todo: switch between two response buffer, only set size to 0 but capacity is always huge

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
    var opened:Bool
    fn __init__(out self,x:Int,y:Int,scale:Float64=1.0):
        self.x =x
        self.y =y
        self.scale = scale
        self.opened = True

@value
struct Server:
    alias exit_if_request_not_from_localhost = param_env.env_get_bool[
        "exit_if_request_not_from_localhost", True
    ]()
    alias base_theme = param_env.env_get_string[
        "mojo_ui_html_theme","theme.css"
    ]()

    alias Circle = Circles
    alias Square = Squares
    alias Arrow = Arrow
    alias Accessibility = Accessibility

    var server: PythonObject
    var client: PythonObject
    var response: String
    var request: List[String]

    var last_rendition: String
    var total_renditions: Int
    var re_render_current: Bool

    var send_response : Bool
    var request_interval_second: Float64
    var keyboard_handler:Bool
    var base_styles: String
    var base_js: String
    var keyboard_handler_js: String

    alias initial_capacity = 1<<15



    fn __init__(out self):
        try:
            with open(Self.base_theme,"r") as f:
                self.base_styles = f.read()
        except e:
            print("Error importing theme.css: " + String(e))
            self.base_styles = ""
        try:
            with open("base.js","r") as f:
                self.base_js = f.read()
        except e:
            print("Error importing base.js: " + String(e))
            self.base_js = ""
        try:
            with open("keyboard_handler.js","r") as f:
                self.keyboard_handler_js = f.read()
        except e:
            print("Error importing keyboard_handler.js: " + String(e))
            self.keyboard_handler_js = ""

        self.server  = PythonObject(None)
        self.client = PythonObject(None)
        self.response = String(capacity = Self.initial_capacity)
        self.request = List[String]()


        self.last_rendition = " "
        self.re_render_current=False
        self.total_renditions = 0
        self.send_response=False
        self.request_interval_second=0.1
        self.keyboard_handler=False
        try:
            self.start()
        except e:
            print(e)

    def start(mut self, host:String = "127.0.0.1", port:Int = 8000):
        var socket = Python.import_module("socket")
        var tmp = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server = tmp
        self.server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.server.bind(Python.tuple(host, port))
        #self.server.setblocking(0) #Blocking by default
        self.server.listen(1)
        print("http://"+String(host)+":"+String(port))

    fn __del__(owned self):
        try:
            self.server.close()
        except e: print(e)

    fn _response_init(mut self):
        # self.response = String(capacity=32768*64)
        self.response = String()
        self.response += 'HTTP/1.0 200 OK\n\n'
        if not self.keyboard_handler:
            self.keyboard_handler_js = ""
        self.response += "<html  ondrop='drop(event)' ondragover='preventDefaults(event)'><head><link rel='icon' href='data:;base64,='><script>"+self.base_js+self.keyboard_handler_js+"</script><style>"+self.base_styles+"</style><meta charset='UTF-8'></head><body>"

    fn should_re_render(mut self): self.re_render_current = True

    fn Span(mut self, arg:String):
        self.RawHtml("<span>"+arg+"</span")

    fn RawHtml(mut self,arg:String):
        self.response += arg

    fn AudioBase64Wav(mut self, b64wav:String):
        self.RawHtml("<audio loop style='width:100%;' controls='controls' autobuffer='autobuffer' autoplay='autoplay'>")
        self.RawHtml("<source src='data:audio/wav;base64,"+b64wav+"' />")
        self.RawHtml("</audio>")

    fn NeedNewRendition(mut self) -> Bool:
        var ref_c = Pointer(to=self.client)
        var ref_s = Pointer(to=self.server)
        if self.send_response == True:
            self.total_renditions+=1
            var current_rendition:String=" "
            try:
                current_rendition = self.response
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
                    #self.response += "<div class='rendition_box' id='_rendition_status'>"+str(self.total_renditions)+"</div>"
                    self.response+= "</body></html>"
                    ref_c[][0].sendall(PythonObject(self.response).encode())
                    ref_c[][0].close()
                    self.send_response=False
                    self.last_rendition = current_rendition

            except e: print(e)


        try: #if error is raised in the block, no request or an error
            #could do loop here
            ref_c[] = ref_s[].accept()
            self.total_renditions = 0

            self._response_init()

            @parameter
            if self.exit_if_request_not_from_localhost:
                if ref_c[][1][0] != '127.0.0.1':
                    print("Exit, request from: "+String(ref_c[][1][0]))
                    return False

            var tmp_ = String(ref_c[][0].recv(1024).decode())
            self.request = tmp_.split('\n')[0].split(" ")
            self.send_response=True
        except e:
            print(e)
            self.send_response=False
        if self.request_interval_second != 0: sleep(self.request_interval_second)

        return True #todo: should return self.Running: bool to exit the loop

    fn SetNoneRequest(mut self):
        self.request = List[String]()

    fn KeyDown(mut self)-> Variant[Int,String,NoneType]:
        if not self.keyboard_handler: return NoneType()
        # print(self.request.__repr__())
        try:
            if
                self.request and
                self.request[1].startswith("/keyboard/down/")
            :
                var tmp = self.request[1].split("/")
                if len(tmp)>=3:
                    if not String(tmp[3]).startswith("keydown-"):
                        var res = atol(String(tmp[3]))
                        self.SetNoneRequest()
                        return res
                    else:
                        var res = String(tmp[3]).split("keydown-")[1]
                        self.SetNoneRequest()
                        return res
        except e:
            print(e)
            return NoneType() #Int(0)
        return NoneType() #Int(0)


    def Button(mut self,txt:String,CSS:String="") ->Bool:
        var id:String = ""
        var ptr = txt.unsafe_ptr()
        for c in range(len(txt)):
            id+=String(ptr[c])
            id+="-"
        _=txt
        self.response += String("<div data-click='true' class='Button_' style='", CSS, "' id='", id, "'>", txt, "</div>")
        if self.request and self.request[1] == "/click_"+id:
            self.should_re_render()
            self.SetNoneRequest()
            return True
        return False

    def Toggle[L:MutableOrigin](mut self,ref[L]val:Bool,label:String)->Bool:
        var res:Bool = False
        var val_repr:String = "ToggleOff_"
        var id:String = String(self.ID(val))
        if self.request and self.request[1] == "/click_"+id:
            val = not val
            self.should_re_render()
            self.SetNoneRequest()
            res = True

        if val: val_repr = "ToggleOn_"
        self.response += String("<div data-click='true' class='", val_repr, "' id='", id, "'", ">", label, "</div>")
        return res

    fn Text(mut self:Self, txt:String):
        self.response += "<div class='Text_'>"+txt+"</div>"

    def Window(
        mut self,
        name: String,
        mut pos:Position,
        CSSTitle:String=""
    )->Window[__origin_of(self), __origin_of(pos)]:
        return Window[__origin_of(self), __origin_of(pos)](
            self,
            name,
            pos,
            CSSTitle
        )

    def Slider[L:MutableOrigin](mut self,label:String,ref[L]val:Int, min:Int = 0, max:Int = 100,CSSLabel:String="",CSSBox:String="")->Bool:
        #Todo: if new_value > max: new_value = max, check if min<max
        var id:String = String(self.ID(val))
        var retval = False
        if self.request and self.request[1].startswith("/change_"+id):
            val = atol(self.request[1].split("/")[2]) #split by "/change_"+id ?
            self.SetNoneRequest()
            self.should_re_render()
            retval=True
        self.response += String("<div class='SliderBox_' style='", CSSBox, "'><div><span class='SliderLabel_' style='", CSSLabel, "'>", label, "</span> ",String(val),"</div>")
        self.response += "<input data-change='true' type='range' min='"+String(min)+"' max='"+String(max)+"' value='"+String(val)+"' style='max-width: fit-content;' id='"+String(id)+"'>"
        self.response += "</div>"
        return retval

    fn ID[T:AnyType](mut self, ref[_]arg:T)->Int:
        return UnsafePointer(to=arg).__int__()

    fn TextInput[maxlength:Int=32](
        mut self,
        label:String,
        mut val:String,
        CSSBox:String="",
    )->Bool:
        var ret_val = False
        try:
            var id:String = String(self.ID(val))
            var tmp2 = "/change_"+id+"/"
            if self.request and self.request[1] == tmp2:
                val = "" #empty
                self.should_re_render()
                self.SetNoneRequest()
                ret_val = True
            else:
                if self.request and self.request[1].startswith(tmp2):
                    var tmp3 = self.request[1].split(tmp2)[1].split("-")
                    val = String()
                    for i in range(len(tmp3)):
                        val.append_byte(Int(tmp3[i]))
                    self.should_re_render()
                    self.SetNoneRequest()
                    ret_val = True

            self.response += "<div class='TextInputBox_' style='"+CSSBox+"'>"
            if label!="":
                self.response += "<span>"+label+"</span>"
            self.response += "<input maxlength='"+String(maxlength)+"' class='TextInputElement_' data-textinput='true' value='"+val+"' type='text' id='"+id+"'>"
            self.response += "</div>"
        except e: print("Error TextInput widget: "+ String(e))
        return ret_val

    def ComboBox[L:MutableOrigin](mut self,label:String,values:List[String],ref[L]selection:Int)->Bool:
        var ret_val = False
        var id:String = String(self.ID(selection))
        var tmp2 = "/combobox_"+id+"/"
        if self.request and self.request[1].startswith(tmp2):
            selection = atol(self.request[1].split(tmp2)[1])
            self.should_re_render()
            self.SetNoneRequest()
            ret_val = True


        self.response += "<div class='ComboBox_' style=''>"
        self.response += "<span>"+label+" </span>"
        self.response += "<select data-combobox='true' class='ComboBoxSelect_' id='" +id+"'>"
        for s in range(len(values)):
            var selected:String = ""
            if s == selection : selected = "selected"
            self.response +=  "<option "+ selected +" value='" + values[s] +"'>"+values[s]+"</option>"
        self.response += "</select>"
        self.response += "</div>"
        return ret_val

    def ComboBox[L:MutableOrigin](mut self,label:String,ref[L]selection:Int,*selections:String)->Bool:
        var ret_val = False
        var id:String = String(self.ID(selection))
        var tmp2 = "/combobox_"+id+"/"
        if self.request and self.request[1].startswith(tmp2):
            selection = atol(self.request[1].split(tmp2)[1])
            self.should_re_render()
            self.SetNoneRequest()
            ret_val = True


        self.response += "<div class='ComboBox_'>"
        self.response += "<span>"+label+" </span>"
        self.response += "<select data-combobox='true' class='ComboBoxSelect_' id='" +id+"'>"
        for s in range(len(selections)):
            var selected:String = ""
            if s == selection : selected = "selected"
            self.response +=  "<option "+ selected +" value='" + selections[s] +"'>"+selections[s]+"</option>"
        self.response += "</select>"
        self.response += "</div>"
        return ret_val

    def TextChoice[L:MutableOrigin](mut self, label:String,ref[L]selected: String, *selections:String):
        var id:String = String(self.ID(selected))
        var tmp2 = "/text_choice/"+id+"/"
        if self.request and self.request[1].startswith(tmp2):
            try:
                result = atol(self.request[1].split(tmp2)[1])
                if result >= len(selections):
                    raise Error("Selected index >= len(selections)")
                selected = String(selections[result])
                self.should_re_render()
                self.SetNoneRequest()

            except e: print("Error TextChoice widget: "+String(e))

        self.response+="""
            <fieldset class='TextChoiceFieldset_'>
            <legend class='TextChoiceLegend_'>""" + label + "</legend>"
        for i in range(len(selections)):
            var current = String(selections[i])
            var url = "/text_choice/"+id+"/"+String(i)
            if current == selected:
                self.response+= "<span id='0' data-textchoice='"+url+"'>▪️<b>" + (current)+'</b></span><br>'
            else:
                self.response+= "<span id='0' data-textchoice='"+url+"'>▪️" + (current)+'</span><br>'
        self.response += "</fieldset>"

    def Bold(mut self, t:String)->String: return "<b>"+t+"</b>"
    def Highlight(mut self, t:String)->String: return "<mark>"+t+"</mark>"
    def Small(mut self, t:String)->String: return "<small>"+t+"</small>"
    def _Ticker(mut self,t:String)->String:
        return "<marquee>"+t+"</marquee>"
    def Ticker(mut self,t:String,width:Int=200):
        self.response+="<div class='Ticker_' style='width:"+String(width)+"px'><marquee>"+t+"</marquee></div>"

    def Digitize(mut self, number: Int)->String :
        var digits = List[String]("0️⃣","1️⃣","2️⃣","3️⃣","4️⃣","5️⃣","6️⃣","7️⃣","8️⃣","9️⃣")
        tmp = String(number)
        var res:String = ""
        for i in range(len(tmp)):
            res+=digits[(ord(tmp[i])-48)]
        return(res)

    def Collapsible(mut self,title:String,CSS:String="")->Collapsible[__origin_of(self)]:
        return Collapsible(
            self,
            title,
            CSS
        )

    def Table[L:MutableOrigin](ref[L]self)->WithTag[L]:
        return WithTag(
            self,
            "table",
            "margin:4px;border:1px solid black;",
            " "
        )

    def Row[L:MutableOrigin](ref[L]self)->WithTag[L]:
        return WithTag(
            self,
            "tr",
            "border:1px solid black;",
            " "
        )

    def Cell[L:MutableOrigin](ref[L]self)->WithTag[L]:
        return WithTag(
            self,
            "td",
            "border:1px solid black;",
            " "
        )

    def ScrollableArea[L:MutableOrigin](ref[L]self,height:Int=128)->ScrollableArea[L]:
        return ScrollableArea(self,height)

    def ColorSelector(mut self, mut arg:String)->Bool:
        var ret_val = False
        var id:String = String(self.ID(arg))
        var tmp3 = "/colorselector_"+id+"/"
        if self.request and self.request[1].startswith(tmp3):
            try:
                result = "#"+String(self.request[1].split(tmp3)[1])
                arg=result
                self.should_re_render()
                self.SetNoneRequest()
                ret_val = True
            except e: print("Error ColorSelector widget: "+String(e))
        self.response += "<input class='ColorSelector_' data-colorselector='true' type='color' id='"+id+"' value='"+arg+"'>"
        return ret_val

    def TimeSelector(mut self, mut arg:String)->Bool:
        var ret_val = False
        var id = String(self.ID(arg))
        var tmp3 = "/timeselector_"+id+"/"
        if self.request and self.request[1].startswith(tmp3):
            try:
                result = self.request[1].split(tmp3)[1]
                arg=result
                self.should_re_render()
                self.SetNoneRequest()
                ret_val = True
            except e: print("Error TimeSelector widget: "+String(e))

        self.response += "<input class='DateSelector_' data-callbackurl='"+tmp3+"' type='time' id='"+id+"' value='"+arg+"' onblur='send_element_value(event)'>"
        return ret_val

    #⚠️ not sure at all about the date format (see readme.md)
    def DateSelector(mut self, mut arg:String)->Bool:
        var ret_val = False
        var id = String(self.ID(arg))
        var tmp3 = "/dateselector_"+id+"/"
        if self.request and self.request[1].startswith(tmp3):
            try:
                result = String(self.request[1].split(tmp3)[1])
                arg=result
                self.should_re_render()
                self.SetNoneRequest()
                ret_val = True
            except e: print("Error DateSelector widget: "+String(e))
        self.response += "<input class='DateSelector_' data-dateselector='true' type='date' id='"+id+"' value='"+arg+"'>"
        return ret_val
    def NewLine(mut self): self.response+="</br>"

    fn Tag[L:MutableOrigin](
        ref[L]self,
        tag:String,
        style:String="",
        _additional_attributes:String=" "
    ) -> WithTag[L] #) -> WithTag[MutableStaticLifetime]
        :
        return WithTag(
            self,
            tag,
            style,
            _additional_attributes
        )

    fn AudioBase64WavSpecial(mut self, id: Int, volume:Int, b64wav:String):
        self.RawHtml("<audio loop controls='controls' autobuffer='autobuffer' id='AudioPlayerSpecial"+String(id)+"' data-volume='"+String(volume)+"'>")
        self.RawHtml("<source src='data:audio/wav;base64,"+b64wav+"' />")
        self.RawHtml("</audio>")

    def CustomEvent(mut self,unique_name:String)->Optional[String]:
        var ret = Optional[String](None)
        if self.request and self.request[1].startswith("/custom_event_"+unique_name):
            ret = String(self.request[1].split("/")[2])
            self.SetNoneRequest()
            self.should_re_render()
            self.SetNoneRequest()

        return ret
    

    #TODO: add css, align, ..
    def HorizontalGrow(mut self)->WithTag[__origin_of(self)]:
        return WithTag(self, "div","display: flex;flex-direction: row;", "")
    def VerticalGrow(mut self)->WithTag[__origin_of(self)]:
        return WithTag(self, "div","display: flex;flex-direction: column;", "")

@value
struct ScrollableArea[L:MutableOrigin]:
    var server: Pointer[Server, L]
    var height: Int
    fn __init__(out self, ref[L]ui:Server, height: Int):
        self.server = Pointer(to=ui)
        self.height = height
    fn __enter__(self):
        self.server[].response += "<div class='ScrollableArea_' style='height:"+String(self.height)+"px;'>"

    fn __exit__( self): _=self.close()
    fn __exit__( self, err:Error)->Bool: return self.close()

    fn close(self) -> Bool:
        self.server[].response += "</div>"
        return True

@value
struct Collapsible[L:MutableOrigin]:
    var title: String
    var server: Pointer[Server, L]
    var CSS: String
    fn __init__(out self, ref[L]ui:Server, title:String, css:String):
        self.title = title
        self.CSS = css
        self.server = Pointer(to=ui)
    fn __enter__(self):
        self.server[].response += "<details><summary class='Collapsible_' style='"+self.CSS+"'>"+self.title+"</summary>"

    fn __exit__( self): _=self.close()
    fn __exit__( self, err:Error)->Bool: return self.close()

    fn close(self) -> Bool:
        self.server[].response += "</details>"
        return True


@value
struct WithTag[L:MutableOrigin]:
    var server: Pointer[Server, L]
    var tag:String
    var style:String
    var _additional_attributes:String
    fn __init__(out self, ref[L]ui: Server, tag: String, style:String,_additional_attributes:String):
        self.server = Pointer(to=ui)
        self.tag = tag
        self.style = style
        self._additional_attributes = _additional_attributes
    fn __enter__(self):
        self.server[].response += "<"+self.tag+" "+self._additional_attributes+" style='" + self.style + "'>"
    fn __exit__( self): self.close()
    fn __exit__( self, err:Error)->Bool:
        self.close()
        print(err)
        return False
    fn close(self):
        self.server[].response += "</"+self.tag+">"

@value
struct Window[
    L: MutableOrigin,
    LPOS: MutableOrigin,
]:
    var server: Pointer[Server, L]
    var name: String
    var pos: Pointer[Position, LPOS]
    var titlecss: String
    fn __init__(out self, ref[L]ui: Server, name:String,ref[LPOS] pos: Position,titlecss:String):
        self.server = Pointer(to=ui)
        self.name = name
        self.pos = Pointer(to=pos)
        self.titlecss = titlecss
    fn __enter__(self) -> Pointer[Position, LPOS]:
        try:
            var id = String(self.pos)#str(hash(self.name._as_ptr(),len(self.name)))
            var positions:String = ""
            var req = self.server[].request

            if req and req[1].startswith("/window_scale_"+id):
                var val = req[1].split("/window_scale_"+id)[1].split("/")
                if val[1] == "1":
                    self.pos[].scale+=0.1
                else:
                    if self.pos[].scale >=0.2:
                        self.pos[].scale-=0.1
                self.server[].request = List[String]()
            elif req and req[1].startswith("/window_"+id):
                    var val = req[1].split("/window_"+id)[1].split("/")
                    self.pos[].x += atol(String(val[1])) #todo try: block for atol
                    self.pos[].y += atol(String(val[2]))
                    self.server[].request = List[String]()
            elif req and req[1].startswith("/click_/window_toggle_"+id):
                self.pos[].opened = not self.pos[].opened
                self.server[].request = List[String]()
            positions += "left:"+String(self.pos[].x)+"px;"
            positions += "top:"+String(self.pos[].y)+"px;"
            var scale:String = String(self.pos[].scale)
            self.server[].response += "<div  ondragstart='drag(event)' class='Window_' style='transform-origin: 0% 0% 0px;transform:scale("+scale+");" +positions+ ";' id='"+id +"'>"
            self.server[].response += "<div data-zoomlevel='1.O' onwheel='zoom_window(event)' onmouseover='DragOn(event)'  onmouseout='DragOff(event)' data-istitlebar='true' class='WindowTitle_' style='cursor:grab;"+self.titlecss+"'><span data-click='true' style='cursor:s-resize;' id='/window_toggle_"+String(id)+"'>➖</span> ❌ " + self.name + "&nbsp;</div>"
            var opened = String(" ")
            if not self.pos[].opened: opened = "hidden"
            self.server[].response += "<div class='WindowContent_' style='' "+opened+">"
        except e: print("Window __enter__ widget:"+String(e))
        return self.pos
    fn __exit__( self): _=self.close()
    fn close(self) -> Bool:
        self.server[].response += "</div></div>"
        return True
    fn __exit__( self, err:Error)->Bool: return self.close()

alias CSS_T=Variant[String,Int]
fn CSS(**kwargs: CSS_T) -> String:
    var res:String =";"
    try:
        for i in kwargs:
            var kw=i[]
            if kwargs[kw].isa[String]():
                res+= kw+":"
                res+= String(kwargs[kw].take[String]()) +";"
            if kwargs[kw].isa[Int]():
                res+= kw+":"
                res+= String(kwargs[kw].take[Int]()) +";"
    except e: print("CSS function"+String(e))
    return res
