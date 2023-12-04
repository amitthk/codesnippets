* 1 => Courtesy: https://medium.com/@mrJTY/kubernetes-cka-exam-cheat-sheet-6194ccf162bb

tips, see: https://medium.com/@mrJTY/exam-tips-for-taking-the-certified-kubernetes-admistrator-42d0b9ed72dd

Bookmark these links
One page API reference: https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26
kubectl command reference: https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands
kubectl cheat sheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/
Kubectl
Enabling autocomplete
https://kubernetes.io/docs/reference/kubectl/cheatsheet/#kubectl-autocomplete

source <(kubectl completion bash) # set up autocomplete in bash into the current shell, bash-completion package should be installed first.
echo "source <(kubectl completion bash)" >> ~/.bashrc # add autocomplete permanently to your bash shell.
alias k=kubectl
complete -o default -F __start_kubectl k
kubectl get with custom columns

kubectlget deployment \
  -o custom-columns=DEPLOYMENT:.metadata.name,CONTAINER_IMAGE:.spec.template.spec.containers[].image,READY_REPLICAS:.status.readyReplicas,NAMESPACE:.metadata.namespace \
  --sort-by=.metadata.name 
Verifing the kubeconfig
A kubeconfig file can be verified if it’s correctly working by doing a:

k cluster-info --kubeconfig=./.kubeconfig
Export useful variables
alias k=kubectl
export dry='--dry-run=client -o=yaml'
export oy='-o=yaml'
alias kn='kubectl config set-context --current --namespace '
export ETCDCTL_API=3
This is so that you can call $dry to export yaml files instead of creating the objects


# Make a pod yaml
k run <pod-name> --image=<image> $dry > pod.yaml

# Apply
k apply -f ./pod.yaml

# Get it back as yaml
k get po <pod-name> $oy
Workloads
Creating pods
k run <pod-name> --image=<image> $dry
Creating pods with security context
Build a yaml output and add this as part of `

Creating a deployment
k create deploy <deploy> --replicas=<n> --image=<image> $dry
Initiating a cluster with kubeadm
Install kubelet and kubeadm
https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/

apt update
apt search kubeadm kubelet
apt install kubeadm=1.26.0-00 kubelet=1.26.0-00
Init kubeadm in the controlplane
IP_ADDRESS=$(ifconfig eth0 | grep 'inet ' | cut -d: -f2 | awk '{print $2}')

kubeadm init \
  --apiserver-advertise-address=$IP_ADDRESSS \
  --apiserver-cert-extra-sans=controlplane \
  --pod-network-cidr=10.244.0.0/16
Make a token from the controlplane:
https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-token/

controlplane ~ ✖ kubeadm token  create --print-join-command
kubeadm join 192.15.211.6:6443 --token XXX --discovery-token-ca-cert-hash sha256:1493d93e085bcaa30819bc10958c54ff69a2ebea37a00632fb37c0621fc40139 
Join from a worker node
https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-join/

workernode$ kubeadm join 192.15.211.6:6443 --token XXX --discovery-token-ca-cert-hash sha256:1493d93e085bcaa30819bc10958c54ff69a2ebea37a00632fb37c0621fc40139
Back in the control plane, check the nodes:
controlplane ~ ➜  k get no
NAME           STATUS     ROLES           AGE    VERSION
controlplane   NotReady   control-plane   8m4s   v1.26.0
node01         NotReady   <none>          8s     v1.26.0
Install a CNI (eg: flannel)
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
Cluster Maintenance
Backing up etcd
https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/

export ETCDCTL_API=3 
etcdctl --endpoints $ENDPOINTS \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  snapshot save <output>
Endpoints can be found in:

cat /etc/kubernetes/manifests/etcd.yaml | grep listen-client-url
Restoring ectd
Extract the db output with:

export ETCDCTL_API=3 
etcdctl --endpoints $ENDPOINTS \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  snapshot restore <output>
Then mount the output directory in the static pod: /etc/kubernetes/manifest/etcd.yaml

    volumeMounts:
    - mountPath: <your-output-directory> # Change this
      name: etcd-data
Creating a new user
Create the keys:

https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/#create-private-key

openssl genrsa -out myuser.key 2048
openssl req -new -key myuser.key -out myuser.csr
Create a CSR k8s object: https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/#create-certificatesigningrequest

cat <<EOF
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: myuser
spec:
  request: $(cat myuser.csr | base64 | tr -d "\n")
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400  # one day
  usages:
  - client auth
EOF
Save that as a csr.yaml file

Apply it:

k apply -f ./csr.yaml
Approve the CSR:

https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/#approve-certificate-signing-request

kubectl certificate approve myuser
Creating a role
k create role --help

kubectl create role $dry --verb=<verb1,verb2,verb3> --resource=<resource1,resource2> <role>
Create role binding
k create rolebinding $dry --user=<user> --role=<role> <role-name>
Check using the auth can-i command
 k auth can-i create pods --as=<user>
Running upgrades
https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/

Upgrading the control plane:

# Unhold
apt-mark unhold kubeadm

# Update apt
apt-get update

# Find packages
apt show kubeadm

# Install what is available
apt-get install -y kubeadm=1.xx.0-00

# Upgrade kubeadm
kubeadm upgrade plan
kubeadm apply v.1.xx.0

# Drain the control plane
k drain <control-plane> --ignore-daemonsets

# Install kubelet and kubectl updates
apt-get update && apt-get install -y kubelet=1.26.x-00 kubectl=1.26.x-00 && \
apt-mark hold kubelet kubectl

# Restart kubelet
systemctl daemon-reload
systemctl restart kubelet

# Uncordon the node
k uncordon <control-plane>
Upgrading a worker node

ssh worker-node

# Note that there is a difference with this step
kubeadm upgrade node

# Drain the node
k drain <node> --ignore-daemonsets

# Update apt
apt-get update
apt-get install -y kubelet=1.xx.x-xx kubectl=1.xx.x-xx

# Restart the kubelet
systemctl daemon-reload
systemctl restart kubelet

# Uncordon the node
k uncordon <node>
Networking
Working with the ip command
Find ip address of nodes:

# Get ip address through kubectl
k get no -o wide

ssh <node>

# Find address and mac address of node
ip a | grep -C 3 <ip-address>

# Find network device
ip link
https://www.cyberciti.biz/faq/linux-ip-command-examples-usage-syntax/

Find status of network device
ip link show <device>

# For example:
ip link show cni0
3: cni0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether 1a:f8:aa:77:8f:53 brd ff:ff:ff:ff:ff:ff
Finding the IP address of the gateway out to the internet
ip route show default
default via 172.25.0.1 dev eth1 
Find the port of kube scheduler
netstat -nplt can be useful to find out what ports are open https://www.howtogeek.com/513003/how-to-use-netstat-on-linux/

netstat -nplt | grep scheduler
tcp        0      0 127.0.0.1:10259         0.0.0.0:*               LISTEN      3317/kube-scheduler 
In this case, we see that the scheduler is open on port 10259

Network policies
Network policies let you specify ingress and egress rules.

For example, this will only allow http traffic from anywhere into port 80.

https://kubernetes.io/docs/concepts/services-networking/network-policies/

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: test-network-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      role: db # Lets you specify labels
      run: pod-name # Depends on the label of your pod
  policyTypes:
    - Ingress
  ingress:
    - ports:
        - protocol: TCP
          port: 80
Services
https://kubernetes.io/docs/concepts/services-networking/service/

CoreDNS
https://kubernetes.io/docs/concepts/services-networking/service/#dns

Using nslookup to validate the service is reachable from a pod
Get the service:

k describe svc web-service 
Name:              web-service
Namespace:         default
Labels:            <none>
Annotations:       <none>
Selector:          label=value  # Pods with this label will receive this service
Type:              ClusterIP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                10.99.70.136
IPs:               10.99.70.136
Port:              <unset>  80/TCP
TargetPort:        80/TCP
Endpoints:         10.244.0.5:80
Session Affinity:  None
Events:            <none>
Exec/ run into a pod:

k exec -ti <pod>
Verify that you can look up the service with nslookup

nslookup web-service
Name:      web-service
Address 1: 10.99.70.136 web-service.default.svc.cluster.local
Port vs target port
This is usually a confusing thing

Port: is the incoming port to the service

TargetPort: is the target port pointing to a deployment/pods that the service forwards connections to.

Note: A Service can map any incoming port to a targetPort. By default and for convenience, the targetPort is set to the same value as the port field.

For example:

apiVersion: v1
kind: Service
metadata:
  name: mysql-service
  namespace: beta
spec:
    ports:
    - port: 3306
      targetPort: 3306
Common troubleshooting tips
Pods not scheduling? Check that pods in kube-system are running correctly.t

k get po -n kube-system
Would you like to know the metrics per node?

k top node
Metrics per pod

k top pod --containers=true
Kubelet not running? Restart it:

# Check that the config is correct
cat /etc/systemd/system/kubelet.service.d/10-kubeadm-conf

# Check the logs
journalctl -u kubelet

# Restart
systemctl restart kubelet
Side note, what is systemd?https://en.wikipedia.org/wiki/Systemd,

Side-side note: https://en.wikipedia.org/wiki/System_D



# 2 => courtesy https://www.devopsmadness.com/cka_cheatsheet/

# Core Concepts
## View resources in namespace dev:

kubectl get pods -n dev
View all pods in all namespaces:

kubectl get pods -A
View all resources in all namespaces:

kubectl get all -A
Generate a pod yaml file with nginx image and label env=prod:

kubectl run nginx --image=nginx --labels=env=prod --dry-run=client -o yaml > nginx_pod.yaml
Delete a pod nginx fast:

kubectl delete pod nginx --grace-period 0 --force
Generate Deployment yaml file:

kubectl create deploy --image=nginx nginx --dry-run=client -o yaml > nginx-deployment.yaml
Access a service test-service in a different namespace dev:

test-service.dev
Create a service for a pod valid-pod, which serves on port 444 with the name frontend:

kubectl expose pod valid-pod --port=444 --name=frontend
Recreate the contents of a yaml file:

kubectl replace --force -f nginx.yaml
Edit details of a deployment nginx:

kubectl edit deploy nginx
Set image of a deployment nginx:

kubectl set image deploy nginx nginx=nginx:1.18
Scale deployment nginx to 4 replicas and record the action:

kubectl scale deploy nginx --repliacs=4 --record
Get events in current namespace:

kubectl get events
Scheduling
Get pods with their labels:

kubectl get pods --show-labels
Get the pods that are labeled env=dev:

kubectl get pods -l env=dev
Get taints of node node01:

kubectl describe node node01 | grep -i Taints:
Label node node01 with label size=small:

kubectl label nodes node01 size=small
Default static pods path:

/etc/kubernetes/manifests
Check pod nginx logs:

kubectl logs nginx
Check pod logs with multiple containers:

kubectl logs <pod_name> -c <container_name>
Monitoring
Check node resources usage:

kubectl top node
Check pod and their containers resource usage:

kubectl top pod --containers=true
Application Lifecycle Management
Check rollout status of deployment app:

kubectl rollout status deployment/app
Check rollout history of deployment app:

kubectl rollout history deployment/app
Undo rollout:

kubectl rollout undo deployment/app
Create configmap app-config with env=dev:

kubectl create configmap app-config --from-literal=env=dev
Create secret app-secret with pass=123:

kubectl create secret generic app-secret --from-literal=pass=123
Cluster Maintenance
Drain node node01 of all workloads:

kubectl drain node01
Make the node schedulable again:

kubectl uncordon node01
Upgrade cluster to 1.18 with kubeadm:

kubeadm upgrade plan
apt-get upgrade -y kubeadm=1.18.0-00
kubeadm upgrade apply v1.18.0
apt-get upgrade -y kubelet=1.18.0-00
systemctl restart kubelet
Backup etcd:

export ETCDCTL_API=3
etcdctl \
--endpoints=https://127.0.0.1:2379 \
--cacert=/etc/kubernetes/pki/etcd/ca.crt \
--cert=/etc/kubernetes/pki/etcd/server.crt \
--key=/etc/kubernetes/pki/etcd/server.key \
snapshot save /tmp/etcd-backup.db
Restore etcd:

ETCDCTL_API=3 etcdctl snapshot restore /tmp/etcd-backup.db --data-dir /var/lib/etcd-backup
After edit /etc/kubernetes/manifests/etcd.yaml and change /var/lib/etcd to /var/lib/etcd-backup.

Security
Create service account sa_1

kubectl create serviceaccount sa_1
Check kube-apiserver certificate details:

openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout
Approve certificate singing request for user john:

kubectl certificate approve john
Check the current kubeconfig file:

kubectl config view
Check current context:

kubectl config current-context
Use context dev-user@dev:

kubectl config use-context prod-user@production
Validate if user john can create deployments:

kubectl auth can-i create deployments --as john
Create role dev to be able to create secrets:

kubectl create role dev --verb=create --resource=secret
Bind the role dev to user john:

kubectl create rolebinding dev-john --role dev --user john
Check namespaced resources:

kubectl api-resources --namespaced=true
Troubleshooting
View all the kube-system related pods:

kubectl get pods -n kube-system
Check if all nodes are in ready state:

kubectl get nodes
Check memory, cpu and disk usage on node:

df -h
top
Check status of kubelet service on node:

systemctl status kubelet
Check kubelet service logs:

sudo journalctl -u kubelet
View kubelet service details:

ps -aux | grep kubelet
Check cluster info:

kubectl cluster-info
Gather info
Find pod CIDR:

kubectl describe node | less -p PodCIDR
Get pods in all namespaces sorted by creation timestamp:

kubectl get pod -A --sort-by=.metadata.creationTimestamp
Find the service CIDR of node-master:

ssh node0master
cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep range
Find which CNI plugin is used on node-master:

ls /etc/cni/net.d/
Find events ordered by creation timestamp:

kubectl get events -A --sort-by=.metadata.creationTimestamp
Find internal IP of all nodes:

kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'
General notes
To create a daemonset, use kubectl create deploy command to create a .yaml file and then change the kind and remove replicas & strategy.
To find the static pod manifest path, check the exec command of kubelet service or staticPodPath parameter of kubelet’s config file.
To create a static pod, place a yaml definition file in the staticPodPath directory.
To identify static pods look for the suffix -<node_name> on pods.
To add a new scheduler copy the existing one and add to the container’s command the flags--leader-elect=false and --scheduler-name=my-scheduler-name. To use the new scheduler under spec of a pod definition file specify the option schedulerName.
To add a default command to a pod use command that overrides the default ENTRYPOINT from Dockerfile. Use args to override the Dockerfile CMD command for the commmand’s extra parameters.
