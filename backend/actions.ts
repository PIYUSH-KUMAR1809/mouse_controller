import robotjs from '@jitsi/robotjs';

const { getScreenSize, getMousePos, setMouseDelay, moveMouse, mouseClick } = robotjs;


var screenSize = getScreenSize();
var mousePos = getMousePos();
setMouseDelay(100);
var sensitivity = 10;

var posx = mousePos.x;
var posy = mousePos.y;

export function setSensitivity(s: number) {
    sensitivity = s;
    console.log("Sensitivity set to: " + sensitivity);
}

export function moveMouseTo(x: number, y: number) {
    mousePos = getMousePos();
    posx = mousePos.x;
    posy = mousePos.y;
    //the screen is divided into 32x18 parts
    //the mouse is moved to the center of the part that contains the point (x,y)
    posx = posx + x * sensitivity;
    posy = posy + y * sensitivity;

    posx = Math.max(0, Math.min(posx, screenSize.width))
    posy = Math.max(0, Math.min(posy, screenSize.height))

    moveMouse(posx, posy);
}

export function leftMouseClick() {
    mouseClick('left');
}

export function rightMouseClick() {
    mouseClick('right');
}

export function middleMouseClick() {
    mouseClick('middle');
}

export function doubleLeftMouseClick() {
    mouseClick('left', true);
}
export function doubleRightMouseClick() {
    mouseClick('right', true);
}

export function doubleMiddleMouseClick() {
    mouseClick('middle', true);
}

export function centerMouse() {
    moveMouse(screenSize.width / 2, screenSize.height / 2);
}


