'******** 2족 보행로봇 초기 영점 프로그램 ********

DIM I AS BYTE
DIM J AS BYTE
DIM MODE AS BYTE
DIM A AS BYTE
DIM X AS BYTE
DIM Y AS BYTE
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

'받은 음원
'PRINT "open 22GongMo.mrs !"
'PRINT "VOLUME 100 !"
'PRINT "SND 1 !"
'GOSUB SOUND_PLAY_CHK

'PRINT "VOLUME 200 !"
'PRINT "SOUND 12 !" '안녕하세요

GOSUB All_motor_mode3


'************************************************
DIM 반복횟수 AS BYTE
DIM arrow AS INTEGER
arrow=0
DIM dis AS INTEGER
DIM dis_old AS INTEGER
DIM head_d AS INTEGER
head_d = 100
dis=0
dis_old=0
DIM go AS BYTE
DIM center AS BYTE
DIM milk AS INTEGER
DIM head AS INTEGER
DIM roomC AS INTEGER
DIM direction AS BYTE

go=0
milk=0
head=0
보행COUNT = 0
center=0
roomC = 0
direction = 0

DIM AAAAAAA AS INTEGER

AAAAAAA = 300
'GOSUB MOTOR_OFF
'STOP
'RETURN -> GOSUB
'GOSUB MOTOR_OFF
'STOP
'RETURN -> GOSUB

DIM vrx AS BYTE
DIM ready AS BYTE
DIM vstate AS BYTE
DIM detectHeight AS BYTE
DIM BPS AS BYTE
DIM walkCount AS BYTE
DIM find AS INTEGER
find=0
vrx=0
ready=0
vstate=0
BPS=4800


GOTO MAIN	'시리얼 수신 루틴으

MAIN:

    GOSUB 앞뒤기울기측정
    GOSUB 좌우기울기측정
    GOSUB 적외선거리센서확인


	GOSUB GET_RX
	    
    IF vrx=99 THEN
    	ready=1
    ENDIF
    
    IF ready=1 THEN
    	IF vstate=0 THEN
    		MOVE G6C,100,  30,  80, 100, 25, 100
    		WAIT
    		GOSUB TRACE_LINE
    	ELSEIF vstate=2 THEN
    		MOVE G6C,100,  30,  80, 100, 25, 100
    		WAIT
    		GOSUB TRACE_LINE
    	ELSEIF vstate=1 THEN
    		GOSUB DETECT_DIRECTION
    
	  	ELSEIF vstate = 3 THEN
		    IF find=0 THEN
		    	GOSUB 고개내리기 
		    	ETX 4800, 153
		    	GOSUB CHECKITEM    
		    ELSEIF find=1 THEN
		    	GOSUB 고개완전내리기  
		    	ETX 4800, 154
		   	 	GOSUB CHECKITEM2
		    ELSEIF find=2 THEN
		    	ETX 4800, 155
		    	GOSUB CHECKITEM2
		    ENDIF
		ELSEIF vstate=4 THEN
			GOSUB BACK_LINE
			
		 	
		  
	    'ELSEIF vstate = 4 THEN
		'    IF find=0 THEN
		'    	GOSUB 고개내리기 
		'    	ETX 4800, 158
		'    	GOSUB CHECKITEM
		'    ENDIF
		ENDIF    
	    
    ENDIF
    
    GOTO MAIN

    '*************************************
    
    
BACK_LINE:
	dis = AD(적외선AD포트)
	IF dis>90 THEN
		GOSUB 오른쪽턴10
		WAIT
	ELSE
		보행횟수= 1
        GOSUB 전진횟수보행50 
        WAIT
    ENDIF
    ETX 4800,158
	GOSUB GET_RX_REPEAT
	IF vrx=201 THEN
    	GOTO BACK_LINE
    ENDIF
    vstate=0
	RETURN

TRACE_LINE:
	ETX 4800,150
	GOSUB GET_RX_REPEAT
	IF vrx=101 THEN
		보행횟수= 1
        GOSUB 전진횟수보행50 
	ELSEIF vrx=102 THEN
		GOSUB 왼쪽턴10
	ELSEIF vrx=103 THEN
		GOSUB 오른쪽턴10
	ELSEIF vrx=104 THEN
		GOSUB 연속왼쪽옆으로70
	ELSEIF vrx=105 THEN
		GOSUB 연속오른쪽옆으로70
	ELSEIF vrx=106 THEN
		DELAY 1000
		MOVE G6C,100,  30,  80, 100, 100, 100
		IF vstate = 2 THEN
			IF direction = 0 THEN
				GOSUB Goto_edge
				GOSUB CHECKDANGER
				GOSUB Left_Mission
			ELSEIF direction = 1 THEN
				GOSUB Goto_edge
				GOSUB CHECKDANGER
				GOSUB Right_Mission
			ENDIF
		ENDIF
		vstate= vstate + 1
		WAIT
	ELSEIF vrx=107 THEN
		DELAY 1000
		MOVE G6C,100,  30,  80, 100, 100, 100
		IF vstate = 2 THEN
			IF direction = 0 THEN
				GOSUB Goto_edge
				GOSUB CHECKDANGER
				GOSUB Left_Mission
			ELSEIF direction = 1 THEN
				GOSUB Goto_edge
				GOSUB CHECKDANGER
				GOSUB Right_Mission
			ENDIF
		ENDIF
		vstate= vstate + 1
		WAIT
	ELSEIF vrx=108 THEN
		DELAY 1000
		MOVE G6C,100,  30,  80, 100, 100, 100
		IF vstate = 2 THEN
			IF direction = 0 THEN
				GOSUB Goto_edge
				GOSUB CHECKDANGER
				GOSUB Left_Mission
			ELSEIF direction = 1 THEN
				GOSUB Goto_edge
				GOSUB CHECKDANGER
				GOSUB Right_Mission
			ENDIF
		ENDIF
		vstate= vstate + 1
		WAIT
	ELSEIF vrx=109 THEN
	ENDIF
	RETURN
	
	
DETECT_DIRECTION:
	ETX 4800,151
	GOSUB GET_RX_REPEAT
	IF vrx=111 THEN
		GOSUB NORTH
		WAIT
		GOSUB Goto_Edge
		GOSUB 왼쪽턴10
		GOSUB 왼쪽턴10
		GOSUB 왼쪽턴10
		GOSUB 왼쪽턴10
		GOSUB 왼쪽턴10
		GOSUB 왼쪽턴10
		GOSUB 왼쪽턴10
		GOSUB 왼쪽턴10
		GOSUB 왼쪽턴10
		보행횟수=2
		GOSUB 전진횟수보행50
		DELAY 1000
		vstate= vstate + 1
		direction = 0
	ELSEIF vrx=112 THEN
		GOSUB NORTH
		WAIT
		GOSUB Goto_Edge
		GOSUB 오른쪽턴10
		GOSUB 오른쪽턴10
		GOSUB 오른쪽턴10
		GOSUB 오른쪽턴10
		GOSUB 오른쪽턴10
		GOSUB 오른쪽턴10
		GOSUB 오른쪽턴10
		GOSUB 오른쪽턴10
		GOSUB 오른쪽턴10
		보행횟수=2
		GOSUB 전진횟수보행50
		DELAY 1000
		vstate= vstate + 1
		direction = 1
	ELSEIF vrx=113 THEN
		GOSUB WEST
		WAIT
		GOSUB Goto_Edge
		GOSUB 왼쪽턴10
		GOSUB 왼쪽턴10
		GOSUB 왼쪽턴10
		GOSUB 왼쪽턴10
		GOSUB 왼쪽턴10
		GOSUB 왼쪽턴10
		GOSUB 왼쪽턴10
		GOSUB 왼쪽턴10
		GOSUB 왼쪽턴10
		보행횟수=2
		GOSUB 전진횟수보행50
		DELAY 1000
		vstate= vstate + 1
		direction = 0
	ELSEIF vrx=114 THEN
		GOSUB WEST
		WAIT
		GOSUB Goto_Edge
		GOSUB 오른쪽턴10
		GOSUB 오른쪽턴10
		GOSUB 오른쪽턴10
		GOSUB 오른쪽턴10
		GOSUB 오른쪽턴10
		GOSUB 오른쪽턴10
		GOSUB 오른쪽턴10
		GOSUB 오른쪽턴10
		GOSUB 오른쪽턴10
		보행횟수=2
		GOSUB 전진횟수보행50
		DELAY 1000
		vstate= vstate + 1
		direction = 1
	ELSEIF vrx=115 THEN
		GOSUB SOUTH
		WAIT
		GOSUB Goto_Edge
		GOSUB 왼쪽턴10
		GOSUB 왼쪽턴10
		GOSUB 왼쪽턴10
		GOSUB 왼쪽턴10
		GOSUB 왼쪽턴10
		GOSUB 왼쪽턴10
		GOSUB 왼쪽턴10
		GOSUB 왼쪽턴10
		GOSUB 왼쪽턴10
		보행횟수=2
		GOSUB 전진횟수보행50
		DELAY 1000
		vstate= vstate + 1
		direction = 0
	ELSEIF vrx=116 THEN
		GOSUB SOUTH
		WAIT
		GOSUB Goto_Edge
		GOSUB 오른쪽턴10
		GOSUB 오른쪽턴10
		GOSUB 오른쪽턴10
		GOSUB 오른쪽턴10
		GOSUB 오른쪽턴10
		GOSUB 오른쪽턴10
		GOSUB 오른쪽턴10
		GOSUB 오른쪽턴10
		GOSUB 오른쪽턴10
		보행횟수=2
		GOSUB 전진횟수보행50
		DELAY 1000
		vstate= vstate + 1
		direction = 1
	ELSEIF vrx=117 THEN
		GOSUB EAST
		WAIT
		GOSUB Goto_Edge
		GOSUB 왼쪽턴10
		GOSUB 왼쪽턴10
		GOSUB 왼쪽턴10
		GOSUB 왼쪽턴10
		GOSUB 왼쪽턴10
		GOSUB 왼쪽턴10
		GOSUB 왼쪽턴10
		GOSUB 왼쪽턴10
		GOSUB 왼쪽턴10
		보행횟수=2
		GOSUB 전진횟수보행50
		DELAY 1000
		vstate= vstate + 1
		direction = 0
	ELSEIF vrx=118 THEN
		GOSUB EAST
		WAIT
		GOSUB Goto_Edge
		GOSUB 오른쪽턴10
		GOSUB 오른쪽턴10
		GOSUB 오른쪽턴10
		GOSUB 오른쪽턴10
		GOSUB 오른쪽턴10
		GOSUB 오른쪽턴10
		GOSUB 오른쪽턴10
		GOSUB 오른쪽턴10
		GOSUB 오른쪽턴10
		보행횟수=2
		GOSUB 전진횟수보행50
		DELAY 1000
		vstate= vstate + 1
		direction = 1
	ELSEIF vrx=119 THEN
	ENDIF
	
	RETURN

Left_Mission:
	ETX 4800,152
	GOSUB GET_RX_REPEAT
	IF vrx = 149 THEN
		GOTO Left_Mission
	ELSE
		roomC = vrx
		GOSUB 왼쪽턴90
	ENDIF
	
	
	RETURN

Right_Mission:
	ETX 4800,152
	GOSUB GET_RX_REPEAT
	IF vrx = 149 THEN
		GOTO Right_Mission
	ELSE
		roomC = vrx
		GOSUB 오른쪽턴90
	ENDIF
	
	RETURN
Goto_Edge:
	MOVE G6C,100,  30,  80, 100, 25, 100
    WAIT
	ETX 4800,156
	GOSUB GET_RX_REPEAT
	IF vrx=193 THEN
		보행횟수= 1
        GOSUB 전진횟수보행50
		GOTO Goto_Edge
	ELSEIF vrx=194 THEN
		DELAY 1000
		MOVE G6C,100,  30,  80, 100, 100, 100
	ENDIF
		
	RETURN
    
CHECKDANGER:
	SPEED 머리이동속도
    SERVO 11,55
    MOVE G6C,100,  30,  80, 100, 55, 100
    WAIT
    DELAY 2000
    
    ETX 4800,157
	GOSUB GET_RX_REPEAT
	IF vrx=195 THEN
		SERVO 11, 100
		MOVE G6C,100,  30,  80, 100, 100, 100
		WAIT
		DELAY 2000
		'계단올라가는 코드 넣어야함 
	ELSEIF vrx=196 THEN
		GOSUB 위험지역 
		SERVO 11,100
    	SERVO 16,100
    	WAIT
    WAIT
	ELSE
		GOTO CHECKDANGER
	ENDIF
		
	RETURN
CHECKITEM:
	ERX 4800,A,CHECKITEM 
 
	
    IF A=170 THEN
    	
        GOSUB 후진종종걸음 

    ELSEIF A=171 THEN
        
        GOSUB 왼쪽턴10

    ELSEIF A=172 THEN
        
        GOSUB 전진횟수보행50

    ELSEIF A=173 THEN
        
        GOSUB 오른쪽턴10

    ELSEIF A=174 THEN
        
        GOSUB 왼쪽턴10
            
	ELSEIF A=175 THEN
        
        GOSUB 전진횟수보행50
            
    ELSEIF A=176 THEN
        
        GOSUB 오른쪽턴10
            
    ELSEIF A=177 THEN
        
        GOSUB 왼쪽턴10
      
            
    ELSEIF A=178 THEN
        
        find=1 
    
    ELSEIF A=179 THEN
        
        GOSUB 오른쪽턴10

    
    ELSE
    	GOTO CHECKITEM
    	
    	
    ENDIF
    
    
    
    
    RETURN
    
CHECKITEM2:
	ERX 4800,A,CHECKITEM2
 
	
    IF A=180 THEN
    	
        find=0 

    ELSEIF A=181 THEN
        
        GOSUB 연속왼쪽옆으로70

    ELSEIF A=182 THEN
        
        GOSUB 전진횟수보행50	 

    ELSEIF A=183 THEN
        
        GOSUB 연속오른쪽옆으로70

    ELSEIF A=184 THEN
        
        GOSUB 연속왼쪽옆으로70
            
	ELSEIF A=185 THEN
        
        GOSUB 우유팩잡기
        MOVE G6C,185,  10,  60, 100, 25, 100
        GOSUB 집고오른쪽턴60
        GOSUB 집고오른쪽턴60
        GOSUB 집고오른쪽턴60
        find = 2
    	
            
    ELSEIF A=186 THEN
        
        GOSUB 연속오른쪽옆으로70
            
    ELSEIF A=187 THEN
        
        GOSUB 연속왼쪽옆으로70
      
            
    ELSEIF A=188 THEN
        
        GOSUB 우유팩잡기
        MOVE G6C,185,  10,  60, 100, 25, 100
       	GOSUB 집고오른쪽턴60
        GOSUB 집고오른쪽턴60
        GOSUB 집고오른쪽턴60
        find = 2
    
    ELSEIF A=189 THEN
        
        GOSUB 연속오른쪽옆으로70

    ELSEIF A=191 THEN
    	GOSUB 잡고보행50
    ELSEIF A=192 THEN
    	GOSUB 우유팩놓기
    	
    	vstate=4
    	find=0
    ELSE
    	GOTO CHECKITEM2
    	
    	
    ENDIF
    
    
    
    
    
    RETURN
	

    '*************************************
        
GET_RX_FAILED:
	vrx=0
	RETURN


GET_RX:'save rx value to variable _rx
	ERX 4800,vrx,GET_RX_FAILED
	RETURN


GET_RX_REPEAT:'get rx repeatly until _rx is valid
	ERX 4800,vrx,GET_RX_REPEAT
	RETURN
    
    
'*******************************************


    
   '*************************************
구조요청:
	PRINT "open 22GongMo.mrs !"
    PRINT "VOLUME 100 !"
    PRINT "SND 7 !"
    GOSUB SOUND_PLAY_CHK
    PRINT "SND 7 !"
    GOSUB SOUND_PLAY_CHK
    RETURN
	
위험지역:
	PRINT "open 22GongMo.mrs !"
    PRINT "VOLUME 100 !"
    PRINT "SND 6 !"
    GOSUB SOUND_PLAY_CHK
    RETURN
    
East:
    PRINT "open 22GongMo.mrs !"
    PRINT "VOLUME 100 !"
    PRINT "SND 0 !"
    GOSUB SOUND_PLAY_CHK
    PRINT "SND 0 !"
    GOSUB SOUND_PLAY_CHK

    MOVE G6A,100, 56, 182, 76, 100, 100
    MOVE G6D,100, 56, 182, 76, 100, 100
    MOVE G6B,100,  30,  80
    MOVE G6C,190,  30,  80
    WAIT
    RETURN

West:
    PRINT "open 22GongMo.mrs !"
    PRINT "VOLUME 100 !"
    PRINT "SND 1 !"
    GOSUB SOUND_PLAY_CHK
    PRINT "SND 1 !"
    GOSUB SOUND_PLAY_CHK

    MOVE G6A,100, 56, 182, 76, 100, 100
    MOVE G6D,100, 56, 182, 76, 100, 100
    MOVE G6B,190,  30,  80
    MOVE G6C,100,  30,  80
    WAIT
    RETURN
    
North:
    PRINT "open 22GongMo.mrs !"
    PRINT "VOLUME 100 !"
    PRINT "SND 3 !"
    GOSUB SOUND_PLAY_CHK
    PRINT "SND 3 !"
    GOSUB SOUND_PLAY_CHK

    MOVE G6A,100, 56, 182, 76, 100, 100
    MOVE G6D,100, 56, 182, 76, 100, 100
    MOVE G6B,190,  30,  80
    MOVE G6C,190,  30,  80
    WAIT
    RETURN

South:
    PRINT "open 22GongMo.mrs !"
    PRINT "VOLUME 100 !"
    PRINT "SND 2 !"
    GOSUB SOUND_PLAY_CHK
    PRINT "SND 2 !"
    GOSUB SOUND_PLAY_CHK

    MOVE G6A,100, 56, 182, 76, 100, 100
    MOVE G6D,100, 56, 182, 76, 100, 100
    MOVE G6B,10,  30,  80
    MOVE G6C,10,  30,  80
    WAIT
    RETURN
    
방이름_B:
    PRINT "open 22GongMo.mrs !"
    PRINT "VOLUME 100 !"
    PRINT "SND 9 !"
    GOSUB SOUND_PLAY_CHK
    RETURN
    
방이름_D:
    PRINT "open 22GongMo.mrs !"
    PRINT "VOLUME 100 !"
    PRINT "SND 11 !"
    GOSUB SOUND_PLAY_CHK
    RETURN

    '*************************************
고개내리기:
	SPEED 2
    MOVE G6B,100,  30,  80, 100, 100, 100
    MOVE G6C,100, 30, 80, 100, 70, 100
    WAIT
	RETURN

고개완전내리기: 
	SPEED 2
	MOVE G6B,100,35
    MOVE G6C,100,35,80, 100, 25, 100
    WAIT
    RETURN
	
고개오른쪽내리기:
    SPEED 2
    MOVE G6B,100,  30,  80, 100, 100, 100
    MOVE G6C,100,  30,  80, 100, 100, 100
    WAIT

    SPEED 2
    MOVE G6B,100,  30,  80, 100, 100, 140
    MOVE G6C,100, 30, 80, 100, 70, 100
    RETURN

고개왼쪽내리기:
    SPEED 2
    MOVE G6B,100,  30,  80, 100, 100, 100
    MOVE G6C,100,  30,  80, 100, 100, 100
    WAIT

    SPEED 2
    MOVE G6B,100,  30,  80, 100, 100, 60
    MOVE G6C,100, 30, 80, 100, 70, 100
    RETURN

    '*************************************




    '*************************************
    

전진횟수보행50:
    넘어진확인 = 0
    반복횟수 = 0
    GOSUB Leg_motor_mode3
    IF 보행순서 = 0 THEN
        보행순서 = 1
        SPEED 3         '오른쪽기울기
        MOVE G6A, 88,  71, 152,  91, 110
        MOVE G6D,108,  76, 146,  93,  94
        MOVE G6B,100,35
        MOVE G6C,100,35,80, 100
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
        MOVE G6C, 100,35,80, 100
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
        RETURN
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
        RETURN
    ENDIF
    GOTO 전진횟수보행50_1

잡고보행50:
    넘어진확인 = 0
    반복횟수 = 0
    GOSUB Leg_motor_mode3
    IF 보행순서 = 0 THEN
        보행순서 = 1
        SPEED 3         '오른쪽기울기
        MOVE G6A, 88,  71, 152,  81, 110
        MOVE G6D,108,  76, 146,  83,  94
        
        WAIT
        SPEED 10'보행속도         '왼발들기
        MOVE G6A, 90, 100, 115, 95, 114
        MOVE G6D,113,  78, 146,  83,  94
        WAIT
        GOTO 잡고보행50_1
    ELSE
        보행순서 = 0
        SPEED 3         '왼쪽기울기
        MOVE G6D,  88,  71, 152,  81, 110
        MOVE G6A, 108,  76, 146,  83,  94
        WAIT
        SPEED 10'보행속도         '오른발들기
        MOVE G6D, 90, 100, 115, 95, 114
        MOVE G6A,113,  78, 146,  83,  94
        WAIT
        GOTO 잡고보행50_2
    ENDIF

잡고보행50_1:
    반복횟수 = 반복횟수 + 1
    SPEED 10
    '왼발뻣어착지
    MOVE G6A, 85,  44, 163, 103, 114
    MOVE G6D,110,  77, 146,  83,  94
    WAIT
    SPEED 4     '왼발중심이동
    MOVE G6A,110,  76, 144, 90,  93
    MOVE G6D,85, 93, 155,  61, 112
    WAIT
    SPEED 10     '오른발들기10
    MOVE G6A,111,  77, 146,  83, 94
    MOVE G6D,90, 100, 105, 100, 114
    WAIT
    IF 반복횟수 >= 보행횟수 THEN
        HIGHSPEED SETOFF
        SPEED 5
        '왼쪽기울기2
        MOVE G6A, 106,  76, 146,  83,  96
        MOVE G6D,  88,  71, 152,  81, 106
        WAIT
        SPEED 3
        'GOSUB 기본자세
        GOSUB Leg_motor_mode1
        RETURN
    ENDIF

잡고보행50_2:

    반복횟수 = 반복횟수 + 1
    SPEED 10
    '오른발뻣어착지
    MOVE G6D,85,  44, 163, 103, 114
    MOVE G6A,110,  77, 146,  83,  94
    WAIT
    SPEED 4
    '오른발중심이동
    MOVE G6D,110,  76, 144, 90,  93
    MOVE G6A, 85, 93, 155,  61, 112
    WAIT
    SPEED 10     '왼발들기10
    MOVE G6A, 90, 100, 105, 100, 114
    MOVE G6D,111,  77, 146,  83,  94
    WAIT
    IF 반복횟수 >= 보행횟수 THEN
        HIGHSPEED SETOFF
        SPEED 5
        '오른쪽기울기2
        MOVE G6D, 106,  76, 146,  83,  96
        MOVE G6A,  88,  71, 152,  81, 106
        WAIT
        SPEED 3
        'GOSUB 기본자세
        GOSUB Leg_motor_mode1
        RETURN
    ENDIF
    GOTO 잡고보행50_1


전진종종걸음:
    GOSUB All_motor_mode3
    보행COUNT = 0
    SPEED 4
    HIGHSPEED SETON


    IF 보행순서 = 0 THEN
        보행순서 = 1
        MOVE G6A,95,  76, 147,  93, 101
        MOVE G6D,101,  76, 147,  93, 98
        MOVE G6B,100
        MOVE G6C,100
        WAIT

        GOTO 전진종종걸음_1
    ELSE
        보행순서 = 0
        MOVE G6D,95,  76, 147,  93, 101
        MOVE G6A,101,  76, 147,  93, 98
        MOVE G6B,100
        MOVE G6C,100
        WAIT

        GOTO 전진종종걸음_4
    ENDIF


    '**********************

전진종종걸음_1:
    MOVE G6A,95,  90, 125, 100, 104
    MOVE G6D,104,  77, 147,  93,  102
    MOVE G6B, 85
    MOVE G6C,115
    WAIT


전진종종걸음_2:

    MOVE G6A,103,   73, 140, 103,  100
    MOVE G6D, 95,  85, 147,  85, 102
    WAIT



    ' 보행COUNT = 보행COUNT + 1
    'IF 보행COUNT > 보행횟수 THEN  GOTO 전진종종걸음_2_stop


전진종종걸음_2_stop:
        MOVE G6D,95,  90, 125, 95, 104
        MOVE G6A,104,  76, 145,  91,  102
        MOVE G6C, 100
        MOVE G6B,100
        WAIT
        HIGHSPEED SETOFF
        SPEED 15
        GOSUB 안정화자세
        SPEED 5
        GOSUB 기본자세2
        DELAY 300

	RETURN
   

    '*********************************

전진종종걸음_4:
    MOVE G6D,95,  95, 120, 100, 104
    MOVE G6A,104,  77, 147,  93,  102
    MOVE G6C, 85
    MOVE G6B,115
    WAIT


전진종종걸음_5:
    MOVE G6D,103,    73, 140, 103,  100
    MOVE G6A, 95,  85, 147,  85, 102
    WAIT


    ' 보행COUNT = 보행COUNT + 1
    ' IF 보행COUNT > 보행횟수 THEN  GOTO 전진종종걸음_5_stop

전진종종걸음_5_stop:
        MOVE G6A,95,  90, 125, 95, 104
        MOVE G6D,104,  76, 145,  91,  102
        MOVE G6B, 100
        MOVE G6C,100
        WAIT
        HIGHSPEED SETOFF
        SPEED 15
        GOSUB 안정화자세
        SPEED 5
        GOSUB 기본자세2
		DELAY 300

	RETURN



횟수_전진종종걸음:
    GOSUB All_motor_mode3
    보행COUNT = 0
    SPEED 8


    IF 보행순서 = 0 THEN
        보행순서 = 1
        MOVE G6A,95,  76, 147,  93, 101
        MOVE G6D,101,  76, 147,  93, 98
        MOVE G6B,100
        MOVE G6C,100
        WAIT

        GOTO 횟수_전진종종걸음_1
    ELSE
        보행순서 = 0
        MOVE G6D,95,  76, 147,  93, 101
        MOVE G6A,101,  76, 147,  93, 98
        MOVE G6B,100
        MOVE G6C,100
        WAIT

        GOTO 횟수_전진종종걸음_4
    ENDIF


    '**********************

횟수_전진종종걸음_1:
    MOVE G6A,95,  90, 125, 100, 104
    MOVE G6D,104,  77, 147,  93,  102
    MOVE G6B, 85
    MOVE G6C,115
    WAIT


횟수_전진종종걸음_2:

    MOVE G6A,103,   73, 140, 103,  100
    MOVE G6D, 95,  85, 147,  85, 102
    WAIT

  

    보행COUNT = 보행COUNT + 1
    IF 보행COUNT > 보행횟수 THEN
        MOVE G6D,95,  90, 125, 95, 104
        MOVE G6A,104,  76, 145,  91,  102
        MOVE G6C, 100
        MOVE G6B,100
        WAIT
        HIGHSPEED SETOFF
        SPEED 15
        GOSUB 안정화자세
        SPEED 5
        GOSUB 기본자세2

        'DELAY 400
        RETURN
    ENDIF

    '*********************************

횟수_전진종종걸음_4:
    MOVE G6D,95,  95, 120, 100, 104
    MOVE G6A,104,  77, 147,  93,  102
    MOVE G6C, 85
    MOVE G6B,115
    WAIT


횟수_전진종종걸음_5:
    MOVE G6D,103,    73, 140, 103,  100
    MOVE G6A, 95,  85, 147,  85, 102
    WAIT


    
    보행COUNT = 보행COUNT + 1
    IF 보행COUNT > 보행횟수 THEN
        MOVE G6A,95,  90, 125, 95, 104
        MOVE G6D,104,  76, 145,  91,  102
        MOVE G6B, 100
        MOVE G6C,100
        WAIT
        HIGHSPEED SETOFF
        SPEED 15
        GOSUB 안정화자세
        SPEED 5
        GOSUB 기본자세2

        'DELAY 400
        RETURN
    ENDIF

    '*************************************

    '*********************************

    GOTO 횟수_전진종종걸음_1

    '******************************************

    '******************************************



    '*********************************************
후진종종걸음:
    GOSUB All_motor_mode3
    넘어진확인 = 0
    보행COUNT = 0
    SPEED 7
    HIGHSPEED SETON


    IF 보행순서 = 0 THEN
        보행순서 = 1
        MOVE G6A,95,  76, 145,  93, 101
        MOVE G6D,101,  76, 145,  93, 98
        MOVE G6B,100
        MOVE G6C,100
        WAIT

        GOSUB 후진종종걸음_1
    ELSE
        보행순서 = 0
        MOVE G6D,95,  76, 145,  93, 101
        MOVE G6A,101,  76, 145,  93, 98
        MOVE G6B,100
        MOVE G6C,100
        WAIT

        GOSUB 후진종종걸음_4
        
        RETURN
    ENDIF


후진종종걸음_1:
    MOVE G6D,104,  76, 147,  93,  101
    MOVE G6A,95,  95, 120, 95, 114
    MOVE G6B,115
    MOVE G6C,85
    WAIT
    RETURN

후진종종걸음_4:
    MOVE G6A,104,  76, 147, 93,  101
    MOVE G6D,95,  95, 120, 95, 114
    MOVE G6C,115
    MOVE G6B,85
    WAIT
    RETURN
    
집고오른쪽턴60:

    SPEED 15
    MOVE G6A,95,  36, 145,  125, 105, 100
    MOVE G6D,95,  116, 145,  45, 105, 100
    WAIT

    SPEED 15
    MOVE G6A,90,  36, 145,  125, 105, 100
    MOVE G6D,90,  116, 145,  45, 105, 100
    WAIT

    SPEED 10
    MOVE G6A,100,  76, 145,  85, 100
    MOVE G6D,100,  76, 145,  85, 100
    WAIT
    RETURN
집고오른쪽턴45:

    SPEED 8
    MOVE G6A,95,  46, 145,  115, 105, 100
    MOVE G6D,95,  106, 145,  55, 105, 100
    WAIT

    SPEED 10
    MOVE G6A,93,  46, 145,  115, 105, 100
    MOVE G6D,93,  106, 145,  55, 105, 100
    WAIT

    SPEED 8
    MOVE G6A,100,  76, 145,  85, 100
    MOVE G6D,100,  76, 145,  85, 100
    WAIT
    

왼쪽턴10:
    넘어진확인 = 0
    MOTORMODE G6A,3,3,3,3,2
    MOTORMODE G6D,3,3,3,3,2
    SPEED 2
    MOVE G6A,97,  86, 145,  83, 103, 100
    MOVE G6D,97,  66, 145,  103, 103, 100
    WAIT

    SPEED 6
    MOVE G6A,94,  86, 145,  83, 101, 100
    MOVE G6D,94,  66, 145,  103, 101, 100
    WAIT

    SPEED 3
    MOVE G6A,101,  76, 146,  93, 98, 100
    MOVE G6D,101,  76, 146,  93, 98, 100
    WAIT
    DELAY 300
    RETURN

    '**********************************************
오른쪽턴10:
    넘어진확인 = 0
    MOTORMODE G6A,3,3,3,3,2
    MOTORMODE G6D,3,3,3,3,2
    SPEED 2
    MOVE G6A,97,  66, 145,  103, 103, 100
    MOVE G6D,97,  86, 145,  83, 103, 100
    WAIT

    SPEED 6
    MOVE G6A,94,  66, 145,  103, 101, 100
    MOVE G6D,94,  86, 145,  83, 101, 100
    WAIT
    SPEED 3
    MOVE G6A,101,  76, 146,  93, 98, 100
    MOVE G6D,101,  76, 146,  93, 98, 100
    WAIT
    DELAY 300
    RETURN

    '**********************************************



    '**********************************************
왼쪽턴90:
    GOSUB Leg_motor_mode2
    SPEED 8
    MOVE G6A,95,  106, 145,  63, 105, 100
    MOVE G6D,95,  46, 145,  123, 105, 100
    MOVE G6B,115
    MOVE G6C,85
    WAIT

    SPEED 10
    MOVE G6A,93,  106, 145,  63, 105, 100
    MOVE G6D,93,  46, 145,  123, 105, 100
    WAIT

    SPEED 8
    GOSUB 기본자세
    GOSUB Leg_motor_mode1

    '한번 더
    GOSUB Leg_motor_mode2
    SPEED 8
    MOVE G6A,95,  106, 145,  63, 105, 100
    MOVE G6D,95,  46, 145,  123, 105, 100
    MOVE G6B,115
    MOVE G6C,85
    WAIT

    SPEED 10
    MOVE G6A,93,  106, 145,  63, 105, 100
    MOVE G6D,93,  46, 145,  123, 105, 100
    WAIT

    SPEED 8
    GOSUB 기본자세
    GOSUB Leg_motor_mode1
    
    RETURN

    '**********************************************
오른쪽턴90:
    GOSUB Leg_motor_mode2
    SPEED 8
    MOVE G6A,95,  46, 145,  123, 105, 100
    MOVE G6D,95,  106, 145,  63, 105, 100
    MOVE G6C,115
    MOVE G6B,85
    WAIT

    SPEED 10
    MOVE G6A,93,  46, 145,  123, 105, 100
    MOVE G6D,93,  106, 145,  63, 105, 100
    WAIT

    SPEED 8
    GOSUB 기본자세
    GOSUB Leg_motor_mode1

    '한번 더
	GOSUB Leg_motor_mode2
    SPEED 8
    MOVE G6A,95,  46, 145,  123, 105, 100
    MOVE G6D,95,  106, 145,  63, 105, 100
    MOVE G6C,115
    MOVE G6B,85
    WAIT

    SPEED 10
    MOVE G6A,93,  46, 145,  123, 105, 100
    MOVE G6D,93,  106, 145,  63, 105, 100
    WAIT

	RETURN
    '**********************************************

연속오른쪽옆으로70:
    넘어진확인 = 0
    SPEED 7
    MOVE G6D, 90,  90, 120, 105, 110, 100
    MOVE G6A,100,  76, 146,  93, 107, 100
    MOVE G6B,100,  40
    MOVE G6C,100,  40
    WAIT
    SPEED 7
    MOVE G6D, 102,  76, 147, 93, 100, 100
    MOVE G6A,83,  78, 140,  96, 115, 100
    WAIT
    SPEED 7
    MOVE G6D,98,  76, 146,  93, 100, 100
    MOVE G6A,98,  76, 146,  93, 100, 100
    WAIT
    SPEED 7
    MOVE G6A,100,  76, 145,  93, 100, 100
    MOVE G6D,100,  76, 145,  93, 100, 100
    WAIT
    DELAY 300
    RETURN
    '*************
연속왼쪽옆으로70:
    넘어진확인 = 0
    SPEED 7
    MOVE G6A, 90,  90, 120, 105, 110, 100
    MOVE G6D,100,  76, 146,  93, 107, 100
    MOVE G6B,100,  40
    MOVE G6C,100,  40
    WAIT
    SPEED 7
    MOVE G6A, 102,  76, 147, 93, 100, 100
    MOVE G6D,83,  78, 140,  96, 115, 100
    WAIT
    SPEED 7
    MOVE G6A,98,  76, 146,  93, 100, 100
    MOVE G6D,98,  76, 146,  93, 100, 100
    WAIT
    SPEED 7
    MOVE G6A,100,  76, 145,  93, 100, 100
    MOVE G6D,100,  76, 145,  93, 100, 100
    WAIT
    DELAY 300
    RETURN
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
    MOVE G6C,100,  30,  80, 100, , 
    WAIT
    RETURN
    '*************************************
기본자세2:
    MOVE G6A,100,  76, 145,  93, 100, 100
    MOVE G6D,100,  76, 145,  93, 100, 100
    MOVE G6B,100,  30,  80,
    MOVE G6C,100,  30,  80
    WAIT

    mode = 0
    RETURN
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
RX_EXIT:

    ERX 4800, A, MAIN

    GOTO RX_EXIT
    '************************************************
SOUND_PLAY_CHK:
    DELAY 60
    SOUND_BUSY = IN(46)
    IF SOUND_BUSY = 1 THEN GOTO SOUND_PLAY_CHK
    DELAY 50

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
고개들기:
    SPEED 2
    MOVE G6C,100,  30,  80, 100, 100, 100
    WAIT
    SPEED 2
    MOVE G6C,100, 30, 80, 100, 120, 100
    RETURN

    '**************************************************
뒤로일어나기:

    HIGHSPEED SETOFF
    PTP SETON 				
    PTP ALLON		

    GOSUB 자이로OFF

    GOSUB All_motor_Reset

    SPEED 15
    GOSUB 기본자세

    MOVE G6A,90, 130, ,  80, 110, 100
    MOVE G6D,90, 130, 120,  80, 110, 100
    MOVE G6B,150, 160,  10, 100, 100, 100
    MOVE G6C,150, 160,  10, 100, 100, 100
    WAIT

    MOVE G6B,170, 140,  10, 100, 100, 100
    MOVE G6C,170, 140,  10, 100, 100, 100
    WAIT

    MOVE G6B,185,  20, 70,  100, 100, 100
    MOVE G6C,185,  20, 70,  100, 100, 100
    WAIT
    SPEED 10
    MOVE G6A, 80, 155,  85, 150, 150, 100
    MOVE G6D, 80, 155,  85, 150, 150, 100
    MOVE G6B,185,  20, 70,  100, 100, 100
    MOVE G6C,185,  20, 70,  100, 100, 100
    WAIT



    MOVE G6A, 75, 162,  55, 162, 155, 100
    MOVE G6D, 75, 162,  59, 162, 155, 100
    MOVE G6B,188,  10, 100, 100, 100, 100
    MOVE G6C,188,  10, 100, 100, 100, 100
    WAIT

    SPEED 10
    MOVE G6A, 60, 162,  30, 162, 145, 100
    MOVE G6D, 60, 162,  30, 162, 145, 100
    MOVE G6B,170,  10, 100, 100, 100, 100
    MOVE G6C,170,  10, 100, 100, 100, 100
    WAIT
    GOSUB Leg_motor_mode3	
    MOVE G6A, 60, 150,  28, 155, 140, 100
    MOVE G6D, 60, 150,  28, 155, 140, 100
    MOVE G6B,150,  60,  90, 100, 100, 100
    MOVE G6C,150,  60,  90, 100, 100, 100
    WAIT

    MOVE G6A,100, 150,  28, 140, 100, 100
    MOVE G6D,100, 150,  28, 140, 100, 100
    MOVE G6B,130,  50,  85, 100, 100, 100
    MOVE G6C,130,  50,  85, 100, 100, 100
    WAIT
    DELAY 100

    MOVE G6A,100, 150,  33, 140, 100, 100
    MOVE G6D,100, 150,  33, 140, 100, 100
    WAIT
    SPEED 10
    GOSUB 기본자세

    넘어진확인 = 1

    DELAY 200
    GOSUB 자이로ON

    RETURN
    '**********************************************
앞으로일어나기:


    HIGHSPEED SETOFF
    PTP SETON 				
    PTP ALLON

    GOSUB 자이로OFF

    HIGHSPEED SETOFF

    GOSUB All_motor_Reset

    SPEED 15
    MOVE G6A,100, 15,  70, 140, 100,
    MOVE G6D,100, 15,  70, 140, 100,
    MOVE G6B,20,  140,  15
    MOVE G6C,20,  140,  15
    WAIT

    SPEED 12
    MOVE G6A,100, 136,  35, 80, 100,
    MOVE G6D,100, 136,  35, 80, 100,
    MOVE G6B,20,  30,  80
    MOVE G6C,20,  30,  80
    WAIT

    SPEED 12
    MOVE G6A,100, 165,  70, 30, 100,
    MOVE G6D,100, 165,  70, 30, 100,
    MOVE G6B,30,  20,  95
    MOVE G6C,30,  20,  95
    WAIT

    GOSUB Leg_motor_mode3

    SPEED 10
    MOVE G6A,100, 165,  45, 90, 100,
    MOVE G6D,100, 165,  45, 90, 100,
    MOVE G6B,130,  50,  60
    MOVE G6C,130,  50,  60
    WAIT

    SPEED 6
    MOVE G6A,100, 145,  45, 130, 100,
    MOVE G6D,100, 145,  45, 130, 100,
    WAIT


    SPEED 8
    GOSUB All_motor_mode2
    GOSUB 기본자세
    넘어진확인 = 1

    '******************************
    DELAY 200
    GOSUB 자이로ON
    RETURN


앞뒤기울기측정:
    FOR i = 0 TO COUNT_MAX
        A = AD(앞뒤기울기AD포트)	'기울기 앞뒤
        IF A > 250 OR A < 5 THEN RETURN
        IF A > MIN AND A < MAX THEN RETURN
        DELAY 기울기확인시간
    NEXT i

    IF A < MIN THEN
        GOSUB 기울기앞
    ELSEIF A > MAX THEN
        GOSUB 기울기뒤
    ENDIF

    RETURN
    '**************************************************

기울기앞:
    A = AD(앞뒤기울기AD포트)
    'IF A < MIN THEN GOSUB 앞으로일어나기
    IF A < MIN THEN
        ETX  4800,16
        GOSUB 뒤로일어나기

    ENDIF
    RETURN

기울기뒤:
    A = AD(앞뒤기울기AD포트)
    'IF A > MAX THEN GOSUB 뒤로일어나기
    IF A > MAX THEN
        ETX  4800,15
        GOSUB 앞으로일어나기
    ENDIF
    RETURN


좌우기울기측정:
    FOR i = 0 TO COUNT_MAX
        B = AD(좌우기울기AD포트)	'기울기 좌우
        IF B > 250 OR B < 5 THEN RETURN
        IF B > MIN AND B < MAX THEN RETURN
        DELAY 기울기확인시간
    NEXT i

    IF B < MIN OR B > MAX THEN
        SPEED 8
        MOVE G6B,140,  40,  80
        MOVE G6C,140,  40,  80
        WAIT
        GOSUB 기본자세	
    ENDIF
    RETURN
    '******************************************

    '************************************************
우유팩잡기:

    SPEED 5
    MOVE G6A,100,  32, 180,  155, 100
    MOVE G6D,100,  32, 180,  155, 100
    MOVE G6B,185,  35,  80
    MOVE G6C,185,  35,  80
    WAIT
    'DELAY 1000 'delay로 잠시 확인

    '잡는간격
    MOVE G6B,190,  10,  58
    MOVE G6C,190,  10,  58
    WAIT
    'DELAY 1000

    SPEED 5
    MOVE G6A,100,  30, 170,  155, 100
    MOVE G6D,100,  30, 170,  155, 100
    WAIT
    'DELAY 1000

    SPEED 5
    MOVE G6A,100,  60, 150,  115, 100
    MOVE G6D,100,  60, 150,  115, 100
    WAIT
    'DELAY 1000

    SPEED 5
    MOVE G6A,100,  76, 145,  93, 100
    MOVE G6D,100,  76, 145,  93, 100


    WAIT
    'DELAY 2000

    RETURN

    '********************************************
우유팩놓기:

    SPEED 5
    MOVE G6A,100,  35, 170,  155, 100
    MOVE G6D,100,  35, 170,  155, 100
    WAIT
    'DELAY 1000 'delay로 잠시 확인

    MOVE G6B,150,  35,  80
    MOVE G6C,150,  35,  80
    WAIT
    'DELAY 1000

    SPEED 5
    MOVE G6A,100,  65, 150,  103, 100
    MOVE G6D,100,  65, 150,  103, 100
    MOVE G6B,100,  35,  90
    MOVE G6C,100,  35,  90
    WAIT
    'DELAY 1000

    SPEED 5
    MOVE G6A,100,  76, 145,  93, 100
    MOVE G6D,100,  76, 145,  93, 100
    WAIT
    'DELAY 1000

    RETURN	
