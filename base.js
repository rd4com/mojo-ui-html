['click','input','change'].forEach(function(evt) {
    document.addEventListener(evt, function (event) {         
        var id = event.target.getAttribute('id'); 
        if (id){
            if (evt == "click") {
                if (event.target.dataset.click == "true"){
                    window.location.href = "/"+evt+"_"+id
                }
                if (event.target.dataset.hasOwnProperty('textchoice')){
                    window.location.href = event.target.dataset.textchoice
                } 
            }
            if (evt == "change") {
                if (event.target.dataset.textinput == "true"){
                    const encoder = new TextEncoder();
                    const utf8 = encoder.encode(event.target.value);
                    console.log(utf8.join("-"))
                    window.location.href = "/"+evt+"_"+id+"/"+utf8.join("-")
                }
                if (event.target.dataset.change == "true"){
                    window.location.href = "/"+evt+"_"+id+"/"+event.target.value
                }
                 if (event.target.dataset.combobox == "true"){
                    window.location.href = "/combobox_"+id+"/"+event.target.selectedIndex
                }
                if (event.target.dataset.colorselector == "true"){
                    window.location.href = "/colorselector_"+id+"/"+event.target.value.substring(1)
                }
                if (event.target.dataset.dateselector == "true"){
                    window.location.href = "/dateselector_"+id+"/"+event.target.value
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
/* not used yet
function new_xhr(data,async_mode){
    var xhttp = new XMLHttpRequest();
    xhttp.overrideMimeType("text/plain");
    xhttp.open("GET", data, async_mode);
    xhttp.send();
}*/