#!/usr/bin/env python
# license removed for brevity

import socket
import rospy
from geometry_msgs.msg import Twist

UDP_IP = "192.168.4.1"
UDP_PORT = 2018

sock = socket.socket(socket.AF_INET, # Internet
                     socket.SOCK_DGRAM) # UDP
sock.bind((UDP_IP, UDP_PORT))

def get_sensors_data():
    pub = rospy.Publisher('chatter', String, queue_size=10)
    while not rospy.is_shutdown():
        hello_str = "hello world %s" % rospy.get_time()
        data, addr = sock.recvfrom(1024) # buffer size is 1024 bytes
        rospy.loginfo("received message:" + data)
        pub.publish(data)

def new_cmd_vel(data):
    DELIMITER = "*"
    CMD_SPEED = "speed"
    robotito_cmd_vel = CMD_SPEED + DELIMITER + twist.linear.x + DELIMITER + twist.linear.y + DELIMITER + twist.angular.z
    rospy.loginfo(rospy.get_caller_id() + "send command: %s", robotito_cmd_vel)
    sock.sendto(robotito_cmd_vel, (UDP_IP, UDP_PORT))

if __name__ == '__main__':
    try:
        rospy.init_node('remote_robotito', anonymous=True)
        rospy.Subscriber("cmd_vel", Twist, new_cmd_vel)
        get_sensors_data()
    except rospy.ROSInterruptException:
        pass
