import serial
import cv2
import os
import pytesseract
import math
import numpy
from PIL import Image

ser = serial.Serial('/dev/ttyS0', 4800, timeout=0.01)
cap = cv2.VideoCapture(0)
viewSize = (320, int(320 / 1.333))
cap.set(3, viewSize[0])
cap.set(4, viewSize[1])
cap.set(5, 30)

blue_range = [(105, 50, 0), (135, 255, 255)]

def sendTX(data):
    ser.write(serial.to_bytes([data]))
    print("send data:", data)


def receiveRX():
    if ser.inWaiting() > 0:
        rx = ord(ser.read(1))
        print("receive data:", rx)
        return rx
    else:
        return 0

def getColorObject(img, lower, upper):
    mask = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    mask = cv2.inRange(mask, lower, upper)
    img = cv2.bitwise_and(img, img, mask=mask)
    img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    contours, _ = cv2.findContours(
        img, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if len(contours) < 1:
        return {
            'x': 0,
            'y': 0,
            'w': 0,
            'h': 0,
            'cx': 0,
            'cy': 0
        }
    contour = max(contours, key=cv2.contourArea)
    x, y, w, h = cv2.boundingRect(contour)
    cx = x + (w / 2)
    cy = y + (h / 2)
    rect = {
        'x': x,
        'y': y,
        'w': w,
        'h': h,
        'cx': cx,
        'cy': cy
    }
    return rect

def drawRects(img, rects):
    for rect in rects:
        pt1 = (int(rect['x']), int(rect['y']))
        pt2 = (pt1[0]+int(rect['w']), pt1[1]+int(rect['h']))
        cv2.rectangle(img, pt1, pt2, (0, 255, 0), 2)
    return img

def command_direction(rects):
    w_view = viewSize[0]
    h_view = viewSize[1]
    for rect in rects:
        center_point=(int(rect['cx']),int(rect['cy']))

    if (center_point[0]<=int(w_view*0.33))and (center_point[1]<=int(h_view*0.33)):
        return 171
    elif(center_point[0]<=int(w_view*0.33*2))and (center_point[1]<=int(h_view*0.33)):
        return 172
    elif (center_point[0] <= int(w_view)) and (center_point[1] <= int(h_view * 0.33)):
        return 173
    elif (center_point[0] <= int(w_view * 0.33)) and (center_point[1] <= int(h_view * 0.33*2)):
        return 174
    elif (center_point[0] <= int(w_view * 0.33 * 2)) and (center_point[1] <= int(h_view * 0.33*2)):
        return 175
    elif (center_point[0] <= int(w_view)) and (center_point[1] <= int(h_view * 0.33*2)):
        return 176
    elif (center_point[0] <= int(w_view * 0.33)) and (center_point[1] <= int(h_view)):
        return 177
    elif (center_point[0] <= int(w_view * 0.33 * 2)) and (center_point[1] <= int(h_view)):
        return 178
    elif (center_point[0] <= int(w_view)) and (center_point[1] <= int(h_view)):
        return 179


def detect_object(rects):
    w_view = viewSize[0]
    h_view = viewSize[1]
    for rect in rects:
        center_point=(int(rect['cx']),int(rect['cy']))

    if (center_point[0]<=int(w_view*0.33))and (center_point[1]<=int(h_view*0.33)):
        return 181
    elif(center_point[0]<=int(w_view*0.33*2))and (center_point[1]<=int(h_view*0.33)):
        return 182
    elif (center_point[0] <= int(w_view)) and (center_point[1] <= int(h_view * 0.33)):
        return 183
    elif (center_point[0] <= int(w_view * 0.33)) and (center_point[1] <= int(h_view * 0.33*2)):
        return 184
    elif (center_point[0] <= int(w_view * 0.33 * 2)) and (center_point[1] <= int(h_view * 0.33*2)):
        return 185
    elif (center_point[0] <= int(w_view)) and (center_point[1] <= int(h_view * 0.33*2)):
        return 186
    elif (center_point[0] <= int(w_view * 0.33)) and (center_point[1] <= int(h_view)):
        return 187
    elif (center_point[0] <= int(w_view * 0.33 * 2)) and (center_point[1] <= int(h_view)):
        return 188
    elif (center_point[0] <= int(w_view)) and (center_point[1] <= int(h_view)):
        return 189


def gridline():
    w_view=viewSize[0]
    h_view=viewSize[1]
    for n_line in range(1,3):
        cv2.line(img, (int(w_view*0.33*n_line), 0), (int(w_view*0.33*n_line), h_view), (255, 255, 255), 1)
        cv2.line(img, (0, int(h_view * 0.33*n_line)), (w_view, int(h_view * 0.33*n_line)), (255, 255, 255), 1)
    cv2.imshow("camera_grid", img)

def gotoObject(img):
    rect_blue = getColorObject(img, blue_range[0], blue_range[1])
    rect = rect_blue
    gridline()
    if rect['w'] > 0:
        img = drawRects(img, [rect])
        return command_direction([rect])
    else:
        return 170


def pickObject(img):
    rect_blue = getColorObject(img, blue_range[0], blue_range[1])
    rect = rect_blue
    gridline()
    if rect['w'] > 0:
        img = drawRects(img, [rect])
        return detect_object([rect])
    else:
        return 180

actionFunc = {153:gotoObject, 154:pickObject}

sendTX(128)
while True:
    cv2.waitKey(1)
    _, img = cap.read()
    rx = receiveRX()
    try:
        tx = actionFunc[rx](img)
        sendTX(tx)
    except Exception as e:
        if str(e) != '0':
            print('main loop error: ', e)
    cv2.imshow("camera", img)