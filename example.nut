
class Screen {
    port = null;
    lines = null;
    positions = null;

    constructor(_port) {
        port = _port;
        lines = ["booting...", ""];
        positions = [0, 0];
    }
    
    function set0(line) {
        lines[0] = line;
    }
    
    function set1(line) {
        lines[1] = line;
    }
    
    function clear_screen() {
        port.write(0xFE);
        port.write(0x01);
    }
    
    function cursor_at_line0() {
        port.write(0xFE);
        port.write(128);
    }
    
    function cursor_at_line1() {
        port.write(0xFE);
        port.write(192);
    }
    
    function write_string(string) {
        foreach(i, char in string) {
            port.write(char);
        }
    }
    
    function start() {
        update_screen();
    }
    
    function update_screen() {
        imp.wakeup(0.4, update_screen.bindenv(this));
        
        cursor_at_line0();
        display_message(0);
        
        cursor_at_line1();
        display_message(1);
    }
    
    function display_message(idx) {  
        local message = lines[idx];
        
        local start = positions[idx];
        local end   = positions[idx] + 16;
        
    
        if (end > message.len()) {
            end = message.len();
        }
    
        local string = message.slice(start, end);
        for (local i = string.len(); i < 16; i++) {
            string  = string + " ";
        }
    
        write_string(string);
    
        if (message.len() > 16) {
            positions[idx]++;
            if (positions[idx] > message.len() - 1) {
                positions[idx] = 0;
            }
        }
    }
}

class UpdateMessage extends InputPort {
    name = "response";
    type = "string";
    
    function set(response) {
        local hero = response["0"]["hero"];
        local message0 = response["0"]["message"]
        
        local jenkins = response["1"]["jenkins"];
        local message1 = response["1"]["message"];
        
        server.show("Hero: " + hero);
        server.log("Hero: " + hero + " Message: " + message0 + " Jenkins: " + jenkins + " Message: " + message1);

        screen0.set0("Hero: " + hero);
        screen0.set1(message0);
        
        screen1.set0("Jenkins: " + jenkins);
        screen1.set1(message1);
    }
}

class HttpUpdater {
    target = null
    
    constructor(_target) {
        target = _target
    }
    
    function start() {
        fetch_message();
    }
    
    function fetch_message() {
        imp.wakeup(60.0, fetch_message.bindenv(this));
        
        target.set("ok");
        
        server.log("Fetched status...");
    }
}

// Register with the server
local output = OutputPort("status", "string");
local input = UpdateMessage("repsonse", "string");

imp.configure("NR Support Display", [input], [output]);

local port0 = hardware.uart12
local port1 = hardware.uart57;
port0.configure(9600, 8, PARITY_NONE, 1, NO_CTSRTS);
port1.configure(9600, 8, PARITY_NONE, 1, NO_CTSRTS);

// Boot!
server.log("booting! " + imp.getmacaddress());

screen0 <- Screen(port0);
screen0.clear_screen();
screen0.start();

screen1 <- Screen(port1);
screen1.clear_screen();
screen1.start();

http_updater <- HttpUpdater(output);
http_updater.start();

