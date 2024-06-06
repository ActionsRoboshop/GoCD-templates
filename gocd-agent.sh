R="\e[31m"
G="\e[32m"
N="\e[0m"

Stat() {
[ $1 -ne 0 ] && echo -e "${R}$2 is Failure ${N}" && echo "Check for more logs --> /tmp/gocd-agent.log" && exit 1 || echo -e "${G}$2 is Success ${N}"
}



dnf install java-17-openjdk.x86_64 -y  &>/tmp/gocd-agent.log
Stat $? "Install Java"

id go  &>>/tmp/gocd-agent.log
if [ $? -eq 0 ]; then
  kill -9 `ps -u go | grep -v PID | awk '{print $1}'` &>>/tmp/gocd-agent.log
  userdel -rf go
fi
useradd go  &>>/tmp/gocd-agent.log
Stat $? "Adding GoCD user"

curl -L -o /tmp/go-agent-23.5.0-18179.zip https://download.gocd.org/binaries/23.5.0-18179/generic/go-agent-23.5.0-18179.zip &>>/tmp/gocd-agent.log
Stat $? "Download GoCD zip File"


mkdir -p /gocd &>>/tmp/gocd-agent.log
Stat $? "Creating directory"

unzip  -o /tmp/go-agent-23.5.0-18179.zip -d /gocd &>>/tmp/gocd-agent.log && rm -rf /tmp/go-agent-23.5.0-18179.zip
Stat $? "Unzipping GoCD zip file"



chown -R go:go /gocd
Stat $? "Change ownership -> /gocd/go-agent"

echo '
[Unit]
Description=GoCD Server

[Service]
Type=forking
User=go
ExecStart=/gocd/go-agent/bin/go-agent start sysd
ExecStop=/gocd/go-agent/bin/go-agent stop sysd
KillMode=control-group
Environment=SYSTEMD_KILLMODE_WARNING=true

[Install]
WantedBy=multi-user.target
' > /etc/systemd/system/gocd.service
Stat $? "Setup systemd GoCD Agent Service file"


systemctl daemon-reload &>>/tmp/gocd-agent.log
systemctl enable gocd &>>/tmp/gocd-agent.log
Stat $? "Enable GoCD Agent Service"

systemctl start gocd &>>/tmp/gocd-agent.log
Stat $? "Start GoCD Agent Service"

echo -e "\n \n -> Open this file \e[1;33m/gocd/go-agent/wrapper-config/wrapper-properties.conf\e[0m & Update \e[1;33mwrapper.app.parameter.101\e[0m line and replace \e[1;31mlocalhost\e[0m with gocd server ip address and restart gocd-agent service"
echo -e "To restart service \e[1;33msystemctl restart gocd\e[0m"

