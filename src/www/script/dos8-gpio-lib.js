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
    // window.pico8_gpio[1] = 255;
    for (i in window.dos8_data.data_pins) {
        window.pico8_gpio[window.dos8_data.data_pins[i]] = 255;
    }
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
    // window.pico8_gpio[1] = 0;
    for (i in window.dos8_data.data_pins) {
        window.pico8_gpio[window.dos8_data.data_pins[i]] = 255;
    }
    window.pico8_gpio[2] = 0;
}

window.dos8_send_gpio = function () {
    // data is a string of characters to send
    if (window.dos8_data.control_mode == 1) {
        if (window.dos8_data.debug){
            console.log("sending transcribed data stream: "+JSON.stringify(window.dos8_data.data_stream));
        }
        // send the data_stream to pico-8
        if (window.pico8_gpio[2] == 255 && !window.dos8_check_data_pins() && window.dos8_data.data_stream.length > 0) {
            if (window.dos8_data.debug){
                console.log("ready to send data stream")
            }
            var current_data_pin = 8;
            var charsToProcess= window.dos8_data.data_stream.length;
            for (i=0;i<charsToProcess;i++) {
                var letter = window.dos8_data.data_stream.shift();
                var index = window.dos8_data.allowed_keys.indexOf(letter);
                window.pico8_gpio[current_data_pin] = index;
                current_data_pin++;
                if (current_data_pin > 127) {
                    current_data_pin = 8;
                    break;
                } else if (i == charsToProcess-1) {
                    window.dos8_data.data_stream = new Array();
                }
            }
            for (i=0; i<current_data_pin-8; i++) {
                window.dos8_data.data_stream.shift();
            }
        }
        else if (window.dos8_data.data_stream.length==0 && window.pico8_gpio[2] == 255) {
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

window.dos8_check_data_pins = function () {
    // check and see if all data pins are 255. If not, return false. esle, return true
    for (i in window.dos8_data.data_pins) {
        if (window.pico8_gpio[window.dos8_data.data_pins[i]] != 255) {
            return true;
        }
    }
    return false;
};

window.dos8_reset_data_pins = function () {
    for (i in window.dos8_data.data_pins) {
        window.pico8_gpio[window.dos8_data.data_pins[i]] = 255;
    }
};


window.dos8_receive_gpio = function (data) {
    if (window.dos8_data.control_mode == 2) {
        console.log(window.pico8_gpio)
        console.log("control mode is 2, receiving data stream")
        console.log("data: "+JSON.stringify(data));
        console.log("data pins on:"+window.dos8_check_data_pins())
        console.log("clock pin: "+window.pico8_gpio[2])
        if (window.pico8_gpio[2] == 255 && window.dos8_check_data_pins()) { //&& window.pico8_gpio[1] == 255
            if (window.dos8_data.debug){
                console.log("ready to receive data stream")
            }
            if (window.dos8_data.debug){
                console.log("receiving data stream: "+JSON.stringify(data));
                console.log("current data stream: "+window.dos8_data.data_stream+", typeof: "+typeof(window.dos8_data.data_stream));
            }
            for (var pin=8; pin<=127;pin++) {
                var value = gpio[pin];
                if (value != 255 && value != undefined) {
                    console.log("pin: "+pin+", value: "+value, ",letter: "+window.dos8_data.allowed_keys[value-1])
                    window.dos8_data.data_stream.push(value-1);
                    gpio[pin] = 255;
                }

            }
            window.pico8_gpio[2] = 0;
        }
    }
};

window.dos8_idle = function (gpioStream) {
    if (window.dos8_data.data_pins.length == 0) {
        for (i=8;i<=127;i++) {
            window.dos8_data.data_pins.push(i);
        }
        // console.log("set up data pins")
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
            // console.log("gpio control mode is 0")
            // set control mode to 0
            if (window.dos8_data.control_mode == 2) {
                // console.log("saved control mode is 2, translating data")
                var translated_data = "";
                // console.log("data_stream: "+JSON.stringify(window.dos8_data.data_stream))
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

    } else if (!window.dos8_check_data_pins() && window.dos8_data.control_mode == 1 && window.pico8_gpio[2] == 255 && window.dos8_data.data_stream.length == 0) {
        console.log("data stream is finished sending, setting clock to 0")
        // window.pico8_gpio[2] = 0;

    } else if (!window.dos8_check_data_pins() && window.dos8_data.control_mode == 1 && window.pico8_gpio[2] == 255 && window.dos8_data.data_stream.length > 0) {
        console.log("data still being sent, send more data")
        window.dos8_send_gpio();
    }
    if (window.dos8_check_data_pins()) {
        console.log("data pins are being written to")
        window.dos8_receive_gpio(gpioStream);
        
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