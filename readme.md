# k8s 方式部署 nextcloud

> 相关的镜像支持 amd64、arm64、armhf
>
> 存储采用了nfs的 storage。存储和计算分离。
>
> 样例架构：k8s装在树莓派4b上，数据通过(黑)群晖的nfs共享到树莓派，路由器开启k8s的ingress的端口映射，mysql也在(黑)群晖上。
>

## 一、环境依赖

+ helm >=v3.9
+ kubernetes（kubelete、kubectl、kubeadm） >= 1.23
+ mysql >= 5.7
+ nfs server
+ cert-manager >= 1.19
+ 如果你没有公网80端口（一般家用宽带都没有），则需要对应的cert-manager的dns验证方式插件。这里以dnspod（腾讯云api）方式的为例

> 如果你没有k8s环境、cert-manager 啥的，可以参考 `https://github.com/scjtqs2/kubernets-installer` 进行安装
>

## 二、配置存储设置

1. 修改 nfs.sh 脚本：
    1. 修改里面的`nfs.server`地址
    2. 修改里面的`nfs.path`路径
    3. 当前仓库里面的nfs.sh是一个黑群晖的配置：
        + 在`共享文件夹` 中创建文件夹。eg: 命名为 `k8s-nextcloud`，选第三块盘。路径就是 `/volume3/k8s-nextcloud`，具体路径，请ssh进去确认。
        + `NFS权限` 中`增加`配置
        + `服务器名称或IP地址` 填你的内网网段 例如 `192.168.50.0/24` 保证k8s所在的机器能够访问它
        + `权限` 可读性
        + `squash` 无映射
        + `安全性` sys
        + 勾选`启动异步`
        + 在 `/etc/exports` 中的配置如此： `/volume3/k8s-nextcloud  192.168.50.0/24(rw,async,no_wdelay,no_root_squash,insecure_locks,sec=sys,anonuid=1025,anongid=100)`
2. 修改`pvc.yaml`，里面总共两部分，一个pv，一个pvc:
    + 修改里面的`storage`字段，为你想要的容量，这里默认1000Gi 也就是 1TB限制。两个部分的`storage`保持一致就行。
    + 修改`PersistentVolume`那段的`server`为你的nfs 服务器地址
    + 修改`PersistentVolume`那段的`path`为你的nfs 的共享文件夹的一个下级文件夹
      （别用共享文件夹本身，会有权限问题。如果用了下级文件夹依旧有权限问题，执行 `chmod 755 /volume3/k8s-nextcloud`）
3. 创建nfs的storageClass: 执行`bash nfs.sh`
4. 创建nextcloud需要的pvc： `kubectl apply -f pvc.yaml`

## 三、配置nextcloud配置
1. 修改 `nextcloud.custom.yaml` 文件
   1. `image`部分目前是最新的v24版本，就它了。官方的镜像缺失很多php扩展，这里使用我通过github的actions自动编译更新维护的镜像
   2. `ingress`部分：
      1. `cert-manager.io/cluster-issuer` 这里是以dnspod 的dns验证方式，并且配了 issur为 `dnspod`。具体参考 `https://github.com/scjtqs2/kubernets-installer` 中`7. (可选，非必须) 添加dnspod(实际是腾讯云接口)的dns证书签名验证方式`
      2. `tls.hosts` 改成你自己的域名。不带协议，不带端口。
   3. `nginx` 默认使用的是apache的镜像，就不用开启了。如果使用fp,的镜像，这里需要`enable`
   4. `phpClientHttpsFix` 不动
   5. `nextcloud`部分：
      1. `host` 你的域名，不带协议，不带端口。
      2. `username` 默认创建的管理员账号名
      3. `password` 默认创建的管理员账号密码
      4. `mail` 这块可以预先配置，也可以安装好后，与管理面板自行配置。
      5. `phpConfigs` 如果使用的是官方镜像，请删除/注释 着部分，因为官方镜像缺失扩展，没法开启php8的jit。
      6. `extraEnv` 这里的 NEXTCLOUD_TRUSTED_DOMAINS 部分改成你的所有可能会用到的域名、ip。带端口，不带协议。多个配置以空格 隔开
   6. `internalDatabase` 这里必须为false，否则将启用自带的sqllite，不会启动mysql。
   7. `externalDatabase` 按照说明填写你的数据库信息。支持mysql和postgresql
   8. `persistence` 不用动
   9. `redis` redis的高可用版本（集群），可以自行修改里面的 `auth.password` 字段。其他就不动了
   10. `hpa` 这个看个人需求吧。自动伸缩，可以启动多个nextcloud的后端pod。也可以在部署完成后通过 `kuboard`面板自行开启
   11. 其他的就不动了
## 四、 nextcloud的安装
1. 初始化安装： `bash install.sh`
2. 然后可以在namespace为`nextcloud`的环境下查看pod情况
3. 等待cert-manager的证书签发完成。

## 五、 nextcloud的卸载
> 如果你想重新安装，需要先进行卸载，然后在进行安装。
> 
1. 卸载nextcloud: `bash uninstall.sh`
2. (非必须)进入nfs服务器，删除生成的文件夹
3. (非必须。 当然，如果执行了2,则必须执行3)进入mysql，删除生成的数据表

## 六、 cronjob
> 仅使用官方镜像的才使用！！
> 
> 仅使用官方镜像的才使用！！
> 
> 仅使用官方镜像的才使用！！
> 
> 这个是针对使用了官方镜像 的用户，使用`nextcloud.custom.yaml`内置的镜像无需配置此项。。 我这边维护的镜像自带 crontab内部执行。也就是后台管理里面的 `Cron(推荐)`
> 
> 这是通过curl的方式 访问 cron.php。也就是后台管理里面的 `Webcron`
> 
> 要使用这个脚本，请确保 `nextcloud.extraEnv.NEXTCLOUD_TRUSTED_DOMAINS` 中有 `nextcloud` 字段
```shell
kubectl apply -f cronjob.yaml
```
