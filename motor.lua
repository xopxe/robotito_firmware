-- https://www.dfrobot.com/product-1487.html
-- PPM signal pulse width range: 500us-2500us
-- Clockwise pulse width range: 500us-1400us (500us speed maximum)
-- Stop pulse width range: 1400us-1600us
-- Anticlockwise pulse width range: 1600us-2500us (2500us speed maximum)
-- PWM frequency: 500 Hz. 

ZERO_PULSE_WIDTH = 1500
MAX_CLOCKWISE_PULSE_WIDTH = 500
MIN_CLOCKWISE_PULSE_WIDTH = 1400
MAX_ACLOCKWISE_PULSE_WIDTH = 2500
MIN_ACLOCKWISE_PULSE_WIDTH = 1600
MAX_RPM = 100
MIN_RPM = 0
PWM_FREC = 390 -- must be < 400
ALFA = 0.2
TIME_OUT = 30

local device, pwm_pin

-- evalua la funcion de una recta en x dado dos puntos (x1, y1) y (x2, y2)
function line(x1, y1, x2, y2, x)
	return (y2-y1)/(x2-x1)*(x-x1)+y1
end

-- rpm to pulse width
function rpm2pw(rpm)
	if rpm == 0 then
		return ZERO_PULSE_WIDTH
	else 
		if rpm > 0 then
			return line(MAX_RPM, MAX_CLOCKWISE_PULSE_WIDTH, MIN_RPM, MIN_CLOCKWISE_PULSE_WIDTH, rpm)
		else
			return line(MIN_RPM, MIN_ACLOCKWISE_PULSE_WIDTH, MAX_RPM, MAX_ACLOCKWISE_PULSE_WIDTH, -rpm)
		end
	end
end

function rpm2duty(rpm)
	return rpm2pw(rpm)*PWM_FREC/1000000 -- useg
end

function stop()
	if device then
		set_pow(0)
		device:detach()
	end
end

function set_pow(rpm)
	if not device then
		device = pwm.attach(pwm_pin, PWM_FREC, rpm2duty(rpm))
	else
		device:setduty(rpm2duty(rpm))
	end
end

function init(pwm_pin)
	if not device then
		device = pwm.attach(pwm_pin, PWM_FREC, rpm2duty(0))
		actual_pow = 0
		target_pow = 0
	end
	pwm_pin = pin
	device:start()
end

function set_target_pow(pow)
	target_pow = pow
	smooth_set_pow()-- deberia invocarse en un hilo o int
end

function smooth_set_pow()
	actual_pow = actual_pow + ALFA * (target_pow-actual_pow)
	set_pow(actual_pow)
end

function horario_antihorario()
	_vel = MAX_RPM

	while true do 
		if time == TIME_OUT then
			_vel = - _vel
			time = 0
		end
		set_target_pow(_vel)
		tmr.delayus(500*1000)
		time = time + 1
		print(tostring(actual_pow))
	end -- while true
end
-- init(pio.GPIO17)