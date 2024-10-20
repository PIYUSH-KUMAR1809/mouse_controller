import { WebSocketServer } from 'ws';
import {
    leftMouseClick,
    rightMouseClick,
    doubleLeftMouseClick,
    doubleRightMouseClick,
    middleMouseClick,
    doubleMiddleMouseClick,
    centerMouse,
    moveMouseTo,
    setSensitivity
  } from './actions';

var isMouseMovementEnabled = false;

var wss = new WebSocketServer({ port: 3000 });

const handleMessage = (message: string) => {
    try {
        const data = JSON.parse(message.toString());
        console.log('Received:', data);
  
        if (data.leftClickEvent) {
            leftMouseClick();
          } else if (data.rightClickEvent) {
            rightMouseClick();
          } else if (data.doubleLeftClickEvent) {
            doubleLeftMouseClick();
          } else if (data.doubleRightClickEvent) {
            doubleRightMouseClick();
          } else if (data.middleClickEvent) {
            middleMouseClick();
          } else if (data.doubleMiddleClickEvent) {
            doubleMiddleMouseClick();
          } else if (data.centerMouseEvent) {
            centerMouse();
          } else if (data.event === "MouseMotionMove") {
              if (isMouseMovementEnabled) {
                  const { x, y } = data.axis;
                  moveMouseTo(x, y);
              }
          } else if (data.event === "MouseMotionStart") {
              isMouseMovementEnabled = true;
              console.log("Mouse motion tracking started");
          } else if (data.event === "MouseMotionStop") {
              isMouseMovementEnabled = false;
              console.log("Mouse motion tracking stopped");
          } else if ('changeSensitivityEvent' in data) {
              setSensitivity(data.changeSensitivityEvent);
          } else {
            console.log('Unknown event:', data);
          }
      } catch (error) {
        console.error('Error processing message:', error);
      }
  };

wss.on('connection', function connection(ws) {
    ws.send("Hello Client. Socket connection established successfully");
    //it is a constant connection, all messages are handled in this function
    //the messages are parsed as JSON objects
    //the messages are handled in the actions.ts file
    ws.on('message', (message) => handleMessage(message.toString()));

    ws.on('close', () => {
        console.log('Client disconnected');
    });
});

