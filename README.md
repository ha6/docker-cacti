# docker-cacti
此镜像为cacti1.10（可更新）的docker镜像
本镜像不含数据库，数据库需要单独安装

创建docker镜像
`docker build -t babyfenei/cacti .`
启动docker镜像
`docker run -d -it -p 80:80  -p 9111:9111 --name cacti babyfenei/cacti` 
