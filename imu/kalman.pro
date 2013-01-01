

; kalman.pro
;	an attempt to write a simple kalman filter that works on fake data
;	hopefully this will be easily ported to the IMU I'm using..
;
;	Model: (following wiki artile on Kalman filters)
;		an accelerometer measures linear acceleration, has noise, bias, drift
;		a GPS measures position, has noise
;
;		state vector is linear acceleration, velocity, and position
;
;		physics:
;
;		v_k = a_k-1 * dt      + v_k-1
;		x_k = a_k-1 * dt*dt/2 + v_k-1 * dt + x_k-1
;
;		x_k = F * x_k-1 + G * a_k + (known driving input)
;
;							[   1    0 ]
;		where F = [   dt   1 ]
;
;							[    dt   ]
;		and   G = [ dt*dt/2 ]
;
;		and w_k = ?
;		Q_k = covariance matrix of process noise?
;
;		measurement:
;
;		z_k = H * x_k + v_k
;		x_k is the real state vector, v_k is noise
;		so H = [ 1 0 1 ]
;		and v_k = [ s_a 0 s_x ]^T
;
;		initially:
;		x_k = [ 0 0 0 ]^T
;		with no incertainty:
;		P = 0 (3x3)
;		R = E[ v_k * v_k^T ] = ?
;
;		steps:
;			x_k = F * x_k-1 + (0)            predicted state estimate
;			P_k = F_k * P_k-1 * F_k^T + Q_k  predicted estimate covariance
;
;			y_k = z_k - H_k * x_k            measurement residual
;			S_k = H_k * P_K * H_k^T + R_k    residual covariance
;
;			K_k = P_k * H_k^T * S_k^-1       optimal Kalman gain
;
;			x_k = x_k + K_k * y_k            updated state estimate
;			P_k = (I - K_k * H_k) * P_K      updated estimate covariance
;

PRO kalman
	print, "start"
	log = fltarr(200)
	real = fltarr(200)
	dt = 0.01
	seed = 1234
	accel = 0.0
	speed = 0.0
	pos = 0.0

	x = fltarr(1,3)
	x_old = fltarr(1,3)
	z = fltarr(1,3)

	F = fltarr(3,3)
	F = [[1.0, 0.0, 0.0],[dt, 1.0, 0.0],[dt*dt/2., dt, 1.0]]

	for ii=0,199 do begin
		accel = 10.0*cos(ii*0.015) + randomn(seed)*0.1
		speed = speed + accel*dt
		pos = pos + speed*dt
		x_old = x
		; predicted
		x[0] = x_old[2]*dt*dt/2. + x_old[1]*dt + x_old[0]
		x[1] = x_old[2]*dt + x_old[1]
		x[2] = x_old[2]
		; measurement
		z = fltarr(3)
		if (ii mod 25 eq 0) then begin
			H = [[1.0, 1.0, 1.0]]
			z[0] = randomn(seed)*2.0 + pos; position
			z[1] = randomn(seed)*0.5 + speed ; velocity
			z[2] = randomn(seed)*2.0 + accel ; accel
		endif else begin
			H = [[0.0, 0.0, 1.0]]
			z[0] = 0.0 ; position
			z[1] = 0.0 ; velocity
			z[2] = randomn(seed)*2.0 + accel ; accel		
		endelse
		; residual
		y = z - H*x
		; kalman gain
		K = [0.5, 0.5, 0.5]
		; update
		x = x + K*y
		log[ii] = x[0,0]
		real[ii] = pos
	endfor
	plot, real, yrange=[-0.5,10.0]
	oplot, log, color=120

	print, "final error = ", stddev(log-real)
END

