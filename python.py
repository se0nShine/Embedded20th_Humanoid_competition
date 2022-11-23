import serial
import cv2
import os
import pytesseract
import math
import numpy
import numpy as np
from PIL import Image

#ser = 0
ser = serial.Serial('/dev/ttyS0', 4800, timeout=0.01)
cap = cv2.VideoCapture(0)
viewSize = (320, int(320 / 1.333))
cap.set(3, viewSize[0])
cap.set(4, viewSize[1])
cap.set(5, 30)  # FPS 30으로 설정

ROI_row1 = 0
ROI_row2 = viewSize[1]
roomColor = 0


def CutImg(img, rx):
    global ROI_row1, ROI_row2
    if rx == 150:
        ROI_row1 = viewSize[1]*(1/5)
        ROI_row2 = viewSize[1]
    elif rx == 151:
        ROI_row1 = 0
        ROI_row2 = viewSize[1]*(1/2)
    elif rx == 152:
        ROI_row1 = viewSize[1] * (1 / 2)
        ROI_row2 = viewSize[1]
    img = img[int(ROI_row1):int(ROI_row2), 0:int(viewSize[0])]
    return img


def getDegree(p1, p2):
    if p2[0] == p1[0]:
        p2 = (p1[0]+0.1, p2[1])
    rad = math.atan(float(p2[1] - p1[1]) / (p2[0] - p1[0]))
    return round(rad * (180 / (numpy.pi)), 3)


def getDistance(p1, p2):
    return math.sqrt((p1[0] - p2[0]) * (p1[0] - p2[0]) + (p1[1] - p2[1]) * (p1[1] - p2[1]))


def getSubDegree(deg1, deg2):
    ang1 = max(deg1, deg2) - min(deg1, deg2)
    ang2 = 180 - ang1
    return min(ang1, ang2)


# 로보베이직으로 값을 보냄
def sendTX(data):
    ser.write(serial.to_bytes([data]))
    print("send data:", data)


# 로보베이직에서 보낸 데이터 값을 받아옴
def receiveRX():
    if ser.inWaiting() > 0:
        rx = ord(ser.read(1))
        print("receive data:", rx)
        return rx
    else:
        return 0


red_low = [165, 50, 0]
red_up = [179, 255, 255]

green_low = [45, 50, 0]
green_up = [90, 255, 255]

blue_low = [105, 50, 0]
blue_up = [135, 255, 255]

yellow_low = [15, 100, 0]
yellow_up = [45, 255, 255]

white_low = [0, 0, 141]
white_up = [179, 255, 255]

invert_black_low = [0, 0, 200]
invert_black_up = [179, 80, 255]

lower_color = [0, 0, 0]
upper_color = [255, 255, 255]


# 라인트레이싱 영상처리
def traceLine(img):
    res = img
    mask = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    mask = cv2.inRange(mask, tuple(yellow_low), tuple(yellow_up))
    img = cv2.bitwise_and(img, img, mask=mask)
    contours, _ = cv2.findContours(mask, 1, cv2.CHAIN_APPROX_NONE)
    if len(contours) > 0:
        c = max(contours, key=cv2.contourArea)
        M = cv2.moments(c)
        if M["m00"] != 0:
            cx = int(M['m10'] / M['m00'])
            _, cols = img.shape[:2]
            [vx, vy, x, y] = cv2.fitLine(c, cv2.DIST_L2, 0, 0.01, 0.01)
            cv2.line(res, (cx, 0), (cx, viewSize[1]), (0, 0, 255), 3)
            cv2.drawContours(res, c, -1, (0, 255, 0), 2)
            try:
                y1 = int((-x * vy / vx) + y)
                y2 = int(((cols - x) * vy / vx) + y)
                deg = getDegree((0, y1), (cols - 1, y2))
                resultDeg = round(getSubDegree(90, deg), 1)
                if deg > 0:
                    deg = resultDeg
                else:
                    deg = -resultDeg

                cv2.putText(res, str(deg), (0, 50), 0, 1, (0, 255, 0), 2)
                cv2.imshow("traceLine", res)

                if deg <= -5:
                    return 103
                elif deg >= 5:
                    return 102
                else:
                    if cx <= 120:
                        return 104
                    elif cx >= 200:
                        return 105
                    else:
                        return 101
            except Exception as e:
                if str(e) != '0':
                    print('error: ', e)
                return 109
            finally:
                cv2.imshow("traceLine", res)

    return 109


# 방향인식 영상처리
# 140~143: 동쪽 서쪽 남쪽 북쪽인식
# 144: 문자못찾음 또는 오류발생
def detectWord(img):
    alphas = ('N', 'W', 'S', 'E')
    txVal = {'N': 111, 'W': 113, 'S': 115, 'E': 117}
    img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    _, img = cv2.threshold(
        img, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    img = cv2.copyMakeBorder(
        img, 50, 50, 50, 50, cv2.BORDER_CONSTANT, value=(255, 255, 255))
    filename = "{}.png".format(os.getpid())
    cv2.imwrite(filename, img)
    text = pytesseract.image_to_string(
        Image.open(filename), config="--psm 10", lang='eng')
    os.remove(filename)
    try:
        if alphas.count(text[0]) > 0:
            print(text[0])
            return txVal[text[0]]
    except Exception as e:
        if str(e) != '0':
            print('error: ', e)
        return 119

    return 119


def detectRoomWord(img):
    contours, _ = cv2.findContours(
        img, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    img_color = cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)
    cv2.drawContours(img_color, contours, -1, (0, 255, 0), 5)
    cv2.imshow("wwww", img_color)

    if len(contours) < 1:
        print("contours is not")
        return 149

    c = max(contours, key=cv2.contourArea)
    x, y, w, h = cv2.boundingRect(c)  # boundingRect는 직사각형 그려주는 함수
    img = img[y:y+h, x:x+w]
    cv2.imshow("wwww2", img)

    alphas = ('A', 'B', 'C', 'D')
    txVal = {'A': 141, 'B': 142, 'C': 143, 'D': 144}
    _, img = cv2.threshold(
        img, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    img = cv2.copyMakeBorder(
        img, 50, 50, 50, 50, cv2.BORDER_CONSTANT, value=(255, 255, 255))
    filename = "{}.png".format(os.getpid())
    cv2.imwrite(filename, img)
    text = pytesseract.image_to_string(
        Image.open(filename), config="--psm 10", lang='eng')
    os.remove(filename)

    try:
        if alphas.count(text[0]) > 0:
            print(text[0])
            return txVal[text[0]]
    except Exception as e:
        if str(e) != '0':
            print('error: ', e)
        return 149

    return 149


def detectArrow(img, tx):
    if tx == 119:
        return 119
    img = cv2.Canny(img, 200, 200)
    lines = cv2.HoughLinesP(img, rho=1, theta=np.pi/180.0, threshold=30)

    if lines is None:
        return 119
    temp = []
    for line in lines:
        x1, y1, x2, y2 = line[0]
        temp.append(line[0])
    x1, y1, x2, y2 = min(temp, key=lambda l: min(l[1], l[3]))

    # img2 = cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)
    # cv2.line(img2, (x1, y1), (x2, y2), (0, 255, 0), 3, cv2.LINE_AA)
    # cv2.imshow("capture", img2)

    if x2 == x1:
        x2 = x1+0.1
    ang1 = math.atan(float(y2-y1)/(x2-x1))

    if (ang1 > np.pi/8 and ang1 < 3*np.pi/8):
        return tx+1
    elif (ang1 < -np.pi/8 and ang1 > -3*np.pi/8):
        return tx
    else:
        return 119


def detectCorner(img):
    mask = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    mask = cv2.inRange(mask, tuple(yellow_low), tuple(yellow_up))
    img = cv2.bitwise_and(img, img, mask=mask)
    img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    _, img = cv2.threshold(img, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    skel = numpy.zeros(img.shape, numpy.uint8)
    element = cv2.getStructuringElement(cv2.MORPH_CROSS, (3, 3))
    while True:
        open = cv2.morphologyEx(img, cv2.MORPH_OPEN, element)
        temp = cv2.subtract(img, open)
        eroded = cv2.erode(img, element)
        skel = cv2.bitwise_or(skel, temp)
        img = eroded.copy()

        if cv2.countNonZero(img) == 0:
            break
    edges = cv2.Canny(skel, 200, 200)
    linesP = cv2.HoughLinesP(edges, 1, numpy.pi / 180, 30, 30)
    cdstP = cv2.cvtColor(edges, cv2.COLOR_GRAY2BGR)

    if linesP is not None:
        for line in range(0, len(linesP)):
            I = linesP[line][0]
        temps = []
        points = []
        for line in linesP:
            x1, y1, x2, y2 = line[0]
            deg = round(getDegree((x1, y1), (x2, y2)), 3)
            temps.append([x1, y1, x2, y2, deg])
            points.append([x1, y1])
            points.append([x2, y2])
        stn = max(temps, key=lambda l: max(l[1], l[3]))
        if stn[1] > stn[3]:
            stn_point = [stn[0], stn[1]]
        else:
            stn_point = [stn[2], stn[3]]
        left_point = min(points, key=lambda p: p[0])  # points 중x값중에 제일 작은거
        right_point = max(points, key=lambda p: p[0])  # Points 중 x값중 제일 큰거

        stn_deg = stn[4]
        print_deg = stn_deg

        cv2.line(cdstP, (stn_point[0], stn_point[1]), (stn_point[0]+int(math.cos(stn_deg/(2*math.pi)*50)), stn_point[0]+int(math.sin(stn_deg/(2*math.pi)*50))),
                 (0, 0, 255), 3, cv2.LINE_AA)
        if print_deg < 0:
            print_deg += 180
        cv2.circle(cdstP, (stn_point[0], stn_point[1]), 5, (255, 255, 255), -1)
        cv2.circle(
            cdstP, (left_point[0], left_point[1]), 5, (255, 255, 255), -1)
        cv2.circle(
            cdstP, (right_point[0], right_point[1]), 5, (255, 255, 255), -1)

        notCurve = False

        if getDistance(left_point, stn_point) < 30:
            left_deg = stn_deg
            notCurve = True
        else:
            left_deg = getDegree(left_point, stn_point)
        cv2.line(cdstP, (stn_point[0], stn_point[1]), (left_point[0], left_point[1]),
                 (0, 255, 0), 3, cv2.LINE_AA)
        ld = left_deg
        left_deg = getSubDegree(stn_deg, left_deg)
        left = left_deg >= 30 and left_deg <= 75

        if getDistance(right_point, stn_point) < 30:
            right_deg = stn_deg
            notCurve = True
        else:
            right_deg = getDegree(right_point, stn_point)
        cv2.line(cdstP, (stn_point[0], stn_point[1]), (right_point[0], right_point[1]),
                 (255, 0, 0), 3, cv2.LINE_AA)
        rd = right_deg
        right_deg = getSubDegree(stn_deg, right_deg)
        right = right_deg >= 30 and right_deg <= 75

        print("left_deg:", ld)
        print("right_deg:", rd)
        print("stn_deg:", stn_deg)
        print("left_subdeg:", left_deg)
        print("right_subdeg:", right_deg)
        print("right:", right)
        print("left:", left)
        print()

        cv2.imshow("corner", cdstP)
        # if notCurve:
        #    return 133
        if right and left:

            return 108
        elif right and not (left):

            return 106
        elif not (right) and left:

            return 107
        else:
            return 133

        if not math.isnan(print_deg):
            cv2.line(cdstP, (stn[0], stn[1]), (stn[2], stn[3]),
                     (0, 0, 255), 3, cv2.LINE_AA)

        cv2.imshow("detectCorner", cdstP)
    return 133


def detectLine(img):
    tx = detectCorner(img)
    if tx == 133:
        return traceLine(img)
    return tx


def detectDirection(img):
    img_ori = img
    mask = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    mask = cv2.inRange(mask, tuple(white_low), tuple(white_up))
    img = cv2.bitwise_and(img, img, mask=mask)
    img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    contours, _ = cv2.findContours(
        img, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    # print(len(contours))
    # cv2.drawContours(img, contours, -1, (0, 255, 0), 5)

    c = max(contours, key=cv2.contourArea)
    x, y, w, h = cv2.boundingRect(c)  # boundingRect는 직사각형 그려주는 함수
    # cv2.rectangle(img, (x, y), (x+w, y+h), (255, 255, 0), 2)
    img = img_ori[y:y+h, x:x+w]
    img_ori = img
    cv2.imshow("white", img)

    img = cv2.bitwise_not(img)
    mask = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    mask = cv2.inRange(mask, tuple(invert_black_low), tuple(invert_black_up))
    img = cv2.bitwise_and(img, img, mask=mask)
    img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    contours, _ = cv2.findContours(
        img, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    rects = []
    for contour in contours:
        x, y, w, h = cv2.boundingRect(contour)
        rect = {
            'x': x,
            'y': y,
            'w': w,
            'h': h,
            'cx': x + (w / 2),
            'cy': y + (h / 2)
        }
        rects.append(rect)

    if len(rects) < 1:
        return 119
    maxRect1 = max(rects, key=lambda r: r['w']*r['h'])
    rects.remove(maxRect1)
    # while maxRect['w']*3 < maxRect['h'] or maxRect['w'] > 3*maxRect['h']:
    #    maxRect = max(rects, key=lambda r: r['w']*r['h'])
    #    rects.remove(maxRect)

    subImg1 = img_ori[maxRect1['y']:maxRect1['y']+maxRect1['h'],
                      maxRect1['x']:maxRect1['x']+maxRect1['w']].copy()
    cv2.rectangle(img_ori, (maxRect1['x'], maxRect1['y']), (
        maxRect1['x'] + maxRect1['w'], maxRect1['y'] + maxRect1['h']), (255, 255, 0), 2)

    # cv2.imshow("arrow", img)

    if len(rects) < 1:
        return 119
    maxRect2 = max(rects, key=lambda r: r['w']*r['h'])
    rects.remove(maxRect2)
    # while maxRect['w']*3 < maxRect['h'] or maxRect['w'] > 3*maxRect['h']:
    #    maxRect = max(rects, key=lambda r: r['w']*r['h'])
    #    rects.remove(maxRect)

    subImg2 = img_ori[maxRect2['y']:maxRect2['y']+maxRect2['h'],
                      maxRect2['x']:maxRect2['x']+maxRect2['w']].copy()
    cv2.rectangle(img_ori, (maxRect2['x'], maxRect2['y']), (
        maxRect2['x'] + maxRect2['w'], maxRect2['y'] + maxRect2['h']), (255, 255, 0), 2)

    # cv2.imshow("aaa", subImg1)
    # cv2.imshow("bbb", subImg2)

    if maxRect1['cy'] < maxRect2['cy']:
        return detectArrow(subImg2, detectWord(subImg1))
    else:
        return detectArrow(subImg1, detectWord(subImg2))

    # cv2.imshow("word", img)


def detectRoomName(img):
    global roomColor
    img_ori = img.copy()
    mask = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    mask_red = cv2.inRange(mask, tuple(red_low), tuple(red_up))
    mask_blue = cv2.inRange(mask, tuple(blue_low), tuple(blue_up))
    img_red = cv2.bitwise_and(img, img, mask=mask_red)
    img_blue = cv2.bitwise_and(img, img, mask=mask_blue)
    img_red = cv2.cvtColor(img_red, cv2.COLOR_BGR2GRAY)
    img_blue = cv2.cvtColor(img_blue, cv2.COLOR_BGR2GRAY)

    cv2.imshow("ss", img_blue)

    ret = detectRoomWord(img_red)
    roomColor = 1
    
    if ret == 149:
        ret = detectRoomWord(img_blue)
        if ret != 149:
            roomColor = 2
    return ret


def onChangeHMin(val):
    global lower_color
    lower_color[0] = val


def onChangeHMax(val):
    global upper_color
    upper_color[0] = val


def onChangeSMin(val):
    global lower_color
    lower_color[1] = val


def onChangeSMax(val):
    global upper_color
    upper_color[1] = val


def onChangeVMin(val):
    global lower_color
    lower_color[2] = val


def onChangeVMax(val):
    global upper_color
    upper_color[2] = val


def color_write():
    cv2.setTrackbarPos("H_min", "Trackbar Windows", lower_color[0])
    cv2.setTrackbarPos("H_max", "Trackbar Windows", upper_color[0])
    cv2.setTrackbarPos("S_min", "Trackbar Windows", lower_color[1])
    cv2.setTrackbarPos("S_max", "Trackbar Windows", upper_color[1])
    cv2.setTrackbarPos("V_min", "Trackbar Windows", lower_color[2])
    cv2.setTrackbarPos("V_max", "Trackbar Windows", upper_color[2])


cv2.namedWindow("Trackbar Windows")

cv2.createTrackbar("H_min", "Trackbar Windows", 0, 179, onChangeHMin)
cv2.createTrackbar("H_max", "Trackbar Windows", 0, 179, onChangeHMax)


cv2.createTrackbar("S_min", "Trackbar Windows", 0, 255, onChangeSMin)
cv2.createTrackbar("S_max", "Trackbar Windows", 0, 255, onChangeSMax)

cv2.createTrackbar("V_min", "Trackbar Windows", 0, 255, onChangeVMin)
cv2.createTrackbar("V_max", "Trackbar Windows", 0, 255, onChangeVMax)

color_write()


def getColorObject(img, lower, upper):
    mask = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    mask = cv2.inRange(mask, tuple(lower), tuple(upper))
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


def getBlackObject(img):
    img = cv2.bitwise_not(img)
    return getColorObject(img, invert_black_low, invert_black_up)


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
        center_point = (int(rect['cx']), int(rect['cy']))

    if (center_point[0] <= int(w_view*0.33)) and (center_point[1] <= int(h_view*0.33)):
        return 171
    elif(center_point[0] <= int(w_view*0.33*2)) and (center_point[1] <= int(h_view*0.33)):
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
        center_point = (int(rect['cx']), int(rect['cy']))

    if (center_point[0] <= int(w_view*0.33)) and (center_point[1] <= int(h_view*0.33)):
        return 181
    elif(center_point[0] <= int(w_view*0.33*2)) and (center_point[1] <= int(h_view*0.33)):
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
    w_view = viewSize[0]
    h_view = viewSize[1]
    for n_line in range(1, 3):
        cv2.line(img, (int(w_view*0.33*n_line), 0),
                 (int(w_view*0.33*n_line), h_view), (255, 255, 255), 1)
        cv2.line(img, (0, int(h_view * 0.33*n_line)),
                 (w_view, int(h_view * 0.33*n_line)), (255, 255, 255), 1)
    cv2.imshow("camera_grid", img)


def gotoObject(img):
    global roomColor
    if roomColor == 1:
        rect_blue = getColorObject(img, red_low, red_up)
    elif roomColor == 2:
        rect_blue = getColorObject(img, blue_low, blue_up)
    else:
        print("not detect room name")
        return 170
    rect = rect_blue
    gridline()
    if rect['w'] > 0:
        img = drawRects(img, [rect])
        return command_direction([rect])
    else:
        return 170


def pickObject(img):
    global roomColor
    if roomColor == 1:
        rect_blue = getColorObject(img, red_low, red_up)
    elif roomColor == 2:
        rect_blue = getColorObject(img, blue_low, blue_up)
    else:
        print("not detect room name")
        return 170
    rect = rect_blue
    gridline()
    if rect['w'] > 0:
        img = drawRects(img, [rect])
        return detect_object([rect])
    else:
        return 180


def putObject(img):
    rect_black = getBlackObject(img)
    rect = rect_black
    gridline()

    if rect['h'] > 80:
        print(rect)
        return 191

    else:
        return 192


def gotoEdge(img):
    rect_yellow = getColorObject(img, yellow_low, yellow_up)
    rect = rect_yellow
    gridline()
    if rect['h'] > 20:
        print(rect)
        return 193
    else:
        return 194


def detectDanger(img):
    rect_green = getColorObject(img, green_low, green_up)
    rectg = rect_green

    rect_black = getBlackObject(img)
    rectk = rect_black

    print("green rect", rectg)

    print("black rect2", rectk)

    if (rectg['w']*rectg['h']) > 25000:
        return 195
    elif (rectk['w']*rectk['h'] > 25000):
        return 196
    else:
        return 197


'''
def backToLine(img):
    rect = getColorObject(img, yellow_low, yellow_up)
    gridline()
    cv2.rectangle(img, (rect['x'], rect['y']), (rect['x'] +
                  rect['w'], rect['y']+rect['h']), (255, 255, 0), 2)
    cv2.imshow("adsf", img)

    if rect['w'] > 0:
        img = drawRects(img, [rect])
        return command_direction([rect])
    else:
        return 170
'''


def checkLineExisted(img):
    if traceLine(img) != 109:
        return 200
    else:
        return 201


actionFunc = {150: detectLine, 151: detectDirection,
              152: detectRoomName, 153: gotoObject, 154: pickObject, 155: putObject, 156: gotoEdge, 157: detectDanger, 158: checkLineExisted}

sendTX(99)
while True:
    key = cv2.waitKey(1) & 0xFF
    _, img = cap.read()
    #rx = 150
    rx = receiveRX()
    # img = CutImg(img, rx)
    if rx != 0:
        tx = actionFunc[rx](img)
        sendTX(tx)
    cv2.imshow("camera", img)

    if key == ord('r'):
        lower_color = red_low
        upper_color = red_up
        print(red_low, red_up)
        color_write()

    elif key == ord('g'):
        lower_color = green_low
        upper_color = green_up
        print(green_low, green_up)
        color_write()

    elif key == ord('b'):
        lower_color = blue_low
        upper_color = blue_up
        print(blue_low, blue_up)
        color_write()

    elif key == ord('y'):
        lower_color = yellow_low
        upper_color = yellow_up
        print(yellow_low, yellow_up)
        color_write()

    elif key == ord('w'):
        lower_color = white_low
        upper_color = white_up
        print(white_low, white_up)
        color_write()

    elif key == ord('k'):
        lower_color = invert_black_low
        upper_color = invert_black_up
        print(invert_black_low, invert_black_up)
        color_write()
