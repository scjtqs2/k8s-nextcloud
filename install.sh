#!/bin/bash
helm repo add nextcloud https://nextcloud.github.io/helm/
helm repo update
helm install  nextcloud -n nextcloud   --create-namespace -f nextcloud.custom.yaml nextcloud/nextcloud
