from cv2 import imshow
import math
import numpy as np
from util import *

color = ''


while True:
    input = cv2.waitKey(1)
    _, img = capture.read() 
    img_focus = cv2.getRectSubPix(
        img, (focus['w'], focus['h']), (focus['cx'], focus['cy']))

    rect = getBlackObject(img_focus)

    if rect['w'] > 0:
        img_focus = cv2.getRectSubPix(img_focus, (int(rect['w']), int(
            rect['h'])), (int(rect['cx']), int(rect['cy'])))
        rect_citizen = getColorObject(
            img_focus, (105, 50, 0), (135, 255, 255))
        if rect_citizen['w'] > 20:
            rect_citizen['x'] += rect['x']
            rect_citizen['y'] += rect['y']
            img = drawRects(img, [rect_citizen])
            img = drawText(img, 1, 'Citizen in danger zone!')

    cv2.rectangle(img, (focus['x'], focus['y']), (focus['x']+focus['w'], focus['y']+focus['h']),
                  (255, 255, 255), 2)  
    cv2.imshow("camera", img)
