from cv2 import imshow
import math
import numpy as np
from util import *

direction = ''


def getDegree(p1, p2):
    rad = math.atan(float(p2[1]-p1[1])/(p2[0]-p1[0]))
    return round(rad*(180/(np.pi)), 3)


def getSubDegree(deg1, deg2):
    if deg1 > deg2:
        ang1 = deg1-deg2
    else:
        ang1 = deg2-deg1
    ang2 = 180-ang1
    if abs(ang1) > abs(ang2):
        return ang2
    else:
        return ang1


def detectAngle(img):
    global direction
    mask = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)  # bgr에서 hsv로 변환
    # black_range안에 있는것만 걸러낸다고 지정
    mask = cv2.inRange(mask, (15, 100, 0), (45, 255, 255))
    img = cv2.bitwise_and(img, img, mask=mask)  # 채로 걸러낸다.

    contours, _ = cv2.findContours(mask, 1, cv2.CHAIN_APPROX_NONE)

    if len(contours) > 0:
        c = max(contours, key=cv2.contourArea)
        M = cv2.moments(c)
        if M["m00"] != 0:
            cx = int(M['m10']/M['m00'])
            cy = int(M['m01']/M['m00'])
            rows, cols = img.shape[:2]
            [vx, vy, x, y] = cv2.fitLine(c, cv2.DIST_L2, 0, 0.01, 0.01)
            try:
                y1 = int((-x*vy/vx)+y)
                y2 = int(((cols-x)*vy/vx)+y)
                #direction = deg
                cv2.circle(img, (cx, cy), 5, (255, 255, 255), -1)
                cv2.line(img, (cx, cy-500), (cx, cy+500), (0, 0, 255), 3)
                cv2.line(img, (0, y1), (cols-1, y2), (0, 0, 255), 2)
                degMid = 90
                deg = getDegree((0, y1), (cols-1, y2))
                resultDeg = getSubDegree(degMid, deg)
                resultDeg = round(resultDeg, 1)
                if deg > 0:
                    direction = '+'+str(resultDeg)
                else:
                    direction = '-'+str(resultDeg)
                cv2.drawContours(img, c, -1, (0, 255, 0), 2)
            except Exception as e:
                print(e)
    cv2.imshow("detect", img)


while True:
    input = cv2.waitKey(1)
    _, img = capture.read()  # 카메라 캡쳐
    img_focus = cv2.getRectSubPix(
        img, (focus['w'], focus['h']), (focus['cx'], focus['cy']))  # 인식 영역만큼 자르기

    rect = getColorObject(img_focus, (15, 100, 0), (45, 255, 255))
    if rect['w'] > 0:
        img_line = cv2.copyMakeBorder(
            img_focus, 10, 10, 10, 10, cv2.BORDER_CONSTANT, value=(255, 255, 255))
        direction = ''
        detectAngle(img_line)

    if direction != '':
        img = drawText(img, 1, direction+' deg')
    cv2.rectangle(img, (focus['x'], focus['y']), (focus['x']+focus['w'], focus['y']+focus['h']),
                  (255, 255, 255), 2)  # 인식 영역 표시하기
    cv2.imshow("camera", img)
