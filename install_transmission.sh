#!/bin/bash
#===================================================================================
#         FILE: install_transmission.sh
# 
#        USAGE: ./install_transmission.sh [-u user_name] [-p] [-r]
# 
#  DESCRIPTION: Install transmission on Seagate GoFlex Home
# 
# REQUIREMENTS: transmission-1_92_ARM_Stora_tar.gz
#         BUGS: ---
#        NOTES: Automate the installation of transmission client on Seagate GoFlex 
#               Home. 
#               The transmission client will be downloaded from an external link or
#               can be manually downloaded and place it in the same folder.
#               Run the script after gaining root access with command "sudo -E -s) 
#       AUTHOR: John A.K. (Jak's Lab - http://kjohna.wordpress.com/)
#      VERSION: 0.93
#      CREATED: 30-June-2012
#     MODIFIED: 17-July-2012
#
# This software is provided by the copyright holders and contributors "as is" and 
# any express or implied warranties, including, but not limited to, the implied 
# warranties of merchantability and fitness for a particular purpose are disclaimed.
# In no event shall the copyright owner or contributors be liable for any direct, 
# indirect, incidental, special, exemplary, or consequential damages (including, 
# but not limited to, procurement of substitute goods or services; loss of use, 
# data, or profits; or business interruption) however caused and on any theory of 
# liability, whether in contract, strict liability, or tort (including negligence 
# or otherwise) arising in any way out of the use of this software, even if advised 
# of the possibility of such damage. 
#===================================================================================

PKGURL="http://www.openstora.com/files/albums/uploads/transmission-1_92_ARM_Stora_tar.gz"  
BINPATH="/usr/local/bin"
WEBPATH="/usr/share/transmission"
SCRIPTPATH="/etc/init.d"
SETTINGSPATH="/home/.config/transmission-daemon"
#DLPATH="/home/$DAEMONUSER/GoFlex Home Public/Torrent Downloads"
#WTPATH="$DLPATH/Torrents"
JSONDLPATH="\\\\\/home\\\\\/.config\\\\\/transmission-daemon\\\\\/Downloads"
JSONWTPATH="\\\\\/home\\\\\/.config\\\\\/transmission-daemon\\\\\/myTorrentFolder"


# Sub-function to download transmission
get_transmission() {
    if [ $(ls | grep -ic "transmission-1_92_ARM_Stora_tar.gz") -eq 0 ]; then
        temp=$(wget -nv http://www.openstora.com/files/albums/uploads/transmission-1_92_ARM_Stora_tar.gz 2>&1)
        if [ $(echo $temp | grep -ic "ERROR 404") -eq 1 ]; then
            echo "[Error -001] Failed to download transmission client. Check internet connection."
            uninstall_daemon
            exit 1
        elif [ $(echo $temp | grep -ic "Command not found") -eq 1 ]; then
            echo "[Error -002] Cannot find wget tool. Manually download transmission client from the link:"
            echo "        http://www.openstora.com/files/albums/uploads/transmission-1_92_ARM_Stora_tar.gz"
            uninstall_daemon
            exit 1
        fi
        echo "Downloading transmission client...Done"
    else
        echo "Search for package...Done"
    fi            
}


# Sub-function to decompress package
decompress_pkg() {
    temp=$(tar -xzvf transmission-1_92_ARM_Stora_tar.gz 2>&1)
    if [ $(ls | grep -xc "transmission") -eq 0 ]; then
        echo "[Error -101] File may be corrupted or permission error"
        uninstall_daemon
        exit 1
    else
        echo "Decompressing the package...Done"
    fi
}


# Sub-function to copy binary and scripts
install_daemon() {
    temp=$(mkdir -p $BINPATH 2>&1)
    if [ $(echo $temp | grep -ic "Permission denied") -eq 1 ]; then
        echo "[Error -201] Cannot create folder"
        uninstall_daemon
        exit 1
    fi
    
    temp=$(cp transmission/transmission-daemon $BINPATH 2>&1)
    if [ $(echo $temp | grep -ic "Cannot open: No such file or directory") -eq 1 ]; then
        echo "[Error -202] Cannot copy file"
        uninstall_daemon
        exit 1
    fi

    temp=$(chmod 0755 $BINPATH/transmission-daemon 2>&1)
    if [ $(echo $temp | grep -ic "chmod:") -eq 1 ]; then
        echo "[Error -203] Cannot change permission"
        uninstall_daemon
        exit 1
    fi
    
    temp=$(mkdir -p $WEBPATH 2>&1)
    if [ $(echo $temp | grep -ic "Permission denied") -eq 1 ]; then
        echo "[Error -204] Cannot create folder"
        uninstall_daemon
        exit 1
    fi
    
    temp=$(cp -r transmission/web $WEBPATH 2>&1)
    if [ $(echo $temp | grep -ic "Permission denied") -eq 1 ]; then
        echo "[Error -205] Cannot copy folder"
        uninstall_daemon
        exit 1
    fi

    temp=$(mkdir -p $SCRIPTPATH 2>&1)
    if [ $(echo $temp | grep -ic "Permission denied") -eq 1 ]; then
        echo "[Error -206] Cannot create folder"
        uninstall_daemon
        exit 1
    fi
    
    temp=$(cp transmission/init.d/transmission-daemon $SCRIPTPATH/transmissiond 2>&1)
    if [ $(echo $temp | grep -ic "Permission denied") -eq 1 ]; then
        echo "[Error -207] Cannot copy file"
        uninstall_daemon
        exit 1
    fi
    
    echo "Installing the package...Done"
}


#Sub-function to start daemon
start_daemon() {
    temp=$($SCRIPTPATH/transmissiond start 2>&1)
    if [ $(echo $temp | grep -ic "[ OK ]") -eq 0 ]; then
        echo "[Error -301] Could not start transmission daemon"
        uninstall_daemon
        exit 1
    else
        echo "Starting transmission daemon...Done"    
    fi    
}


#Sub-function to stop daemon
stop_daemon() {
    temp=$($SCRIPTPATH/transmissiond stop 2>&1)
    if [ $(echo $temp | grep -ic "[ OK ]") -eq 0 ]; then
        echo "[Error -302] Could not stop transmission daemon"
        uninstall_daemon
        exit 1
    else
        echo "Stopping transmission daemon...Done"    
    fi    
}


#Sub-function to configure transmission daemon
configure_daemon() {
    temp=$(mkdir -p $SETTINGSPATH 2>&1)
    if [ $(echo $temp | grep -ic "Permission denied") -eq 1 ]; then
        echo "[Error -303] Cannot create settings folder"
        exit 1
    fi

    temp=$(chown -R $DAEMONUSER:$DAEMONUSER $SETTINGSPATH 2>&1)
    if [ $(echo $temp | grep -ic "chown:") -eq 1 ]; then
        echo "[Error -304] Cannot change permission"
        uninstall_daemon
        exit 1
    fi
    
    temp=$(sed -i -e "s/^# chkconfig:.*/# chkconfig: - 99 30/g" $SCRIPTPATH/transmissiond 2>&1)
    if [ $(echo $temp | grep -ic "sed:") -eq 1 ]; then
        echo "[Error -305] Cannot edit settings file"
        uninstall_daemon
        exit 1
    fi
    
    temp=$(sed -i -e "s/^DAEMON_USER.*/DAEMON_USER="\"$DAEMONUSER\""/g" $SCRIPTPATH/transmissiond 2>&1)
    if [ $(echo $temp | grep -ic "sed:") -eq 1 ]; then
        echo "[Error -306] Cannot edit settings file"
        uninstall_daemon
        exit 1
    fi

    start_daemon
    sleep 0.5

    stop_daemon
    sleep 0.5

    temp=$(mkdir -p "$DLPATH" 2>&1)
    if [ $(echo $temp | grep -ic "Permission denied") -eq 1 ]; then
        echo "[Error -307] Cannot create downloads folder"
        uninstall_daemon
        exit 1
    fi

    temp=$(ln -s "$DLPATH/" "$SETTINGSPATH/Downloads" 2>&1)
    if [ $(echo $temp | grep -ic "ln:") -eq 1 ]; then
        echo "[Error -308] Cannot create downloads folder"
        uninstall_daemon
        exit 1
    fi

    temp=$(sed -i "s/^.*download-dir.*/    \"download-dir\": \"$JSONDLPATH\",/g" $SETTINGSPATH/settings.json 2>&1)
    if [ $(echo $temp | grep -ic "sed:") -eq 1 ]; then
        echo "[Error -309] Cannot edit settings file"
        uninstall_daemon
        exit 1
    fi

    temp=$(sed -i "s/^.*rpc-whitelist.*/    \"rpc-whitelist\": \"127.0.0.1,192.168.*.*\",/g" $SETTINGSPATH/settings.json 2>&1)
    if [ $(echo $temp | grep -ic "sed:") -eq 1 ]; then
        echo "[Error -310] Cannot edit settings file"
        uninstall_daemon
        exit 1
    fi

    temp=$(mkdir -p "$WTPATH" 2>&1)
    if [ $(echo $temp | grep -ic "Permission denied") -eq 1 ]; then
        echo "[Error -311] Cannot create torrent watch folder"
        uninstall_daemon
        exit 1
    fi

    temp=$(ln -s "$WTPATH/" "$SETTINGSPATH/myTorrentFolder" 2>&1)
    if [ $(echo $temp | grep -ic "ln:") -eq 1 ]; then
        echo "[Error -312] Cannot create torrent watch folder"
        uninstall_daemon
        exit 1
    fi

    temp=$(sed -i "s/^}/,\n    \"watch-dir\": \"$JSONWTPATH\",\n    \"watch-dir-enabled\": true\n}/g" $SETTINGSPATH/settings.json 2>&1)
    if [ $(echo $temp | grep -ic "sed:") -eq 1 ]; then
        echo "[Error -313] Cannot edit settings file"
        uninstall_daemon
        exit 1
    fi

    temp=$(/sbin/chkconfig --list 2>&1)
    if [ $(echo $temp | grep -ic "transmission-daemon") -ne 0 ]; then
       temp=$(/sbin/chkconfig --del transmission-daemon) 
    fi
    temp=$(/sbin/chkconfig --list 2>&1)
    if [ $(echo $temp | grep -ic "transmissiond") -ne 0 ]; then
       temp=$(/sbin/chkconfig --del transmissiond) 
    fi

    temp=$(/sbin/chkconfig --add transmissiond 2>&1)
    temp=$(/sbin/chkconfig --levels 345 transmissiond on 2>&1)
    
    echo "Configuring the package...Done"
}


# Sub-function to uninstall transmission
uninstall_daemon() {
    temp=$(ps -ef 2>&1)
    if [ $(echo $temp | grep -ic "/usr/local/bin/transmission-daemon") -eq 1 ]; then
        stop_daemon
        sleep 1
    fi		 

    temp=$([ -f $BINPATH/transmission-daemon ] && rm $BINPATH/transmission-daemon 2>&1)
    if [ $(echo $temp | grep -ic "rm:") -ne 0 ]; then
        echo "[Error -411] Cannot delete transmission daemon"
        exit 1
    fi        	
    
    temp=$([ -f $SCRIPTPATH/transmissiond ] && rm $SCRIPTPATH/transmissiond 2>&1)
    if [ $(echo $temp | grep -ic "rm:") -ne 0 ]; then
        echo "[Error -412] Cannot delete transmission daemon script"
        exit 1
    fi        	
    
    temp=$([ -d $WEBPATH ] && rm -r $WEBPATH 2>&1)
    if [ $(echo $temp | grep -ic "rm:") -ne 0 ]; then
        echo "[Error -413] Cannot delete transmission web folder"
        exit 1
    fi        	
    
    temp=$([ -d $SETTINGSPATH ] && rm -r $SETTINGSPATH 2>&1)
    if [ $(echo $temp | grep -ic "rm:") -ne 0 ]; then
        echo "[Error -414] Cannot delete transmission settings folder"
        exit 1
    fi        	
    
    temp=$(/sbin/chkconfig --list 2>&1)
    if [ $(echo $temp | grep -ic "transmission-daemon") -ne 0 ]; then
       temp=$(/sbin/chkconfig --del transmission-daemon) 
    fi
    
    temp=$(/sbin/chkconfig --list 2>&1)
    if [ $(echo $temp | grep -ic "transmissiond") -ne 0 ]; then
       temp=$(/sbin/chkconfig --del transmissiond) 
    fi

    echo "Removing the package...Done"
}



# Get options from command line
if [ $# -eq 0 ]; then
    echo "No option to execute"
    echo "Usage: $0 [-u user_name] [-p] [-r]"
    exit 1
fi

while getopts u:rhp opt
do
    case "$opt" in
        u)    DAEMONUSER="$OPTARG"
              if [ "$DAEMONUSER" = "" ]; then
                  echo "Username cannot be empty"
                  echo "Usage: $0 [-u user_name] [-p]"
                  exit 1
              fi
                  
              DLPATH="/home/$DAEMONUSER/GoFlex Home Public/Torrent Downloads"
              WTPATH="$DLPATH/Torrents"
              ;;
        p)    if [ "$DAEMONUSER" = "" ]; then
                  echo "User name not set"
                  echo "Usage: $0 [-u user_name] [-p]"
                  exit 1
              fi
              
              DLPATH="/home/$DAEMONUSER/GoFlex Home Personal/Torrent Downloads"
              WTPATH="$DLPATH/Torrents"
              ;;  
        r)    echo "Uninstalling transmission client from Seagate GoFlex Home"
              
              # Uninstall transmission client
              uninstall_daemon
              exit 0
              ;;
        h)    echo "Usage: $0 [-u user_name] [-p] [-r]"
              exit 0
              ;;
        \?)   echo "Illegal option"
              echo "Usage: $0 [-u user_name] [-p] [-r]"
              exit 1
              ;;
     esac
done

echo "Installing for Seagate GoFlexHome user \"$DAEMONUSER\""

# Script starts installing transmission client
# Download transmission client
get_transmission
              
# Decompress the package
decompress_pkg
              
# Install transmission client
install_daemon
              
# Configure transmission daemon
configure_daemon

# Start transmission daemon
start_daemon
sleep 0.5
    
exit 0

