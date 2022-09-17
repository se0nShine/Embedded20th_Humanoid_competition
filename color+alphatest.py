import serial
import cv2
import os
import pytesseract
import math
import numpy
from PIL import Image

cap = cv2.VideoCapture(0)
viewSize = (320, int(320/1.333))
cap.set(3, viewSize[0])
cap.set(4, viewSize[1])

blue_range=[(105, 50, 0), (135, 255, 255)]
red1_range=[(0, 50, 0), (15, 255, 255)]
red2_range=[(165, 50, 0), (179, 255, 255)]
color_range=[(0, 0, 0), (0, 0, 0)]
def detectRoom(img):
    res = img
    mask = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    mask = cv2.inRange(mask, color_range[0], color_range[1])
    img = cv2.bitwise_and(img, img, mask=mask)
    contours, _ = cv2.findContours(
        img, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if len(contours) > 0:
        alphas = ['A', 'B', 'C', 'D']
        txs = {'A': 180, 'B': 181, 'C': 182, 'D': 183}
        c = max(contours, key=cv2.contourArea)
        x, y, w, h = cv2.boundingRect(c)
        rect = {
            'x': x,
            'y': y,
            'w': w,
            'h': h,
            'cx': x + (w / 2),
            'cy': y + (h / 2)
        }
        cv2.rectangle(res, (x, y), (x+w, y+h), (0, 255, 0), 2)

        img = cv2.getRectSubPix(img, (int(rect['w']), int(
            rect['h'])), (int(rect['cx']), int(rect['cy'])))
        _, img = cv2.threshold(img, 0, 255, cv2.THRESH_BINARY+cv2.THRESH_OTSU)
        img = cv2.copyMakeBorder(
            img, 50, 50, 50, 50, cv2.BORDER_CONSTANT, value=(255, 255, 255))
        filename = "{}.png".format(os.getpid())
        cv2.imwrite(filename, img)
        text = pytesseract.image_to_string(
            Image.open(filename), config="--psm 10", lang='eng')
        os.remove(filename)
        try:
            if alphas.count(text[0]) > 0:
                cv2.putText(res, text[0], (0, 50), 0, 1, (0, 255, 0), 2)
                cv2.imshow("detectDirection", res)
                return txs[text[0]]
            elif alphas.count(text[0])==0 and color_range==[(0, 0, 0), (0, 0, 0)]:
                color_range=blue_range
            elif alphas.count(text[0])==0 and color_range==blue_range:
                color_range=red1_range
            elif alphas.coutn(text[0]==0 and color_range==red1_range):
                color_range=red2_range
            elif alphas.count(text[0])==0 and color_range==red2_range:
                color_range=blue_range
                              
        except Exception as e:
            if str(e) != '0':
                print('error: ', e)
            return 184
        finally:
            cv2.imshow("detectDirection", res)

    return 184

