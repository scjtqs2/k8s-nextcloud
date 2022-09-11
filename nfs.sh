helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm install nextcloud-nfs -n nextcloud  --create-namespace  nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --set image.repository=scjtqs/k8s \
    --set image.tag=nfs-subdir-external-provisioner-v4.0.2 \
    --set nfs.server=192.168.50.112 \
    --set nfs.path=/volume3/k8s-nextcloud  --set storageClass.name=nextcloud-nfs  --set storageClass.provisionerName=nextcloud-nfs
