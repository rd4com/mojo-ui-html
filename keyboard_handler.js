
async function send_keyboard(url){
    
    const response = await fetch(url);
    const response2 = await response.text();
    let parser = new DOMParser();
    doc = parser.parseFromString( response2, 'text/html' );
    document.replaceChild( doc.documentElement, document.documentElement );

}

document.addEventListener('keypress', (e) => {
const activeElement = document.activeElement;
//console.log(e.key,e.code,e.keyCode)
//console.log(activeElement.tagName)
if ("body" == activeElement.tagName.toLowerCase()){
    //only if InputElement dont have focus
    send_keyboard("/keyboard/down/"+e.keyCode)
} 
//would be better to check if document.activeElement.data-attribute["keyboard"]
//so that each elements can have separate event
});

document.addEventListener('keydown', (e) => {
const activeElement = document.activeElement;
if ("body" == activeElement.tagName.toLowerCase()){
    if (e.key.length > 1){ 
        send_keyboard("/keyboard/down/keydown-"+e.key)
    }
}
});