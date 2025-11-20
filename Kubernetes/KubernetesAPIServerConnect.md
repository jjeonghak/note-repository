# 쿠버네티스 API 서버와 통신
`downwardAPI`는 단지 파드 자체의 메타데이터와 모든 파드 데이터 중 일부만 노출  
애플리케이션에서 클러스터의 정의된 다른 파드나 리소스에 관한 정보가 필요한 경우  

<img width="450" height="200" alt="kubernetes_api_server_connection" src="https://github.com/user-attachments/assets/cb07ebfa-83f1-4d03-b22b-3b5e110c470a" />

<br>
<br>

### 쿠버네티스 REST API

```
$ kuberctl cluster-info
Kubernetes master is running at https://192.168.99.100:8443
```

<br>

- `kubectl proxy`로 연결 가능

```
$ curl https://192.168.99.100:8443 -k
Unauthorized

$ kubectl proxy
Starting to serve on 127.0.0.1:8001

$ curl http://localhost:8001
{
  "paths": [
    "/api",
    "/api/v1",
    "/apis",
    "/apis/apps",
    "/apis/apps/v1beta1",
    ...
    "/apis/batch",
    "/apis/batch/v1",
    "/apis/batch/v2alpha1",
...
```

<br>

### API 그룹의 REST 엔드포인트 조회

```
$ curl http://localhost:8001/apis/batch
{
  "kind": "APIGroup",
  "apiVersion": "v1",
  "name": "batch",
  "versions": [
    {
      "groupVersion": "batch/v1",
      "version": "v1"
    },
    {
      "groupVersion": "batch/v2alpha1",
      "version": "v2alpha1"
    }
  ],
  "preferredVersion": {
    "groupVersion": "batch/v1",
    "version": "v1"
  },
  "serverAddressByClientCIDRs": null
}
```

<br>

```
$ curl http://localhost:8001/apis/batch/v1
{
  "kind": "APIResourceList",
  "apiVersion": "v1",
  "groupVersion": "batch/v1",
  "resources": [
    {
      "name": "jobs",
      "namespace": true,
      "kind": jobs,
      "verbs": [
        "create",
        "delete",
        "deletecollection",
        "get",
        "list",
        "patch",
        "update",
        "watch"
      ]
    },
    {
      "name": "jobs/status",
      "namespace": true,
      "kind": "Job",
      "verbs": [
        "get",
        "patch",
        "update"
      ]
    }
  ]
}
```

<br>

### 클러스터에 있는 모든 인스턴스 나열

```
$ curl http://localhost:8001/apis/batch/v1/jobs
{
  "kind": "JobList",
  "apiVersion": "batch/v1",
  "metadata": {
    "selfLink": "/apis/batch/v1/jobs",
    "resourceVersion": "225162"
  },
  "items": [
    {
      "metadata": {
        "name": "my-job",
        "namespace": "default",
...
```

<br>

### 이름별로 특정 인스턴스 검색

```
$ curl http://localhost:8001/apis/batch/v1/namespace/default/jobs/my-job
{
  "kind": "Job",
  "apiVersion": "batch/v1",
  "metadata": {
    "name": "my-job",
    "namespace": "default",
...
```

<br>

### 파드 내에서 API 서버와 통신
`kubectl proxy` 없이 파드 내부에서 통신하려면 아래 항목 필요  
- API 서버 위치
- API 서버와 통신하고 있는지 확인 방법
- API 서버로 인증

<br>

### API 서버 위치
`kubernetes`라는 서비스가 디폴트 네임스페이스에 자동으로 노출되고 API 서버를 가리키도록 구성  

```
$ kubectl get svc
NAME        CLUSTER-IP  EXTERNAL-IP  PORT(S)  AGE
kubernetes  10.0.0.1    <none>       443/TCP  46d
```

<br>

컨테이너 내부에 환경 변수에서 확인 가능  

```
root@curl:/# env | grep KUBERNETES_SERVICE
KUBERNETES_SERVICE_PORT=443
KUBERNETES_SERVICE_HOST=10.0.0.1
KUBERNETES_SERVICE_PORT_HTTPS=443
```

<br>

각 서비스마다 DNS 엔트리가 존재  

```
root@curl:/# curl https://kubernetes
curl: (60) SSL certificate problem: unable to get local issuer certificate
...
```

<br>

### 서버 아이덴티티 검증
각 컨테이너의 `/var/run/secrets/kubernetes.io/serviceaccount/`에 마운트되는 기본 시크릿  

```
root@curl:/# ls /var/run/secrets/kubernetes.io/serviceaccount/
ca.crt  namespace  token

root@curl:/# curl --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt https://kubernetes
Unauthorized

root@curl:/# export CURL_CA_BUNDLE=/var/run/secrets/kubernetes.io/serviceaccount/ca.
```

<br>

### API 서버로 인증

```
root@curl:/# TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
root@curl:/# curl -H "Authorization: Bearer $TOKEN" https://kubernetes
{
  "paths": [
    "/api",
    "/api/v1",
    "/apis",
    "/apis/apps",
    "/apis/apps/v1beta1",
    "/apis/authorization.k8s.io",
    ...
    "/ui/",
    "/version"
  ]
}
```

<br>
