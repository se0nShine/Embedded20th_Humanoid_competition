from cv2 import imshow
import math
import numpy as np
from util import *

direction = ''


def detectArrow(img):
    global direction
    img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    _, img = cv2.threshold(img, 0, 255, cv2.THRESH_BINARY+cv2.THRESH_OTSU)
    img = cv2.copyMakeBorder(
        img, 50, 50, 50, 50, cv2.BORDER_CONSTANT, value=(255, 255, 255))

    img = cv2.Canny(img, 200, 200)
    lines = cv2.HoughLinesP(img, rho=1, theta=np.pi/180.0, threshold=30)

    if lines is None:
        direction = ''
        return
    temp = []
    for line in lines:
        x1, y1, x2, y2 = line[0]
        temp.append(line[0])
    x1, y1, x2, y2 = min(temp, key=lambda l: min(l[1], l[3]))

    ang1 = math.atan(float(y2-y1)/(x2-x1))

    if (ang1 > np.pi/8 and ang1 < 3*np.pi/8):
        direction = 'Right'
    elif (ang1 < -np.pi/8 and ang1 > -3*np.pi/8):
        direction = 'Left'
    else:
        direction = ''

    img = cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)
    cv2.line(img, (x1, y1), (x2, y2), (0, 255, 0), 3, cv2.LINE_AA)
    if direction != '':
        cv2.imshow("capture", img)


while True:
    input = cv2.waitKey(1)
    _, img = capture.read()  # 카메라 캡쳐
    img_focus = cv2.getRectSubPix(
        img, (focus['w'], focus['h']), (focus['cx'], focus['cy']))  # 인식 영역만큼 자르기
    rect = getBlackObject(img_focus)
    if rect['w'] > 0:
        img_arrow = cv2.getRectSubPix(img_focus, (int(rect['w']), int(
            rect['h'])), (int(rect['cx']), int(rect['cy'])))
        img = drawRects(img, [rect])
        detectArrow(img_arrow)

    if direction != '':
        img = drawText(img, 1, 'Move '+direction)

    cv2.rectangle(img, (focus['x'], focus['y']), (focus['x']+focus['w'], focus['y']+focus['h']),
                  (255, 255, 255), 2)  # 인식 영역 표시하기
    cv2.imshow("camera", img)
