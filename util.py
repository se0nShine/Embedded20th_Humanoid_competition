import cv2

capture = cv2.VideoCapture(1)
cw = int(capture.get(cv2.CAP_PROP_FRAME_WIDTH))  # 카메라 가로 크기
ch = int(capture.get(cv2.CAP_PROP_FRAME_HEIGHT))  # 카메라 세로 크기
focus = {'x': cw//4, 'y': ch//4, 'w': cw//2,
         'h': ch//2, 'cx': cw//2, 'cy': ch//2}  # 인식 영역
black_range = [(0, 0, 200), (179, 50, 255)]


def getColorObject(img, lower, upper):  # 특정 색상의 물체 위치를 찾는 함수
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


def getBlackObject(img):  # 검은색 물체 위치를 찾는 함수
    img = cv2.bitwise_not(img)
    return getColorObject(img, black_range[0], black_range[1])


def drawRects(img, rects):  # 이미지에 사각형들을 그려주는 함수
    for rect in rects:
        pt1 = (focus['x']+int(rect['x']), focus['y']+int(rect['y']))
        pt2 = (pt1[0]+int(rect['w']), pt1[1]+int(rect['h']))
        cv2.rectangle(img, pt1, pt2, (0, 255, 0), 2)
    return img


def drawText(img, y, text):
    cv2.putText(img, text, (0, y*50), 0, 1, (0, 255, 0), 2)
    return img
