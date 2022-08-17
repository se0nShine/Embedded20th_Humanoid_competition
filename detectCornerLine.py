from util import *
import math
import numpy as np

left = False
right = False
direction = ''


def getDegree(p1, p2):
    rad = math.atan(float(p2[1]-p1[1])/(p2[0]-p1[0]))
    return round(rad*(180/(np.pi)), 3)


def getDistance(p1, p2):
    return math.sqrt((p1[0]-p2[0])*(p1[0]-p2[0])+(p1[1]-p2[1])*(p1[1]-p2[1]))


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


def detectLine(img):
    global left, right, direction
    mask = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)  

    mask = cv2.inRange(mask, (15, 100, 0), (45, 255, 255))
    img = cv2.bitwise_and(img, img, mask=mask)  
    img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    _, img = cv2.threshold(img, 0, 255, cv2.THRESH_BINARY+cv2.THRESH_OTSU)
# Step 1: Create an empty skeleton
    skel = np.zeros(img.shape, np.uint8)

# Get a Cross Shaped Kernel
    element = cv2.getStructuringElement(cv2.MORPH_CROSS, (3, 3))
# Repeat steps 2-4
    while True:
        # Step 2: Open the image
        open = cv2.morphologyEx(img, cv2.MORPH_OPEN, element)
        # Step 3: Substract open from the original image
        temp = cv2.subtract(img, open)
        # Step 4: Erode the original image and refine the skeleton
        eroded = cv2.erode(img, element)
        skel = cv2.bitwise_or(skel, temp)
        img = eroded.copy()
        # Step 5: If there are no white pixels left ie.. the image has been completely eroded, quit the loop
        if cv2.countNonZero(img) == 0:
            break
    edges = cv2.Canny(skel, 200, 200)
    linesP = cv2.HoughLinesP(edges, 1, np.pi/180, 30)

    cdstP = cv2.cvtColor(edges, cv2.COLOR_GRAY2BGR)

    if linesP is not None:
        for line in range(0, len(linesP)):
            I = linesP[line][0]
        temps = []
        points = []
        for line in linesP:
            x1, y1, x2, y2 = line[0]
            rad = math.atan(float(y2-y1)/(x2-x1))
            deg = round(rad*(180/(np.pi)), 3)
            temps.append([x1, y1, x2, y2, deg])
            points.append([x1, y1])
            points.append([x2, y2])

        stn = max(temps, key=lambda l: max(l[1], l[3]))
        if stn[1] > stn[3]:
            stn_point = [stn[0], stn[1]]
        else:
            stn_point = [stn[2], stn[3]]
        left_point = min(points, key=lambda p: p[0])
        right_point = max(points, key=lambda p: p[0])

        stn_deg = stn[4]
        print_deg = stn_deg
        if print_deg < 0:
            print_deg += 180

        # cv2.putText(cdstP, str(stn_deg),
        #            (stn_point[0], stn_point[1]), 0, 1, (255, 0, 255), 1)

        cv2.circle(cdstP, (stn_point[0], stn_point[1]), 5, (255, 255, 255), -1)

        if getDistance(left_point, stn_point) < 30:
            left_deg = stn_deg
        else:
            left_deg = getDegree(left_point, stn_point)
        cv2.line(cdstP, (stn_point[0], stn_point[1]), (left_point[0], left_point[1]),
                 (0, 255, 0), 3, cv2.LINE_AA)
        # cv2.putText(cdstP, str(left_deg),
        #            (left_point[0], left_point[1]), 0, 1, (0, 244, 255), 1)
        left_deg = getSubDegree(stn_deg, left_deg)
        left = left_deg >= 15 and left_deg <= 75

        if getDistance(right_point, stn_point) < 30:
            right_deg = stn_deg
        else:
            right_deg = getDegree(right_point, stn_point)
        cv2.line(cdstP, (stn_point[0], stn_point[1]), (right_point[0], right_point[1]),
                 (0, 255, 0), 3, cv2.LINE_AA)
        # cv2.putText(
        #    cdstP, str(right_deg), (right_point[0], right_point[1]), 0, 1, (0, 244, 255), 1)
        right_deg = getSubDegree(stn_deg, right_deg)
        right = right_deg >= 15 and right_deg <= 75

        if not math.isnan(print_deg):
            direction = str(abs(print_deg))
            cv2.line(cdstP, (stn[0], stn[1]), (stn[2], stn[3]),
                     (0, 0, 255), 3, cv2.LINE_AA)

        cv2.imshow("detect", cdstP)


while True:
    input = cv2.waitKey(1)
    _, img = capture.read()
    img_focus = cv2.getRectSubPix(
        img, (focus['w'], focus['h']), (focus['cx'], focus['cy'])) 
    rect = getColorObject(img_focus, (15, 100, 0), (45, 255, 255))
    if rect['w'] > 0:
        img_line = cv2.copyMakeBorder(
            img_focus, 10, 10, 10, 10, cv2.BORDER_CONSTANT, value=(255, 255, 255))
        detectLine(img_line)

    #img = drawText(img, 2, direction+' deg')
    if right:
        img = drawText(img, 1, '                                   Right')
    if left:
        img = drawText(img, 1, 'Left')

    cv2.rectangle(img, (focus['x'], focus['y']), (focus['x']+focus['w'], focus['y']+focus['h']),
                  (255, 255, 255), 2)  
    cv2.imshow("camera", img)
