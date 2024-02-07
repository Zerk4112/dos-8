window.dos8_data = {
    allowed_keys: ["a","b","c","d","e","f","g","h","i","j","k","l","m",
    "n","o","p","q","r","s","t","u","v","w","x","y","z",
    "0","1","2","3","4","5","6","7","8","9","-","=","[",
    "]","\\",";","'","`",",",".","/", " ", "!","@","#",
    "$","%","^","&","*","(",")","_","+","{","}","|",":",
    "\"","<",">","?","~","⁸","","\r"],
    control_mode:0,
    data_stream:new Array(),
    buffer_clear: false,
    debug:false,
    data_pins: []
};

window.dos8_init_send = function(stringToSend) {

    window.dos8_data.data_stream = stringToSend.split("");
    window.pico8_gpio[0] = 1;
    window.pico8_gpio[1] = 255;
    window.pico8_gpio[2] = 255;
}

window.dos8_init_receive = function() {

    window.dos8_data.data_stream = new Array();
    window.pico8_gpio[0] = 2;
    window.pico8_gpio[1] = 255;
    window.pico8_gpio[2] = 0;
}

window.dos8_clear_buffer = function() {
    window.dos8_data.data_stream = new Array();
    window.pico8_gpio[0] = 1;
    window.pico8_gpio[1] = 0;
    window.pico8_gpio[2] = 0;
}

window.dos8_send_gpio = function () {
    // data is a string of characters to send
    if (window.dos8_data.control_mode == 1) {
        if (window.dos8_data.debug){
            console.log("attempting to send data stream: "+window.dos8_data.data_stream);
        }
        if (window.dos8_data.debug){
            console.log("sending transcribed data stream: "+JSON.stringify(window.dos8_data.data_stream));
        }
        // send the data_stream to pico-8
        if (window.pico8_gpio[2] == 255 && window.pico8_gpio[1] == 255 && window.dos8_data.data_stream.length > 0) {
            if (window.dos8_data.debug){
                console.log("ready to send data stream")
            }
            // extract the first character from the data_stream and send it to pico-8
            var letter = window.dos8_data.data_stream.shift();
            var index = window.dos8_data.allowed_keys.indexOf(letter);
            window.pico8_gpio[1] = index;

        }
        else if (window.dos8_data.data_stream.length==0 && window.pico8_gpio[1] == 255) {
            if (window.dos8_data.debug){
                console.log("data stream is empty, setting control mode to 0");
            }
            window.pico8_gpio[0] = 0;
            window.pico8_gpio[2] = 0;
        }
        else {
            if (window.dos8_data.debug){
                console.log("Clearing buffer");
            }
        }
    } else {
        if (window.dos8_data.debug){
            console.log("control mode is not set to 1, cannot send data stream");
        }
    }
};

window.dos8_receive_gpio = function (data) {
    if (window.dos8_data.control_mode == 2) {
        if (window.pico8_gpio[2] == 255 && window.pico8_gpio[1] == 255) {
            if (window.dos8_data.debug){
                console.log("ready to receive data stream")
            }
            window.pico8_gpio[2] = 0;
        }
        else if (window.pico8_gpio[2] == 0 && window.pico8_gpio[1] != 255) {
            if (window.dos8_data.debug){
                console.log("receiving data stream: "+data);
                console.log("current data stream: "+window.dos8_data.data_stream+" typeof: "+typeof(window.dos8_data.data_stream));
            }
            window.dos8_data.data_stream.push(data);
            window.pico8_gpio[1] = 255;
        }
    }
};

window.dos8_idle = function (gpioStream) {
    if (window.dos8_data.data_pins.length == 0) {
        for (i=8;i<127;i++) {
            window.dos8_data.data_pins.push(i);
        }
        console.log("set up data pins")
    }
    var vkeys = Object.keys(gpioStream);
    if (window.dos8_data.debug){
        console.log("gpioStream: "+JSON.stringify(gpioStream));
        console.log("vkeys: "+JSON.stringify(vkeys));
    }

    if (vkeys.indexOf("0")>-1) {
        if (window.dos8_data.debug){
            console.log("control pin is being set to: "+gpioStream[0]);
        }
        if (gpioStream[0] == 0) {
            // set control mode to 0
            if (window.dos8_data.control_mode == 2) {
                // process the data stream that was sent from pico-8
                // for each character in the data stream, convert it to a character from the available_keys array based on the value as the index of the letter in the array and add it to the data_stream
                var translated_data = "";
                for (bit in window.dos8_data.data_stream) {
                    var letter = window.dos8_data.allowed_keys[window.dos8_data.data_stream[bit]];
                    if (window.dos8_data.debug){
                        console.log("adding letter: "+letter);
                    }
                    translated_data += letter;

                }
                console.log("translated_data: "+translated_data);
                window.dos8_data.data_stream = new Array();
            }
            window.dos8_data.control_mode = 0;
        }
        else if (gpioStream[0] == 1) {
            // set control mode to 1
            window.dos8_data.control_mode = 1;
            window.dos8_send_gpio();
        }
        else if (gpioStream[0] == 2) {
            // set control mode to 2
            window.dos8_data.control_mode = 2;
        }

    }
    if (vkeys.indexOf("1")>-1) {
        if (window.dos8_data.debug){
            console.log("data pin is being set to: "+gpioStream[1]);
        }
        window.dos8_receive_gpio(gpioStream[1]-1);
        window.dos8_send_gpio();
    }
};

window.dos8_debug = function () {
    // log out all keys and values in the dos8_data object
    for (var key in dos8_data) {
        if (window.dos8_data.debug){
            console.log(key + ": " + dos8_data[key]);
        }
    }
};