# FosEye - integration between Foscam and MotionEye
FosEye is a small Docker container based on alpine:latest that monitors every X seconds a Foscam C1 camera/cameras by utilizing camera's integrated PIR and sound sensors. Upon detection, the script triggers a MotionEye recording for the camera. This offloads the MotionEye server CPU from having to deal with the motion detection alarm triggering, which is also sometimes trickier to configure than the integrated camera PIR/sound sensors. The sensitivity of each camera sensor can be configured via the C1 camera web interface.

# Preparations

## First ensure that your MotionEye instance accepts external calls:
Edit motion.conf :
```
...
webcontrol_localhost off
webcontrol_auth_method 1
webcontrol_authentication "meyeuser:meyepass"
...
```
## Setup the Docker config volume
Create a docker volume and attach it as /foseye/config

    docker volume create foseye_config


## Setup the camera config files
Create .cfg file for each camera inside the volume:

    Example: camera1.cfg
    ```
    cat << EOF | sudo tee -a /var/lib/docker/volumes/foseye_config/_data/camera1.cfg
    # Camera setup:
    cam_ip="http://xx.xx.xx.xx:88"	            # IP:port of the camera web interface
    cam_usr="user"			 	                # Camera username
    cam_pwd="pass"		 	                    # Camera password
    cam_alarm1="motionDetectAlarm"              # Comment out that line if you don't want to have alarm1    (motionDetectAlarm) enabled
    cam_alarm2="soundAlarm"                     # Comment out that line if you don't want to have alarm2 (soundAlarm)   enabled
    cam_alarm_timer="1"                         # How often in seconds to check the camera for new alarms

    # Motioneye setup:
    meye_host="http://xx.xx.xx.xx:7999"		    # Motineye API interface
    meye_cam="1"			                    # Monitoreye camera index
    meye_auth="meyeuser:meyepass"	            # Motioneye API username:password (motion.conf ->   webcontrol_authentication)
    EOF
    ```

## (optional) Setup the Docker logs volume for /foseye/logs
    docker volume create foseye_logs


# Build the Docker image
    ./build.sh

# Start the container
    docker run -it -v foseye_config:/foseye/config -v foseye_logs:/foseye/logs --name foseye foseye:latest

You should see an output:
```
Starting the monitoring for camera1.cfg (config/camera1.cfg)...
Monitoring started for camera1.cfg (config/camera1.cfg)
```

Open a new terminal and attach to the container:

    docker exec -it foseye bash -c 'tail logs/*'

The outcome should be:
```
==> logs/camera1.cfg.log <==
Tue May 24 18:17:02 UTC 2022|camera1.cfg|Starting the monitoring script for camera1.cfg
Tue May 24 18:17:02 UTC 2022|camera1.cfg|Initiating monitoring for 1 (http://xx.xx.xx.xx:88) via Motioneye (http://xx.xx.xx.xx:7999), verifying the connection...
Tue May 24 18:17:03 UTC 2022|camera1.cfg|Connection to 1 (http://xx.xx.xx.xx:88) has been established, checking for new alarms every 1 second...
Tue May 24 18:17:04 UTC 2022|camera1.cfg|motionDetectAlarm event on 1 (http://xx.xx.xx.xx:88), triggering Motioneye (http://xx.xx.xx.xx:7999) alarm !Tue May 24 18:17:30 UTC 2022|camera1.cfg|Connection to 1 (http://xx.xx.xx.xx:88) has been established, checking for new alarms every 1 second...
Tue May 24 18:17:45 UTC 2022|camera1.cfg|motionDetectAlarm event on 1 (http://xx.xx.xx.xx:88), triggering Motioneye (http://xx.xx.xx.xx:7999) alarm !
==> logs/foshi.log <==
Tue May 24 18:17:02 UTC 2022|camera1.cfg|Initiating monitoring for 1 (http://http://xx.xx.xx.xx:88) via Motioneye (http://xx.xx.xx.xx:7999), appending to log file: logs/camera1.cfg.log
single_monitor.sh: line 94: [: ==: unary operator expected
single_monitor.sh: line 94: [: ==: unary operator expected
```