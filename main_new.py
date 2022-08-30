import serial
import cv2
import os
import pytesseract
from PIL import Image

ser = serial.Serial('/dev/ttyS0', 4800, timeout=0.01)
cap = cv2.VideoCapture(0)
cap.set(3, 320)
cap.set(4, int(320/1.333))
cap.set(5, 30)  # FPS 30으로 설정
yellow_range = [(15, 100, 0), (45, 455, 455)]
black_range = [(0, 0, 200), (179, 80, 255)]


# 로보베이직으로 값을 보냄
def sendTX(data):
    ser.write(serial.to_bytes([data]))
    print("send", data)


# 로보베이직에서 보낸 데이터 값을 받아옴
def receiveRX():
    if ser.inWaiting() > 0:
        return ord(ser.read(1))
    else:
        return 0


# 라인트레이싱 영상처리
# 160: 직진
# 161,162: 방향 조절 필요
# 163,164: 좌우 이동 필요
# 165: 선 못찾음, 오류 발생
def traceLine(img):
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
            try:
                y1 = int((-x*vy/vx)+y)
                y2 = int(((cols-x)*vy/vx)+y)
                deg = getDegree((0, y1), (cols-1, y2))
                resultDeg = round(getSubDegree(90, deg), 1)
                if deg > 0:
                    deg = resultDeg
                else:
                    deg = -resultDeg

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
                print(e)
            finally:
                return 165
    return 165


# 문자인식 영상처리
# 140~143: 동쪽 서쪽 남쪽 북쪽인식
# 144: 문자못찾음 또는 오류발생
def detectDirection(img):
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
                return txs[text[0]]
        except:
            return 144
    return 144


while True:
    cv2.waitKey(1)
    _, img = cap.read()
    rx = receiveRX()
    print("receive", rx)
    if rx == 150:
        sendTX(traceLine(img.copy()))
    elif rx == 151:
        sendTX(detectDirection(img.copy()))
    cv2.imshow("camera", img)
