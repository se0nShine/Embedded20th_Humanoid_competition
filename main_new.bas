PTP SETON 				'단위그룹별 점대점동작 설정
PTP ALLON				'전체모터 점대점 동작 설정

DIR G6A,1,0,0,1,0,0		'모터0~5번
DIR G6D,0,1,1,0,1,1		'모터18~23번
DIR G6B,1,1,1,1,1,1		'모터6~11번
DIR G6C,0,0,0,0,1,0		'모터12~17번

OUT 52,0	'머리 LED 켜기

SPEED 5
GOSUB MOTOR_ON

S11=MOTORIN(11)
S16=MOTORIN(16)

SERVO 11,100
SERVO 16, S16
SERVO 16,100

GOSUB 전원초기자세
GOSUB 기본자세


GOSUB 자이로INIT
GOSUB 자이로MID
GOSUB 자이로ON

PRINT "VOLUME 100 !"
PRINT "SOUND 12 !" '안녕하세요

GOSUB All_motor_mode3


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
    

전원초기자세:
    MOVE G6A,100,  76, 145,  93, 100, 100
    MOVE G6D,100,  76, 145,  93, 100, 100
    MOVE G6B,100,  35,  90,
    MOVE G6C,100,  35,  90
    WAIT
    mode = 0
    RETURN
    
    
자이로INIT:

    GYRODIR G6A, 0, 0, 1, 0,0
    GYRODIR G6D, 1, 0, 1, 0,0

    GYROSENSE G6A,200,150,30,150,0
    GYROSENSE G6D,200,150,30,150,0

    RETURN
    

자이로MID:

    GYROSENSE G6A,200,150,30,150,0
    GYROSENSE G6D,200,150,30,150,0

    RETURN
    
    
자이로ON:

    GYROSET G6A, 4, 3, 3, 3, 0
    GYROSET G6D, 4, 3, 3, 3, 0

    자이로ONOFF = 1

    RETURN
    
    
All_motor_mode3:

    MOTORMODE G6A,3,3,3,3,3
    MOTORMODE G6D,3,3,3,3,3
    MOTORMODE G6B,3,3,3,,,3
    MOTORMODE G6C,3,3,3,,3

    RETURN
    
'*********전역변수 선언부*********

DIM ready AS BYTE
DIM _rx AS BYTE
DIM dis AS INTEGER

ready=0

'******************************

GOTO MAIN


기본자세:
    MOVE G6A,100,  76, 145,  93, 100, 100
    MOVE G6D,100,  76, 145,  93, 100, 100
    MOVE G6B,100,  30,  80, 100, 100, 100
    MOVE G6C,100,  30,  80, 100, 100, 100
    WAIT     
    RETURN
    
    
전진횟수보행50:'함수 호출시마다 보행횟수 값 설정필요
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
    RETURN
    
      
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
    RETURN
    
    
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


'로보베이직에서 goto한 함수에서 return했을 경우 어떻게 되는가? 
'가장 최근 gosub을 호출한 부분으로 돌아간다고 가정하고 코딩
GET_RX_FAILED:
	_rx=0
	RETURN


GET_RX:'save rx value to variable _rx
	ERX 4800,_rx,GET_RX_FAILED
	RETURN


MAIN:
	GOSUB GET_RX
	
	IF _rx=1 THEN
		IF ready=0 THEN
			ready=1
			PRINT "SOUND 12 !"
		ELSE
			ready=0
		ENDIF
	ENDIF
	
	IF ready=1 THEN
    	dis=AD(4)
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
	
	







