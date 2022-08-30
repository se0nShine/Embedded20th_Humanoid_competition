'******** 2족 보행로봇 초기 영점 프로그램 ********

DIM I AS BYTE
DIM J AS BYTE
DIM MODE AS BYTE
DIM A AS BYTE
DIM A_old AS BYTE
DIM B AS BYTE
DIM C AS BYTE
DIM 보행속도 AS BYTE
DIM 좌우속도 AS BYTE
DIM 좌우속도2 AS BYTE
DIM 보행순서 AS BYTE
DIM 현재전압 AS BYTE
DIM 반전체크 AS BYTE
DIM 모터ONOFF AS BYTE
DIM 자이로ONOFF AS BYTE
DIM 기울기앞뒤 AS INTEGER
DIM 기울기좌우 AS INTEGER

DIM 곡선방향 AS BYTE

DIM 넘어진확인 AS BYTE
DIM 기울기확인횟수 AS BYTE
DIM 보행횟수 AS BYTE
DIM 보행COUNT AS BYTE

DIM 적외선거리값  AS BYTE

DIM S11  AS BYTE
DIM S16  AS BYTE
'************************************************
DIM NO_0 AS BYTE
DIM NO_1 AS BYTE
DIM NO_2 AS BYTE
DIM NO_3 AS BYTE
DIM NO_4 AS BYTE

DIM NUM AS BYTE

DIM BUTTON_NO AS INTEGER
DIM SOUND_BUSY AS BYTE
DIM TEMP_INTEGER AS INTEGER

'**** 기울기센서포트 설정 ****
CONST 앞뒤기울기AD포트 = 0
CONST 좌우기울기AD포트 = 1
CONST 기울기확인시간 = 20  'ms

CONST 적외선AD포트  = 4
7

CONST min = 61	'뒤로넘어졌을때
CONST max = 107	'앞으로넘어졌을때
CONST COUNT_MAX = 3


CONST 머리이동속도 = 10
'************************************************



PTP SETON 				'단위그룹별 점대점동작 설정
PTP ALLON				'전체모터 점대점 동작 설정

DIR G6A,1,0,0,1,0,0		'모터0~5번
DIR G6D,0,1,1,0,1,1		'모터18~23번
DIR G6B,1,1,1,1,1,1		'모터6~11번
DIR G6C,0,0,0,0,1,0		'모터12~17번

'************************************************

OUT 52,0	'머리 LED 켜기
'***** 초기선언 '************************************************

보행순서 = 0
반전체크 = 0
기울기확인횟수 = 0
보행횟수 = 1
모터ONOFF = 0

'****초기위치 피드백*****************************


TEMPO 230
MUSIC "cdefg"



SPEED 5
GOSUB MOTOR_ON

S11 = MOTORIN(11)
S16 = MOTORIN(16)

SERVO 11, 100
SERVO 16, S16

SERVO 16, 100


GOSUB 전원초기자세
GOSUB 기본자세


GOSUB 자이로INIT
GOSUB 자이로MID
GOSUB 자이로ON



PRINT "VOLUME 200 !"
PRINT "SOUND 12 !" '안녕하세요

GOSUB All_motor_mode3


'************************************************
DIM 반복횟수 AS BYTE
DIM arrow AS INTEGER
arrow=0
DIM dis AS INTEGER
DIM dis_old AS INTEGER
dis=0
dis_old=0
DIM go AS BYTE
go=0


GOTO MAIN	'시리얼 수신 루틴으

MAIN:
	IF go=0 THEN
		ERX 4800,A,MAIN
		IF A=128  THEN
			PRINT "SOUND 12 !"
			go=1
		ENDIF
	ENDIF
	
    IF arrow=0 THEN
    	dis_old=dis
    	dis=0
    	GOSUB 적외선거리센서확인
    	IF dis>50 THEN
    		GOSUB 기본자세
    		ETX 4800,151
    		GOTO CHECKALPHA
    	ELSE
    		IF dis_old>50 THEN
    			MOVE G6C,100,  30,  80, 100, 25, 100
    		ENDIF
    		ETX 4800,150
    		GOTO CHECKLINE
    	ENDIF
 
    ENDIF
    
    GOTO MAIN

CHECKLINE:
	
	ERX 4800,A,CHECKLINE
	A_old = A
	
	
	IF A=160 THEN
   		보행횟수= 1
     	GOTO 전진횟수보행50
    ELSEIF A=161 THEN
    	GOTO 왼쪽턴10
    ELSEIF A=162 THEN
    	GOTO 오른쪽턴10
	ELSEIF A=163 THEN
    	GOTO 연속왼쪽옆으로70
    ELSEIF A=164 THEN
    	GOTO 연속오른쪽옆으로70
    ELSE
    	GOTO MAIN
	ENDIF
	

CHECKALPHA:
	ERX 4800,A,CHECKALPHA
	
	IF A=140 THEN
     	GOTO East
    ELSEIF A=141 THEN
    	GOTO West
    ELSEIF A=142 THEN
    	GOTO South
	ELSEIF A=143 THEN
    	GOTO North
    ELSE
    	GOTO MAIN
	ENDIF
    
East:
	MOVE G6A,100, 56, 182, 76, 100, 100
    MOVE G6D,100, 56, 182, 76, 100, 100
    MOVE G6B,100,  30,  80
	MOVE G6C,190,  30,  80
	GOTO MAIN
West:
	MOVE G6A,100, 56, 182, 76, 100, 100
    MOVE G6D,100, 56, 182, 76, 100, 100
    MOVE G6B,190,  30,  80
	MOVE G6C,100,  30,  80
	GOTO MAIN
North:
	MOVE G6A,100, 56, 182, 76, 100, 100
    MOVE G6D,100, 56, 182, 76, 100, 100
    MOVE G6B,190,  30,  80
	MOVE G6C,190,  30,  80
	GOTO MAIN
South:
	MOVE G6A,100, 56, 182, 76, 100, 100
    MOVE G6D,100, 56, 182, 76, 100, 100
    MOVE G6B,10,  30,  80
	MOVE G6C,10,  30,  80
	GOTO MAIN
    
    '************************************* 
전진횟수보행50:
    반복횟수 = 0
    GOSUB Leg_motor_mode3     
    IF 보행순서 = 0 THEN
        보행순서 = 1         
        SPEED 3         '오른쪽기울기
        MOVE G6A, 88,  71, 152,  91, 110
        MOVE G6D,108,  76, 146,  93,  94
        MOVE G6B,100,35
        MOVE G6C,100,35,80, 100, 25, 100     
        WAIT
        SPEED 10'보행속도         '왼발들기
        MOVE G6A, 90, 100, 115, 105, 114
        MOVE G6D,113,  78, 146,  93,  94
        MOVE G6B,90
        MOVE G6C,110
        WAIT
        GOTO 전진횟수보행50_1     
    ELSE
        보행순서 = 0         
        SPEED 3         '왼쪽기울기
        MOVE G6D,  88,  71, 152,  91, 110
        MOVE G6A, 108,  76, 146,  93,  94
        MOVE G6C, 100,35,80, 100, 25, 100
        MOVE G6B, 100,35
        WAIT
        SPEED 10'보행속도         '오른발들기
        MOVE G6D, 90, 100, 115, 105, 114
        MOVE G6A,113,  78, 146,  93,  94
        MOVE G6C,90
        MOVE G6B,110
        WAIT
        GOTO 전진횟수보행50_2
    ENDIF
      
전진횟수보행50_1:
    반복횟수 = 반복횟수 + 1     
    SPEED 10
    '왼발뻣어착지
    MOVE G6A, 85,  44, 163, 113, 114     
    MOVE G6D,110,  77, 146,  93,  94     
    WAIT
    SPEED 4     '왼발중심이동
    MOVE G6A,110,  76, 144, 100,  93     
    MOVE G6D,85, 93, 155,  71, 112     
    WAIT
    SPEED 10     '오른발들기10
    MOVE G6A,111,  77, 146,  93, 94
    MOVE G6D,90, 100, 105, 110, 114
    MOVE G6B,110
    MOVE G6C,90
    WAIT
    IF 반복횟수 >= 보행횟수 THEN         
        HIGHSPEED SETOFF         
        SPEED 5
        '왼쪽기울기2
        MOVE G6A, 106,  76, 146,  93,  96
        MOVE G6D,  88,  71, 152,  91, 106
        MOVE G6B, 100,35
        MOVE G6C, 100,35
        WAIT
        SPEED 3
        'GOSUB 기본자세         
        GOSUB Leg_motor_mode1
        GOTO MAIN     
    ENDIF
    
전진횟수보행50_2:
    반복횟수 = 반복횟수 + 1     
    SPEED 10
    '오른발뻣어착지
    MOVE G6D,85,  44, 163, 113, 114     
    MOVE G6A,110,  77, 146,  93,  94     
    WAIT
    SPEED 4
    '오른발중심이동
    MOVE G6D,110,  76, 144, 100,  93     
    MOVE G6A, 85, 93, 155,  71, 112     
    WAIT
    SPEED 10     '왼발들기10
    MOVE G6A, 90, 100, 105, 110, 114
    MOVE G6D,111,  77, 146,  93,  94
    MOVE G6B, 90
    MOVE G6C,110
    WAIT
    IF 반복횟수 >= 보행횟수 THEN
        HIGHSPEED SETOFF      
        SPEED 5
        '오른쪽기울기2
        MOVE G6D, 106,  76, 146,  93,  96
        MOVE G6A,  88,  71, 152,  91, 106
        MOVE G6C, 100,35
        MOVE G6B, 100,35
        WAIT
        SPEED 3
        'GOSUB 기본자세     
        GOSUB Leg_motor_mode1         
        GOTO MAIN
    ENDIF
    GOTO 전진횟수보행50_1
    '*********************************************
왼쪽턴10:
    MOTORMODE G6A,3,3,3,3,2
    MOTORMODE G6D,3,3,3,3,2
    SPEED 5
    MOVE G6A,97,  86, 145,  83, 103, 100
    MOVE G6D,97,  66, 145,  103, 103, 100
    WAIT

    SPEED 12
    MOVE G6A,94,  86, 145,  83, 101, 100
    MOVE G6D,94,  66, 145,  103, 101, 100
    WAIT

    SPEED 6
    MOVE G6A,101,  76, 146,  93, 98, 100
    MOVE G6D,101,  76, 146,  93, 98, 100
    WAIT
    DELAY 300
    'ERX 4800,A,왼쪽턴10     
    'IF A <> A_old THEN
    	
     '   GOTO MAIN     
    'ENDIF
  	GOTO MAIN
    GOTO 왼쪽턴10

    '**********************************************
오른쪽턴10:
    MOTORMODE G6A,3,3,3,3,2
    MOTORMODE G6D,3,3,3,3,2
    SPEED 5
    MOVE G6A,97,  66, 145,  103, 103, 100
    MOVE G6D,97,  86, 145,  83, 103, 100
    WAIT

    SPEED 12
    MOVE G6A,94,  66, 145,  103, 101, 100
    MOVE G6D,94,  86, 145,  83, 101, 100
    WAIT
    SPEED 6
    MOVE G6A,101,  76, 146,  93, 98, 100
    MOVE G6D,101,  76, 146,  93, 98, 100
    WAIT
    DELAY 300
    'ERX 4800,A,오른쪽턴10
    'IF A <> A_old THEN
    	
     '   GOTO MAIN     
    'ENDIF
    GOTO MAIN
    GOTO 오른쪽턴10
    
    '********************************************** 
왼쪽턴20:
    GOSUB Leg_motor_mode2     
    SPEED 8
    MOVE G6A,95,  96, 145,  73, 105, 100
    MOVE G6D,95,  56, 145,  113, 105, 100
    MOVE G6B,110
    MOVE G6C,90
    WAIT     
    SPEED 12
    MOVE G6A,93,  96, 145,  73, 105, 100     
    MOVE G6D,93,  56, 145,  113, 105, 100     
    WAIT
    SPEED 6
    MOVE G6A,101,  76, 146,  93, 98, 100
    MOVE G6D,101,  76, 146,  93, 98, 100
    MOVE G6B,100,  30,  80
    MOVE G6C,100,  30,  80
    WAIT
    GOSUB Leg_motor_mode1     
    GOTO MAIN

'********************************************** 
오른쪽턴20:
    GOSUB Leg_motor_mode2     
    SPEED 8
    MOVE G6A,95,  56, 145,  113, 105, 100
    MOVE G6D,95,  96, 145,  73, 105, 100
    MOVE G6B,90
    MOVE G6C,110
    WAIT     
    SPEED 12
    MOVE G6A,93,  56, 145,  113, 105, 100     
    MOVE G6D,93,  96, 145,  73, 105, 100     
    WAIT
    SPEED 6
    MOVE G6A,101,  76, 146,  93, 98, 100
    MOVE G6D,101,  76, 146,  93, 98, 100
    MOVE G6B,100,  30,  80
    MOVE G6C,100,  30,  80
    WAIT
    GOSUB Leg_motor_mode1     
    GOTO MAIN
    '**********************************************
연속오른쪽옆으로70:
    SPEED 5
    MOVE G6D, 90,  90, 120, 105, 110, 100
    MOVE G6A,100,  76, 146,  93, 107, 100
    MOVE G6B,100,  40
    MOVE G6C,100,  40
    WAIT     
    SPEED 5
    MOVE G6D, 102,  76, 147, 93, 100, 100     
    MOVE G6A,83,  78, 140,  96, 115, 100     
    WAIT
    SPEED 5
    MOVE G6D,98,  76, 146,  93, 100, 100     
    MOVE G6A,98,  76, 146,  93, 100, 100     
    WAIT
    SPEED 5
    MOVE G6A,100,  76, 145,  93, 100, 100     
    MOVE G6D,100,  76, 145,  93, 100, 100     
    WAIT
    DELAY 300 
    GOTO MAIN     
    GOTO 연속오른쪽옆으로70     
 	 '*************
연속왼쪽옆으로70:     
	SPEED 5
    MOVE G6A, 90,  90, 120, 105, 110, 100
    MOVE G6D,100,  76, 146,  93, 107, 100
    MOVE G6B,100,  40
    MOVE G6C,100,  40
    WAIT     
    SPEED 5
    MOVE G6A, 102,  76, 147, 93, 100, 100     
    MOVE G6D,83,  78, 140,  96, 115, 100     
    WAIT
    SPEED 5
    MOVE G6A,98,  76, 146,  93, 100, 100     
    MOVE G6D,98,  76, 146,  93, 100, 100     
    WAIT
    SPEED 5
    MOVE G6A,100,  76, 145,  93, 100, 100     
    MOVE G6D,100,  76, 145,  93, 100, 100     
    WAIT
    DELAY 300 
                
    GOTO MAIN     
    GOTO 연속왼쪽옆으로70
'************************************************  
    
    
    
	'************************************* 
Leg_motor_mode3:
    MOTORMODE G6A,3,3,3,3,3     
    MOTORMODE G6D,3,3,3,3,3     
    RETURN
    '*************************************
 
Leg_motor_mode2:
    MOTORMODE G6A,2,2,2,2,2     
    MOTORMODE G6D,2,2,2,2,2
    RETURN

 '*************************************
Leg_motor_mode1:
    MOTORMODE G6A,1,1,1,1,1     
    MOTORMODE G6D,1,1,1,1,1     
    RETURN
    '*******기본자세관련********************
기본자세:
    MOVE G6A,100,  76, 145,  93, 100, 100
    MOVE G6D,100,  76, 145,  93, 100, 100
    MOVE G6B,100,  30,  80, 100, 100, 100
    MOVE G6C,100,  30,  80, 100, 100, 100
    WAIT     
    RETURN
    '*************************************
MOTOR_ON: '전포트서보모터사용설정

    GOSUB MOTOR_GET

    MOTOR G6B
    DELAY 50
    MOTOR G6C
    DELAY 50
    MOTOR G6A
    DELAY 50
    MOTOR G6D

    모터ONOFF = 0
    GOSUB 시작음	
    RETURN

    '************************************************
    '전포트서보모터사용설정
MOTOR_OFF:

    MOTOROFF G6B
    MOTOROFF G6C
    MOTOROFF G6A
    MOTOROFF G6D
    모터ONOFF = 1	
    GOSUB MOTOR_GET	
    GOSUB 종료음	
    RETURN
    '************************************************
    '위치값피드백
MOTOR_GET:
    GETMOTORSET G6A,1,1,1,1,1,0
    GETMOTORSET G6B,1,1,1,0,0,1
    GETMOTORSET G6C,1,1,1,0,1,0
    GETMOTORSET G6D,1,1,1,1,1,0
    RETURN

    '************************************************
    '위치값피드백
MOTOR_SET:
    GETMOTORSET G6A,1,1,1,1,1,0
    GETMOTORSET G6B,1,1,1,0,0,1
    GETMOTORSET G6C,1,1,1,0,1,0
    GETMOTORSET G6D,1,1,1,1,1,0
    RETURN

    '************************************************
All_motor_Reset:

    MOTORMODE G6A,1,1,1,1,1,1
    MOTORMODE G6D,1,1,1,1,1,1
    MOTORMODE G6B,1,1,1,,,1
    MOTORMODE G6C,1,1,1,,1

    RETURN
    '************************************************
All_motor_mode2:

    MOTORMODE G6A,2,2,2,2,2
    MOTORMODE G6D,2,2,2,2,2
    MOTORMODE G6B,2,2,2,,,2
    MOTORMODE G6C,2,2,2,,2

    RETURN
    '************************************************
All_motor_mode3:

    MOTORMODE G6A,3,3,3,3,3
    MOTORMODE G6D,3,3,3,3,3
    MOTORMODE G6B,3,3,3,,,3
    MOTORMODE G6C,3,3,3,,3

    RETURN
    
   '************************************************
  
전원초기자세:
    MOVE G6A,100,  76, 145,  93, 100, 100
    MOVE G6D,100,  76, 145,  93, 100, 100
    MOVE G6B,100,  35,  90,
    MOVE G6C,100,  35,  90
    WAIT
    mode = 0
    RETURN
    '************************************************
안정화자세:
    MOVE G6A,98,  76, 145,  93, 101, 100
    MOVE G6D,98,  76, 145,  93, 101, 100
    MOVE G6B,100,  35,  90,
    MOVE G6C,100,  35,  90
    WAIT
    mode = 0

    RETURN
    '**** 자이로감도 설정 ****
자이로INIT:

    GYRODIR G6A, 0, 0, 1, 0,0
    GYRODIR G6D, 1, 0, 1, 0,0

    GYROSENSE G6A,200,150,30,150,0
    GYROSENSE G6D,200,150,30,150,0

    RETURN
    '***********************************************
    '**** 자이로감도 설정 ****
자이로MAX:

    GYROSENSE G6A,250,180,30,180,0
    GYROSENSE G6D,250,180,30,180,0

    RETURN
    '***********************************************
자이로MID:

    GYROSENSE G6A,200,150,30,150,0
    GYROSENSE G6D,200,150,30,150,0

    RETURN
    '***********************************************
자이로MIN:

    GYROSENSE G6A,200,100,30,100,0
    GYROSENSE G6D,200,100,30,100,0
    RETURN
    '***********************************************
자이로ON:

    GYROSET G6A, 4, 3, 3, 3, 0
    GYROSET G6D, 4, 3, 3, 3, 0

    자이로ONOFF = 1

    RETURN
    '***********************************************
자이로OFF:

    GYROSET G6A, 0, 0, 0, 0, 0
    GYROSET G6D, 0, 0, 0, 0, 0
    자이로ONOFF = 0
    RETURN

    '************************************************
'************************************************
시작음:
    TEMPO 220
    MUSIC "O23EAB7EA>3#C"
    RETURN
    '************************************************
종료음:
    TEMPO 220
    MUSIC "O38GD<BGD<BG"
    RETURN
적외선거리센서확인:
    적외선거리값 = AD(적외선AD포트)
    IF 적외선거리값 > 50 THEN '50 = 적외선거리값 = 25cm
    	dis=적외선거리값
        MUSIC "C"
        DELAY 200
    ENDIF

    RETURN