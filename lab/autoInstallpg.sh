#!/bin/bash
echo -e "\033[32m引入pg rpm包\033[0m"
yum install -y https://mirrors.tuna.tsinghua.edu.cn/postgresql/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
echo -e "\033[32m卸载已安装pg\033[0m"
yum remove -y postgresql*
echo -e "\033[32m安装软件包\033[0m"
echo -e "\033[32m安装的版本号是？支持的版本 12 13 14\033[0m"
read version
echo -e "\033[32m开始安装postgresql-{version}\033[0m"
yum install postgresql${version} postgresql${version}-server -y
if [[ $?=0 ]];then
    echo -e "\033[32m初始化数据库  新建数据库目录,接收用户输入的路径\033[0m"
    read -p  "输入你要存储数据的路径:" path
else
    echo -e "\033[31m程序安装失败请确认\033[0m"
    exit 1
fi

if [ "${path:0:1}" = "/" ];then
    echo -e "\033[31m会清空此路径下的所有文件，请确认:(yes/no)\033[0m"
else
    echo "必须是绝对路径"
    exit 1
fi

read ans
if [[ $ans=yes ]];then
    rm -rf ${path}
    mkdir -p ${path}
else 
    exit 1
fi

echo "修改目录权限"
chown -R postgres:postgres ${path}
su postgres -c "/usr/pgsql-${version}/bin/initdb -D ${path}"
sed -i "s#/var/lib/pgsql/${version}/data/#${path}/#g" /usr/lib/systemd/system/postgresql-${version}.service
systemctl daemon-reload
systemctl enable postgresql-${version} && systemctl start postgresql-${version}
echo "等待pg启动成功"
sleep 10
status=`ps -ef|grep postgres|grep -v grep|wc -l`
if (( ${status}==0 ));then
    echo -e "\033[32m程序启动失败\033[0m"
    exit 1
else
    echo -e "\033[32mpostgresql 进程正常开启，请慢用\033[0m"
fi

