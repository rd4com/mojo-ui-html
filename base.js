function plot_click(event, event_name){
    var x = event.clientX;
    event_and_refresh("/custom_event_"+event_name+"/L"+x)
}
function plot_click2(event, event_name){
    event.preventDefault()
    var x = event.clientX;
    event_and_refresh("/custom_event_"+event_name+"/R"+x)
}
window.onload = function () {
    window.scrollTo(0,localStorage.getItem("scrollpos"))
    // var elements = []
    // var min_volume = 1.0/16.0
    // for (let i = 0; i < 16; i++) {
    //     var tmp_element = document.getElementById("AudioPlayerSpecial"+i);
    //     if ( tmp_element != null && typeof tmp_element !== "undefined"){
    //         tmp_element.volume = min_volume*parseFloat(tmp_element.dataset.volume)
    //         elements.push(tmp_element)
    //     }
    // }
    // for (var i=0; i<elements.length; i++) {
    //     elements[i].play();
    // }
};

['click','input','change'].forEach(function(evt) {
    document.addEventListener(evt, function (event) {         
        var id = event.target.getAttribute('id'); 
        if (id){
            if (evt == "click") {
                if (event.target.dataset.click == "true"){
                    //new_xhr("/"+evt+"_"+id,false)
                    //window.location.href = "/"+evt+"_"+id
                    event_and_refresh("/"+evt+"_"+id)
                    //window.location.href="/"
                }
                if (event.target.dataset.hasOwnProperty('textchoice')){
                    event_and_refresh(event.target.dataset.textchoice)
                } 
            }
            if (evt == "change") {
                if (event.target.dataset.textinput == "true"){
                    const encoder = new TextEncoder();
                    const utf8 = encoder.encode(event.target.value);
                    event_and_refresh("/"+evt+"_"+id+"/"+utf8.join("-"))
                }
                if (event.target.dataset.change == "true"){
                    event_and_refresh("/"+evt+"_"+id+"/"+event.target.value)
                }
                 if (event.target.dataset.combobox == "true"){
                    event_and_refresh("/combobox_"+id+"/"+event.target.selectedIndex)
                }
                if (event.target.dataset.colorselector == "true"){
                    event_and_refresh("/colorselector_"+id+"/"+event.target.value.substring(1))
                }
                if (event.target.dataset.dateselector == "true"){
                    event_and_refresh("/dateselector_"+id+"/"+event.target.value)
                }
            }
            if (evt == "input") {
                if (event.target.dataset.hasOwnProperty('input')){
                    alert("test")
                    event_and_refresh("/"+evt+"_"+id+"/"+event.target.value)
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

function DragOn(e){ 
    
    if (e.target.dataset.hasOwnProperty("istitlebar")){
    e.target.parentElement.draggable = true}
}
function DragOff(e){
    if (e.target.dataset.hasOwnProperty("istitlebar")){
    e.target.parentElement.draggable = false}}

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

function zoom_window(e){
    if (e.deltaY<0){ 
        e.target.dataset.zoomlevel = parseFloat(e.target.dataset.zoomlevel)+0.1 
        window.location.href = "/window_scale_"+e.target.parentElement.id+"/1"
    }
    else { 
        if (parseFloat(e.target.dataset.zoomlevel)>=0.2){
            e.target.dataset.zoomlevel = parseFloat(e.target.dataset.zoomlevel)-0.1 
            window.location.href = "/window_scale_"+e.target.parentElement.id+"/-1"
        }
    }
    //e.target.nextSibling.style.transformOrigin="0% 0% 0px"
    //e.target.parentElement.style.transform = "scale("+e.target.dataset.zoomlevel+")"
    //window.location.href = "/window_scale_"+e.target.parentElement.id+"/"+e.target.dataset.zoomlevel
    e.preventDefault()
}
function event_and_refresh(data){
    window.location.href=data
}
function send_element_value(event){
    window.location.href=event.target.dataset.callbackurl+event.target.value
}
window.onscroll = function () {
    localStorage.setItem("scrollpos", window.scrollY)
};
