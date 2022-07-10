from charset_normalizer import detect
from numpy import rec
import pytesseract
import os
from PIL import Image
from util import *

pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract'

alpha = ''
color = ''


def detectAlpha(img):
    global alpha
    alphas = ['A', 'B', 'C', 'D', 'N', 'S', 'W', 'E']
    img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    _, img = cv2.threshold(img, 0, 255, cv2.THRESH_BINARY+cv2.THRESH_OTSU)
    img = cv2.copyMakeBorder(
        img, 50, 50, 50, 50, cv2.BORDER_CONSTANT, value=(255, 255, 255))
    cv2.imshow("detect", img)
    filename = "{}.png".format(os.getpid())
    cv2.imwrite(filename, img)
    text = pytesseract.image_to_string(
        Image.open(filename), config="--psm 10", lang='eng')  # 이미지에서 문자를 인식해서 나온 결과를 text에 저장
    os.remove(filename)
    try:
        if alphas.count(text[0]) > 0:
            alpha = text[0]
        else:
            alpha = ''
    except:
        alpha = ''


def getMessage(alpha, color):
    message = ''
    roomAlphas = ['A', 'B', 'C', 'D']
    directionAlphas = ['N', 'S', 'W', 'E']
    direction = {'N': 'North', 'S': 'South', 'W': 'West', 'E': 'East'}
    if roomAlphas.count(alpha) > 0:
        message = 'Find {} citizen in room {}'.format(color, alpha)
    elif directionAlphas.count(alpha) > 0:
        message = 'Shout "{}"'.format(direction[alpha])
    return message


while True:
    input = cv2.waitKey(1)
    _, img = capture.read()  # 카메라 캡쳐
    img_focus = cv2.getRectSubPix(
        img, (focus['w'], focus['h']), (focus['cx'], focus['cy']))  # 인식 영역만큼 자르기

    rect_black = getBlackObject(img_focus)
    rect_blue = getColorObject(img_focus, (105, 50, 0), (135, 255, 255))
    rect_red1 = getColorObject(img_focus, (0, 50, 0), (15, 255, 255))
    rect_red2 = getColorObject(img_focus, (165, 50, 0), (179, 255, 255))
    rect_red = max([rect_red1, rect_red2], key=lambda r: (r['w']*r['h']))

    rect = max([rect_blue, rect_red],
               key=lambda r: (r['w']*r['h']))
    if rect['w'] <= 0:
        rect = rect_black

    if rect['w'] > 0:
        img_alpha = cv2.getRectSubPix(img_focus, (int(rect['w']), int(
            rect['h'])), (int(rect['cx']), int(rect['cy'])))
        img = drawRects(img, [rect])
        if input == 13:
            detectAlpha(img_alpha)
            if rect == rect_blue:
                color = 'Blue'
            elif rect == rect_red:
                color = 'Red'
            else:
                color = 'Black'
    if alpha != '' and color != '':
        img = drawText(img, 1, 'Text: '+alpha)
        img = drawText(img, 2, 'Color: '+color)

    #img = drawText(img, 9, 'Press enter to detect text.')

    cv2.rectangle(img, (focus['x'], focus['y']), (focus['x']+focus['w'], focus['y']+focus['h']),
                  (255, 255, 255), 2)  # 인식 영역 표시하기
    cv2.imshow("camera", img)
