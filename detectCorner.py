def detectCorner(img):
    open = cv2.morphologyEx(img, cv2.MORPH_OPEN, element)
    temp = cv2.subtract(img, open)
    eroded = cv2.erode(img, element)
    skel = cv2.bitwise_or(skel, temp)
    img = eroded.copy()
        
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
            return #앞으로 세발자국 걷기
        elif right and not(left):
            return #고개들어서 왼쪽으로 45도턴하고 고개내려서 위험지역인지 안전지역인지 판단
        elif not(right) and left:
            return #고개들어서 오른쪽으로 45도턴하고 고개내려서 위험지역인지 안전지역인지 판단
        else:
            return #라인트레이싱
        
        if not math.isnan(print_deg):
            cv2.line(cdstP, (stn[0], stn[1]), (stn[2], stn[3]),
                     (0, 0, 255), 3, cv2.LINE_AA)
        
        cv2.imshow("detectCorner", cdstP)
    else:
        pass
