import serial
import cv2
import os
import pytesseract
import math
import numpy
from PIL import Image


ser = serial.Serial('/dev/ttyS0', 4800, timeout=0.01)
cap = cv2.VideoCapture(0)
viewSize = (320, int(320/1.333))
cap.set(3, viewSize[0])
cap.set(4, viewSize[1])
cap.set(5, 30)  # FPS 30으로 설정
yellow_range = [(15, 100, 0), (45, 455, 455)]
black_range = [(0, 0, 200), (179, 80, 255)]


def getDegree(p1, p2):
    rad = math.atan(float(p2[1]-p1[1])/(p2[0]-p1[0]))
    return round(rad*(180/(numpy.pi)), 3)
    
def getDistance(p1, p2):
    return math.sqrt((p1[0]-p2[0])*(p1[0]-p2[0])+(p1[1]-p2[1])*(p1[1]-p2[1]))


def getSubDegree(deg1, deg2):
    ang1 = max(deg1, deg2)-min(deg1, deg2)
    ang2 = 180-ang1
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


# 라인트레이싱 영상처리
# 160: 직진
# 161,162: 방향 조절 필요
# 163,164: 좌우 이동 필요
# 165: 선 못찾음, 오류 발생
def traceLine(img):
    res = img
    mask = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    mask = cv2.inRange(mask, yellow_range[0], yellow_range[1])
    img = cv2.bitwise_and(img, img, mask=mask)
    contours, _ = cv2.findContours(mask, 1, cv2.CHAIN_APPROX_NONE)
    if len(contours) > 0:
        c = max(contours, key=cv2.contourArea)
        M = cv2.moments(c)
        if M["m00"] != 0:
            cx = int(M['m10']/M['m00'])
            _, cols = img.shape[:2]
            [vx, vy, x, y] = cv2.fitLine(c, cv2.DIST_L2, 0, 0.01, 0.01)
            cv2.line(res, (cx, 0), (cx, viewSize[1]), (0, 0, 255), 3)
            cv2.drawContours(res, c, -1, (0, 255, 0), 2)
            try:
                y1 = int((-x*vy/vx)+y)
                y2 = int(((cols-x)*vy/vx)+y)
                deg = getDegree((0, y1), (cols-1, y2))
                resultDeg = round(getSubDegree(90, deg), 1)
                if deg > 0:
                    deg = resultDeg
                else:
                    deg = -resultDeg

                cv2.putText(res, str(deg), (0, 50), 0, 1, (0, 255, 0), 2)
                cv2.imshow("traceLine", res)
                
                if deg <= -10:
                    return 162
                elif deg >= 10:
                    return 161
                else:
                    if cx <= 120:
                        return 163
                    elif cx >= 200:
                        return 164
                    else:
                        return 160
            except Exception as e:
                if str(e) !='0':
                    print('error: ',e)
                return 165
            finally:
                cv2.imshow("traceLine", res)
                
    return 165


# 방향인식 영상처리
# 140~143: 동쪽 서쪽 남쪽 북쪽인식
# 144: 문자못찾음 또는 오류발생
def detectDirection(img):
    res = img
    img = cv2.bitwise_not(img)
    mask = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    mask = cv2.inRange(mask, black_range[0], black_range[1])
    img = cv2.bitwise_and(img, img, mask=mask)
    img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    contours, _ = cv2.findContours(
        img, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if len(contours) > 0:
        alphas = ['A', 'B', 'C', 'D', 'N', 'S', 'W', 'E']
        txs = {'E': 140, 'W': 141, 'S': 142, 'N': 143}
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
        except Exception as e:
            if str(e) !='0':
                print('error: ',e)
            return 144
        finally:
            cv2.imshow("detectDirection", res)
            
    return 144


# 화살표인식
# 120,121: 왼쪽,오른쪽
# 122: 화살표인식 못함
def detectArrow(img):
    res = img
    img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    _, img = cv2.threshold(img, 0, 255, cv2.THRESH_BINARY+cv2.THRESH_OTSU)
    img = cv2.copyMakeBorder(
        img, 50, 50, 50, 50, cv2.BORDER_CONSTANT, value=(255, 255, 255))

    img = cv2.Canny(img, 200, 200)
    lines = cv2.HoughLinesP(img, rho=1, theta=numpy.pi/180.0, threshold=30)

    if lines is None:
        cv2.putText(res, '', (0, 50), 0, 1, (0, 255, 0), 2)
        cv2.imshow("traceLine", res)
        return 122
    temp = []
    for line in lines:
        x1, y1, x2, y2 = line[0]
        temp.append(line[0])
    x1, y1, x2, y2 = min(temp, key=lambda l: min(l[1], l[3]))
    x3, y3, x4, y4 = max(temp, key =lambda l: max(l[1], l[3]))

    ang1 = math.atan(float(y2-y1)/(x2-x1))
    ang2 = math.atan(float(y2-y1)/(x2-x1))

    img = cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)
    cv2.line(res, (x1, y1), (x2, y2), (0, 255, 0), 3, cv2.LINE_AA)
    cv2.line(res, (x3, y3), (x4, y4), (0, 255, 0), 3, cv2.LINE_AA)

    if (ang1 > numpy.pi/8 and ang1 < 3*numpy.pi/8) and (ang2 < -numpy.pi/8 and ang2 > -3*numpy.pi/8):
        cv2.putText(res, 'Left', (0, 50), 0, 1, (0, 255, 0), 2)
        cv2.imshow("traceLine", res)
        return 120
    elif (ang1 < -numpy.pi/8 and ang1 > -3*numpy.pi/8) and (ang2 > numpy.pi/8 and ang2< 3*numpy.pi/8):
        cv2.putText(res, 'Right', (0, 50), 0, 1, (0, 255, 0), 2)
        cv2.imshow("traceLine", res)
        return 121
    else:
        cv2.putText(res, '', (0, 50), 0, 1, (0, 255, 0), 2)
        cv2.imshow("traceLine", res)
        return 122



def detectCorner(img):

    mask =cv2.cvtColor(img,cv2.COLOR_BGR2HSV)
    mask=cv2.inRange(mask,(15,100,0),(45,255,255))
    img=cv2.bitwise_and(img,img,mask=mask)
    img=cv2.cvtColor(img,cv2.COLOR_BGR2GRAY)
    _,img=cv2.threshold(img,0,255,cv2.THRESH_BINARY+cv2.THRESH_OTSU)
    skel=numpy.zeros(img.shape,numpy.uint8)
    element=cv2.getStructuringElement(cv2.MORPH_CROSS,(3,3))
    
    open = cv2.morphologyEx(img, cv2.MORPH_OPEN, element)
    temp = cv2.subtract(img, open)
    eroded = cv2.erode(img, element)
    skel = cv2.bitwise_or(skel, temp)
    img = eroded.copy()
        
    if cv2.countNonZero(img) == 0:
        return 133
    edges = cv2.Canny(skel, 200, 200)
    linesP = cv2.HoughLinesP(edges, 1, numpy.pi/180, 30)
    cdstP = cv2.cvtColor(edges, cv2.COLOR_GRAY2BGR)
    
    if linesP is not None:
        for line in range(0, len(linesP)):
            I = linesP[line][0]
        temps = []
        points = []
        for line in linesP:
            x1, y1, x2, y2 = line[0]
            rad = math.atan(float(y2-y1)/(x2-x1))
            deg = round(rad*(180/(numpy.pi)), 3)
            temps.append([x1, y1, x2, y2, deg])
            points.append([x1, y1])
            points.append([x2, y2])
        stn = max(temps, key=lambda l: max(l[1], l[3]))
        if stn[1] > stn[3]:
            stn_point = [stn[0], stn[1]]
        else:
            stn_point = [stn[2], stn[3]]
        left_point = min(points, key=lambda p: p[0]) #points 중x값중에 제일 작은거
        right_point = max(points, key=lambda p: p[0]) #Points 중 x값중 제일 큰거

        stn_deg = stn[4]
        print_deg = stn_deg
        if print_deg < 0:
            print_deg += 180
        cv2.circle(cdstP, (stn_point[0], stn_point[1]), 5, (255, 255, 255), -1)

        if getDistance(left_point, stn_point) < 30:
            left_deg = stn_deg
        else:
            left_deg = getDegree(left_point, stn_point)
        cv2.line(cdstP, (stn_point[0], stn_point[1]), (left_point[0], left_point[1]),
                 (0, 255, 0), 3, cv2.LINE_AA)
        left_deg = getSubDegree(stn_deg, left_deg)
        left = left_deg >= 15 and left_deg <= 75

        if getDistance(right_point, stn_point) < 30:
            right_deg = stn_deg
        else:
            right_deg = getDegree(right_point, stn_point)
        cv2.line(cdstP, (stn_point[0], stn_point[1]), (right_point[0], right_point[1]),
                 (0, 255, 0), 3, cv2.LINE_AA)
        right_deg = getSubDegree(stn_deg, right_deg)
        right = right_deg >= 15 and right_deg <= 75
        
        if right and left:
            return 130
        elif right and not(left):
            return 131
        elif not(right) and left:
            return 132
        else:
            return 133
        
        if not math.isnan(print_deg):
            cv2.line(cdstP, (stn[0], stn[1]), (stn[2], stn[3]),
                     (0, 0, 255), 3, cv2.LINE_AA)
        
        cv2.imshow("detectCorner", cdstP)
    return 133

def detectLine(img):
    tx=detectCorner(img)
    if tx==133:
        return traceLine(img)
    return tx

actionFunc = {150: detectLine, 151: detectDirection, 152: detectArrow}


sendTX(128)
while True:
    cv2.waitKey(1)
    _, img = cap.read()
    rx = receiveRX()
    try:
        tx = actionFunc[rx](img)
        sendTX(tx)
    except Exception as e:
        if str(e) !='0':
            print('main loop error: ',e)
    cv2.imshow("camera", img)
