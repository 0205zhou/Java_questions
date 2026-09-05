---
id: q0106
question: "Linux常用命令？"
category: os
tags: ["Linux", "Shell", "文件管理", "进程管理", "网络排障"]
difficulty: medium
created: 2026-09-05 09:10:00
source: 用户输入
---

# Linux常用命令？

## 联想记忆法

### 记忆口诀/联想

**口诀：文件先定位，内容再查看；权限看属主，进程看状态；网络查连接，日志用管道。**

把 Linux 命令想成一套排障工具箱：

- `pwd`、`ls`、`cd`、`find` 负责找到目标。
- `cat`、`less`、`head`、`tail` 负责查看内容。
- `grep`、`awk`、`sed` 负责筛选和加工文本。
- `ps`、`top`、`kill` 负责观察和管理进程。
- `ss`、`curl`、`ping`、`dig` 负责检查网络。
- `chmod`、`chown`、`sudo` 负责权限和身份。

### 记忆原理

命令不应该按字母表死记，而要按工作流记：**定位 → 查看 → 过滤 → 修改 → 验证**。面试中先讲分类，再给出常见命令和一个完整排障例子，比只罗列几十个命令更容易体现实际使用能力。

### 关联知识

- Shell 参数、通配符、环境变量和退出码。
- 管道（Pipe）、重定向（Redirection）和命令替换。
- 文件权限、用户组、sudo 和最小权限原则。
- 进程、线程、端口、日志、磁盘和网络排障。
- `systemd` 服务管理和 Linux 目录结构。

---

## 深度解答

### 第一层：核心概念

Linux 命令通常是由 Shell 解释并交给操作系统执行的程序或内建指令。常用命令可以按照用途分为：

| 类别 | 常用命令 | 主要用途 |
|---|---|---|
| 路径和文件 | `pwd`、`ls`、`cd`、`mkdir`、`cp`、`mv`、`rm` | 定位、创建和管理文件 |
| 查找和文本 | `find`、`locate`、`grep`、`less`、`head`、`tail` | 查找文件、查看和筛选内容 |
| 文本处理 | `sort`、`uniq`、`wc`、`cut`、`awk`、`sed` | 统计、提取和转换文本 |
| 权限和用户 | `chmod`、`chown`、`id`、`whoami`、`sudo` | 管理权限和身份 |
| 进程和服务 | `ps`、`top`、`kill`、`jobs`、`systemctl` | 观察和控制进程服务 |
| 磁盘和内存 | `df`、`du`、`free`、`mount` | 检查容量、挂载和内存 |
| 网络排障 | `ip`、`ss`、`ping`、`curl`、`dig`、`traceroute` | 检查地址、端口和连通性 |
| 压缩和传输 | `tar`、`gzip`、`zip`、`scp`、`rsync` | 归档、压缩和文件同步 |

### 第二层：文件和目录命令

#### 1. 查看当前位置和目录内容

```bash
pwd
ls
ls -la
ls -lh
cd /var/log
cd -
```

- `pwd` 显示当前工作目录。
- `ls` 列出目录内容。
- `-l` 查看详细信息，包括权限、属主、大小和修改时间。
- `-a` 显示隐藏文件。
- `-h` 以更易读的单位显示文件大小。
- `cd` 切换目录，`cd -` 返回上一个目录。

Linux 中以 `.` 开头的文件通常是隐藏文件，例如 `.bashrc`、`.ssh`。查看配置时经常需要使用 `ls -la`。

#### 2. 创建、复制、移动和删除

```bash
mkdir -p /opt/app/logs
touch app.log
cp app.log app.log.bak
cp -r config /opt/app/
mv app.log /opt/app/logs/
rm app.log.bak
rm -r old_logs
```

- `mkdir -p` 可以递归创建不存在的目录。
- `touch` 创建空文件或更新文件时间。
- `cp` 复制文件，复制目录时通常使用 `-r`。
- `mv` 用于移动或重命名。
- `rm` 删除文件，`rm -r` 删除目录及其内容。

`rm -rf` 具有很强的破坏性，生产环境不应直接对不确定的路径执行。删除前可以先用 `pwd`、`ls` 和 `find` 确认目标，脚本中还应对变量为空、路径异常和权限进行检查。

#### 3. 查找文件

```bash
find /var/log -type f -name "*.log"
find /opt/app -type f -size +100M
find /tmp -type f -mtime +7
find /var/log -type f -name "*.log" -print0 | xargs -0 grep -n "ERROR"
```

`find` 适合按照目录、类型、名称、大小、时间和权限查找文件：

- `-type f` 表示普通文件。
- `-name` 按名称匹配，`*` 是通配符。
- `-size +100M` 查找大于 100 MB 的文件。
- `-mtime +7` 查找七天以前修改过的文件。

如果文件名包含空格或特殊字符，配合 `-print0` 和 `xargs -0` 比直接拼接字符串更安全。

### 第三层：查看和处理文本

#### 1. 查看文件内容

```bash
cat application.yml
less application.log
head -n 20 application.log
tail -n 100 application.log
tail -f application.log
```

- `cat` 适合查看较小文件或拼接文件。
- `less` 支持分页、搜索和上下翻页，适合大文件。
- `head` 查看文件开头。
- `tail` 查看文件末尾。
- `tail -f` 持续跟踪追加内容，常用于观察实时日志。

查看日志时不建议对几个 GB 的文件直接使用 `cat`，否则会把大量内容刷到终端，影响定位效率。

#### 2. 搜索文本

```bash
grep -n "ERROR" application.log
grep -i "timeout" application.log
grep -E "ERROR|WARN" application.log
grep -R "server.port" /etc/nginx/
```

`grep` 可以在文件中查找匹配文本：

- `-n` 显示行号。
- `-i` 忽略大小写。
- `-E` 使用扩展正则。
- `-R` 递归搜索目录。

常见组合：

```bash
grep -n "ERROR" application.log | tail -n 20
grep -oE "userId=[0-9]+" application.log | sort | uniq -c | sort -nr | head
```

第一条先筛选错误，再看最近 20 条；第二条提取用户 ID，统计出现次数并倒序排序。

#### 3. 统计和格式化文本

```bash
wc -l application.log
sort access.log | uniq -c | sort -nr | head
cut -d' ' -f1 access.log
awk '{print $1, $7, $9}' access.log
sed -n '1,20p' application.log
sed -i 's/old-host/new-host/g' application.conf
```

- `wc -l` 统计行数。
- `sort` 排序。
- `uniq -c` 统计连续重复行，通常要先排序。
- `cut` 按分隔符提取列。
- `awk` 适合按列处理结构化文本。
- `sed` 适合替换、删除和选择文本。

使用 `sed -i` 修改配置前应先备份并确认匹配范围，尤其要注意正则表达式可能替换多处内容。生产环境更推荐通过配置管理和版本控制发布变更。

### 第四层：权限、用户和环境

#### 1. 查看用户和身份

```bash
whoami
id
who
last
env
echo "$PATH"
```

- `whoami` 查看当前用户名。
- `id` 查看用户 ID、组 ID 和所属组。
- `who` 查看当前登录用户。
- `last` 查看登录历史。
- `env` 查看环境变量。
- `echo "$PATH"` 查看 Shell 搜索可执行文件的路径。

#### 2. 查看和修改权限

```bash
ls -l app.sh
chmod u+x app.sh
chmod 640 application.yml
chown appuser:appgroup application.yml
```

权限字符串例如：

```text
-rwxr-x---
```

可以拆成三组：

```text
文件类型 | 属主权限 | 用户组权限 | 其他用户权限
    -    |   rwx    |    r-x     |     ---
```

其中 `r` 是读、`w` 是写、`x` 是执行。数字权限中：

- `4` 表示读。
- `2` 表示写。
- `1` 表示执行。

因此 `640` 表示属主可读写、用户组只读、其他用户无权限。`chown` 修改文件属主和用户组，通常需要管理员权限。

#### 3. 使用 sudo

```bash
sudo systemctl restart nginx
sudo -u appuser whoami
```

`sudo` 允许当前用户以授权的其他身份执行命令。生产环境应遵循最小权限原则，不要习惯性使用 `sudo su` 或对整个目录执行 `chmod -R 777`。权限问题应先查看当前用户、文件属主、目录权限和 SELinux/AppArmor 等安全策略。

### 第五层：进程、服务和任务

#### 1. 查看进程

```bash
ps aux
ps -ef | grep java
top
```

- `ps aux` 查看当前系统进程和资源占用。
- `ps -ef` 查看进程层级、父进程和启动命令。
- `top` 动态查看 CPU、内存和进程状态。

更精确地查找进程可以使用：

```bash
pgrep -af java
pidof nginx
```

#### 2. 结束进程

```bash
kill -15 12345
kill -9 12345
pkill -f "my-service.jar"
```

`kill -15` 发送 `SIGTERM`，给应用一个优雅退出和清理资源的机会；只有进程无响应时才考虑 `kill -9` 的 `SIGKILL`。`kill -9` 不能被进程捕获，可能导致临时文件、事务、连接和业务状态没有正常清理。

#### 3. 管理 systemd 服务

```bash
systemctl status nginx
sudo systemctl start nginx
sudo systemctl stop nginx
sudo systemctl restart nginx
sudo systemctl reload nginx
sudo systemctl enable nginx
journalctl -u nginx -n 100 --no-pager
journalctl -u nginx -f
```

- `start` 启动服务。
- `stop` 停止服务。
- `restart` 重启服务。
- `reload` 让服务重新读取配置，是否支持取决于具体服务。
- `enable` 设置开机启动。
- `status` 查看状态和最近错误。
- `journalctl` 查询 systemd 日志。

修改服务配置后，推荐先做配置检查，再 reload；如果必须 restart，也要评估连接中断和业务影响。

#### 4. 后台任务和定时任务

```bash
command &
jobs
fg %1
bg %1
nohup java -jar app.jar > app.log 2>&1 &
crontab -l
crontab -e
```

- `&` 让命令在后台运行。
- `jobs` 查看当前 Shell 的后台任务。
- `fg` 和 `bg` 切换前后台。
- `nohup` 让进程尽量不受终端退出影响。
- `crontab` 管理当前用户的定时任务。

长期运行的生产服务更适合交给 systemd、容器编排平台或进程管理器，而不是简单依赖 `nohup`。

### 第六层：磁盘、内存和网络排障

#### 1. 磁盘和目录大小

```bash
df -h
du -sh /var/log
du -h --max-depth=1 /var | sort -h
lsblk
mount
```

- `df -h` 查看文件系统整体剩余空间。
- `du -sh` 查看目录实际占用。
- `lsblk` 查看块设备和分区。
- `mount` 查看挂载情况。

`df` 和 `du` 结果不一致时，可能是文件已被删除但进程仍然打开。可以进一步使用 `lsof +L1` 排查这类情况。

#### 2. 内存和系统负载

```bash
free -h
uptime
vmstat 1
```

- `free -h` 查看内存和 Swap。
- `uptime` 查看运行时间、登录用户和平均负载。
- `vmstat 1` 按秒观察运行队列、内存、上下文切换和 IO。

平均负载不是简单等于 CPU 使用率，还可能包含等待不可中断 IO 的任务。判断系统变慢时要结合 CPU、内存、磁盘延迟、网络和应用指标。

#### 3. IP、端口和连接

```bash
ip addr
ip route
ss -lntp
ss -ant
ping -c 4 example.com
curl -I https://example.com
curl -v http://127.0.0.1:8080/health
dig example.com
```

- `ip addr` 查看网卡和 IP 地址。
- `ip route` 查看路由表。
- `ss -lntp` 查看监听中的 TCP 端口及进程。
- `ss -ant` 查看 TCP 连接状态。
- `ping` 检查基本网络连通性，但被禁 ping 不代表 HTTP 一定不可用。
- `curl` 检查 HTTP 状态码、响应头和接口内容。
- `dig` 查询 DNS。

排查接口访问失败时，可以按顺序判断：

```text
域名能否解析
  -> 路由和网络是否可达
  -> 目标端口是否监听
  -> 防火墙或安全组是否放行
  -> HTTP 服务是否返回正确状态码
  -> 应用日志和下游依赖是否正常
```

### 第七层：压缩、传输和组合使用

#### 1. tar 和压缩

```bash
tar -czf app-20260905.tar.gz /opt/app
tar -xzf app-20260905.tar.gz -C /tmp/app
tar -tzf app-20260905.tar.gz
gzip application.log
gunzip application.log.gz
```

`tar` 负责归档，`gzip` 负责压缩，所以 `.tar.gz` 是“先打包再压缩”。解压前应确认目标目录，避免把文件覆盖到错误位置。

#### 2. scp 和 rsync

```bash
scp app.jar user@server:/opt/app/
rsync -avz --progress ./dist/ user@server:/var/www/dist/
```

`scp` 适合简单复制文件；`rsync` 会比较文件差异，只同步变化部分，适合部署目录、备份和增量同步。使用删除选项时要特别谨慎，源目录和目标目录写反可能造成数据丢失。

#### 3. 管道和重定向

```bash
grep "ERROR" application.log > errors.log
grep "WARN" application.log >> errors.log
command 2> error.log
command > all.log 2>&1
cat access.log | awk '{print $9}' | sort | uniq -c | sort -nr
```

- `>` 覆盖写入文件。
- `>>` 追加写入文件。
- `2>` 重定向标准错误。
- `2>&1` 把标准错误合并到标准输出。
- `|` 把前一个命令的输出交给后一个命令。

管道让简单命令组合成完整分析流程，是 Linux 命令行强大的核心原因之一。复杂脚本中还要关注每个命令的退出码、空结果和特殊字符。

### 第八层：一个真实排障示例

假设线上接口变慢，可以按下面流程初步定位：

```bash
# 1. 看机器负载和内存
uptime
free -h

# 2. 看 CPU 最高的进程
ps -eo pid,ppid,cmd,%cpu,%mem --sort=-%cpu | head

# 3. 看磁盘空间和大目录
df -h
du -h --max-depth=1 /var/log | sort -h

# 4. 看服务状态和最近日志
systemctl status my-service
journalctl -u my-service -n 200 --no-pager

# 5. 看端口是否监听
ss -lntp

# 6. 从本机检查接口
curl -v http://127.0.0.1:8080/health
```

如果 CPU 很高，继续分析线程和应用热点；如果磁盘满，先找大文件和日志策略；如果端口未监听，检查服务状态和启动日志；如果本机正常但外部访问失败，再检查 Nginx、防火墙、安全组和 DNS。命令的价值不在于“会背”，而在于能根据现象逐层缩小范围。

## 回答思路

### 答题逻辑框架

1. 先按文件、文本、权限、进程、磁盘、网络六类概括。
2. 每类给出几个核心命令和关键参数。
3. 重点解释管道、重定向、退出码和权限，而不是只背命令名。
4. 用“接口变慢”的排障流程串联 `uptime`、`ps`、`df`、`systemctl`、`ss` 和 `curl`。
5. 补充危险命令和生产环境的安全注意事项。

### 重点得分点

- 能熟练使用 `ls`、`cd`、`find`、`grep`、`tail`、`awk`。
- 能解释 `chmod 640`、`chown` 和 `sudo`。
- 能区分 `kill -15` 与 `kill -9`。
- 能使用 `ps`、`top`、`df`、`du`、`free`、`ss` 进行排障。
- 能说明 `>`、`>>`、`2>&1` 和管道的作用。
- 能把命令组合成实际问题的排查路径。

### 常见误区

- 误区 1：遇到进程问题直接 `kill -9`。  
  正解：优先使用 `SIGTERM`，给应用优雅退出和清理资源的机会。

- 误区 2：磁盘满只看 `df`。  
  正解：还要用 `du` 查目录，并考虑已删除但仍被进程打开的文件。

- 误区 3：看到 `chmod -R 777` 就能解决权限问题。  
  正解：应该定位属主、用户组、目录执行权限和安全策略，遵循最小权限。

- 误区 4：`ping` 不通就说明服务不可用。  
  正解：ICMP 可能被禁用，应继续检查 DNS、端口和 HTTP。

- 误区 5：直接对超大日志使用 `cat`。  
  正解：使用 `less`、`tail`、`grep` 和管道按需读取。

### 面试话术

“Linux 常用命令我会按排障流程来记：先用 `pwd`、`ls`、`find` 定位文件，再用 `less`、`tail`、`grep`、`awk` 分析内容；权限用 `id`、`chmod`、`chown`，进程和服务用 `ps`、`top`、`kill`、`systemctl`，资源用 `df`、`du`、`free`，网络用 `ip`、`ss`、`curl`、`dig`。实际排障时会把命令通过管道和重定向组合起来，并注意 `kill -15` 优先于 `kill -9`、避免 `chmod 777` 和误用 `rm -rf`。”

---

> 📋 **分类**: os
> 🏷️ **标签**: `Linux` `Shell` `文件管理` `进程管理` `网络排障`
> 📊 **难度**: 中级
> 📅 **归档时间**: 2026-09-05 09:10:00
