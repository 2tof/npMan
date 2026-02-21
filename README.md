*NP manager*

在原版的脚本基础上修改。
增加了v6显示等；
重命名成：npMan (npMananger)

v1.0更新：
- 增加的“旧配置嗅探”功能，还会自动读取你旧的端口、API 前缀和 TLS 模式，并在安装时作为默认值推荐（来自旧的 .gob 数据库文件）。
- 增加 将api url和key写入/etc/nodepass/api.txt。
- 解除已安装np的情况下， 不能使用-i参数；现在可以选择4. reconfigure/install 或-i参数 覆盖安装（不改变原来的api配置）；需要修改的话可以用-k参数。
- 修正原来的ipv6地址在单栈机上会显示两次的bug。

下载安装
```
sudo bash <(curl -sL https://raw.githubusercontent.com/2tof/npMan/main/npman.sh)
```
wget
```
wget -qO npman.sh https://raw.githubusercontent.com/2tof/npMan/main/npman.sh && sudo bash npman.sh
```
直接安装 （参数-i）
```
curl -sL https://raw.githubusercontent.com/2tof/npMan/main/npman.sh | sudo bash -s -- -i
```

v1.0菜单
1.Stop API (np -o)
2.Change KEY (np -k)
3.Upgrade core (np -v)
4.Reconfigure/Install (np -i)
5.Uninstall (np -u)
6.Exit

原nodepass项目链接：
Nodepass Project

https://github.com/NodePassProject

https://nodepass.eu/

NPsh脚本
https://github.com/NodePassProject/npsh
