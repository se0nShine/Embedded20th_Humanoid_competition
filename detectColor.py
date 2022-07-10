from cv2 import imshow
import math
import numpy as np
from util import *

color = ''


while True:
    input = cv2.waitKey(1)
    _, img = capture.read()  # 카메라 캡쳐
    img_focus = cv2.getRectSubPix(
        img, (focus['w'], focus['h']), (focus['cx'], focus['cy']))  # 인식 영역만큼 자르기

    rect_black = getBlackObject(img_focus)
    rect_blue = getColorObject(img_focus, (105, 50, 0), (135, 255, 255))
    rect_green = getColorObject(img_focus, (45, 50, 0), (75, 255, 255))
    rect_yellow = getColorObject(img_focus, (15, 50, 0), (45, 255, 255))
    rect_red1 = getColorObject(img_focus, (0, 50, 0), (15, 255, 255))
    rect_red2 = getColorObject(img_focus, (165, 50, 0), (179, 255, 255))
    rect_red = max([rect_red1, rect_red2], key=lambda r: (r['w']*r['h']))
    rect = max([rect_black, rect_blue, rect_red, rect_green, rect_yellow],
               key=lambda r: (r['w']*r['h']))
    if rect['w'] > 0:
        img = drawRects(img, [rect])
        if rect == rect_blue:
            color = 'Blue'
        elif rect == rect_red:
            color = 'Red'
        elif rect == rect_green:
            color = 'Green'
        elif rect == rect_yellow:
            color = 'Yellow'
        else:
            color = 'Black'

    img = drawText(img, 1, 'Color: '+str(color))

    cv2.rectangle(img, (focus['x'], focus['y']), (focus['x']+focus['w'], focus['y']+focus['h']),
                  (255, 255, 255), 2)  # 인식 영역 표시하기
    cv2.imshow("camera", img)
