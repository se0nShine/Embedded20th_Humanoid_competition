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
        #return 122
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
        #return 120
    elif (ang1 < -numpy.pi/8 and ang1 > -3*numpy.pi/8) and (ang2 > numpy.pi/8 and ang2< 3*numpy.pi/8):
        cv2.putText(res, 'Right', (0, 50), 0, 1, (0, 255, 0), 2)
        cv2.imshow("traceLine", res)
        #return 121
    else:
        cv2.putText(res, '', (0, 50), 0, 1, (0, 255, 0), 2)
        cv2.imshow("traceLine", res)
        #return 122
        
