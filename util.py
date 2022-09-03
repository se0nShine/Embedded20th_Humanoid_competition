import cv2

capture = cv2.VideoCapture(0)
W_View_size = 320
H_View_size = int(W_View_size/1.333)
FPS = 30
capture.set(3, W_View_size)
capture.set(4, H_View_size)
capture.set(5, FPS)


cw = int(capture.get(cv2.CAP_PROP_FRAME_WIDTH))
ch = int(capture.get(cv2.CAP_PROP_FRAME_HEIGHT))
focus = {'x': 0, 'y': 0, 'w': cw,
         'h': ch, 'cx': cw//2, 'cy': ch//2}
black_range = [(0, 0, 200), (179, 50, 255)]


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


def getBlackObject(img):
    img = cv2.bitwise_not(img)
    return getColorObject(img, black_range[0], black_range[1])


def drawRects(img, rects):
    for rect in rects:
        pt1 = (focus['x']+int(rect['x']), focus['y']+int(rect['y']))
        pt2 = (pt1[0]+int(rect['w']), pt1[1]+int(rect['h']))
        cv2.rectangle(img, pt1, pt2, (0, 255, 0), 2)
    return img


def drawText(img, y, text):
    cv2.putText(img, text, (0, y*50), 0, 1, (0, 255, 0), 2)
    return img
