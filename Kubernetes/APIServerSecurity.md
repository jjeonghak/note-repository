# 쿠버네티스 API 서버 보안

<br>

## 인증
API 서버가 요청을 받으면 인증 플러그인 목록을 거치면서 요청이 전달  
각각의 인증 플러그인이 요청을 검사  

<br>

### 사용자와 그룹
인증 플러그인은 인증된 사용자의 사용자 이름과 그룹을 반환  
사용자는 실제 사람과 파드로 두 종류의 클라이언트를 구분  
사용자는 싱글 사인온(`single sign on`)과 같은 외부 시스템, 파드는 서비스 어카운트(`service account`) 매커니즘 사용  
휴먼 사용자와 서비스어카운트는 하나 이상의 그룹에 속하는 것 가능  
- `system:unauthenticated`: 어떤 인증 플러그인에서도 인증할 수 없는 요청에 대해 사용되는 그룹
- `system:authenticated`: 성공적으로 인증된 사용자에게 자동으로 할당되는 그룹
- `system:serviceaccounts`: 시스템의 모든 서비스어카운트를 포함하는 그룹
- `system:serviceaccounts:<namespace>`: 특정 네임스페이스의 모든 서비스어카운트를 포함하는 그룹

<br>

### 서비스어카운트
모든 파드는 파드에서 실행중인 애플리케이션의 아이덴티티를 나타내는 서비스어카운트와 연계  
서비스어카운트의 인증 토큰은 시크릿 볼륨으로 각 컨테이너의 파일시스템에 마운트  
위치는 `/var/run/secrets/kubernetes.io/serviceaccount/token`  
서비스어카운트의 사용자 이름은 `system:serviceaccount:<namespace>:<service account name>` 형식  

<br>

서비스어카운트는 파드, 시크릿, 컨피그맵 등과 같은 리소스이며 개별 네임스페이스로 범위 지정  

<img width="550" height="250" alt="serviceaccount" src="https://github.com/user-attachments/assets/60a850c2-9c23-4bf2-b04a-bf16db3d7d0c" />

```
$ kubectl get serviceaccount
NAME     SECRETS  AGE
default  1        1d
```

<br>

파드 매니페스트에 서비스어카운트 지정 가능, 할당하지 않은 경우 네임스페이스 default 사용  
파드에 서로 다른 서비스어카운트를 할당해서 각 파드가 액세스할 수 있는 리소스 제어 가능  

<br>

### 서비스어카운트 생성
```
$ kubectl create serviceaccount foo
serviceaccount "foo" created

$ kubectl describe sa foo
Name:               foo
Namespace:          default
Labels:             <none>
Image pull secrets: <none>
Mountable secrets:  foo-token-qzq7j
Tokens:             foo-token-qzq7j

$ kubectl describe secret foo-token-qzq7j
...
ca.crt: 1066 bytes
namespace: 7 bytes
token: eyJhbGci0iJSUzI1NiIsInR5cCI6IkpXVCJ9...
```

<br>

기본적으로 파드는 원하는 모든 시크릿을 마운트 가능  
하지만 파드가 서비스어카운트의 마운트 가능한 시크릿 목록에 있는 시크릿만 마운트 강제 가능  
해당 기능은 서비스어카운트가 `kubernetes.io/enforce-mountable-secrets="true"` 어노테이션 추가  

<br>

서비스어카운트는 이미지 풀 시크릿 목록도 포함 가능  
이미지 풀 시크릿은 프라이빗 이미지 레포지토리에서 컨테이너 이미지를 불러오는데 필요한 자격증명  
해당 기능은 특정 이미지 풀 시크릿만을 강제하는 것이 아닌 모든 파드에 자동 추가 기능  

```yaml
apiVersion: v1
kind: SeviceAccount
metadata:
  name: my-service-account
imagePullSecrets:
  - name: my-dockerhub-secret
```

<br>

파드에 추가할때는 `spec.service.AccountName` 필드에 추가, 추후에 변경 불가  

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: curl-custom-sa
spec:
  serviceAccountName: foo
  containers:
  - name: main
    image: tutum/curl
    command: ["sleep", "9999999"]
  - name: ambassador
    image: luksa/kubectl-proxy:1.6.2
```

<br>

## 역할 기반 액세스 제어
1.8.0 버전 이후 `RBAC` 인가 플러그인이 `GA`로 승격되어 많은 클러스터에서 기본적으로 활성화  
`RBAC`는 권한이 없는 사용자가 클러스터 상태를 보거나 수정하지 못하게 지원  
사용자는 서버에 HTTP 요청을 보내 액션을 수행할때 요청에 자격증명을 포함시켜 자신을 인증  
인가 규칙은 네개의 리소스로 구성되며 두개 그룹으로 분류 가능  
- 롤과 클러스터롤: 리소스에 수행할 수 있는 동사 지정
- 롤바인딩과 클러스터롤바인딩: 위의 롤을 특정 사용자, 그룹, 서비스어카운트에 바인딩

<img width="550" height="300" alt="rbac" src="https://github.com/user-attachments/assets/58a323dd-22b7-48cc-881f-ed4a52e2e5a0" />

<br>
<br>

롤과 롤바인딩은 네임스페이스가 지정된 리소스  
클러스터롤과 클러스터롤바인딩은 네임스페이스가 지정되지 않은 클러스터 수준 리소스  

<img width="550" height="350" alt="role_and_clusterrole" src="https://github.com/user-attachments/assets/f7074a40-c7c6-4e0c-bcac-2b9fe807eed8" />

<br>
<br>

롤 리소스는 어떤 리소스에 어떤 액션을 수행 가능한지 정의  

<img width="550" height="300" alt="role" src="https://github.com/user-attachments/assets/8f3fbed4-d674-465b-ba7c-d747c67d5f7b" />

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: foo
  name: service-reader
rules:
  - apigroups: [""]
    verbs: ["get", "list"]
    resources: ["services"]
```

<br>

롤은 수행 가능한 액션을 정의하지만 누가 수행할지 지정하지 않음  
주체에 바인딩하기 위해서는 롤바인딩 필요  

<img width="500" height="300" alt="rolebinding" src="https://github.com/user-attachments/assets/33669b39-1730-470c-ab0e-6999c8520dc5" />

```
$ kubectl create rolebinding test --role=service-reader --serviceaccount-foo:default -n foo
rolebinding "test" created

$ kubectl get rolebinding test -n foo -o yaml
```
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: test
  namespace: foo
  ...
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: service-reader
subjects:
- kind: ServiceAccount
  name: default
  namespace: foo
```

<br>

일반 롤은 롤이 위치하고 있는 동일한 네임스페이스 리소스에만 액세스 가능  
또한 API 서버의 리소스를 나타내지 않는 일부 URL 경로에 관한 액세스 권한 부여 불가  
클러스터롤을 사용해서 클러스터 수준 리소스에 액세스 가능  

```
$ kubectl create clusterrole pv-reader --verb=get,list --resource=persistentvolumes
clusterrole "pv-reader" created

$ kubectl get clusterrole pv-reader -o yaml
```

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pv-reader
  resourceVersion: "39932"
  selfLink: ...
  uid: e9ac1099-30e2-11e7-955c-080027e6b159
rules:
- apiGroup:
  - ""
  resources:
  - persistentvolumes
  verbs:
  - get
  - list
```

<br>

클러스터롤은 일반 롤바인딩이 아닌 클러스터롤바인딩을 해야 제대로 동작  

```
$ kubectl create clusterrolebinding pv-test --clusterrole=pv-reader --serviceaccount=foo:default
clusterrolebinding "pv-test" created
```

<br>

일반적으로 `system:discovery` 클러스터롤을 통해 리소스가 아닌 URL 액세스 가능  

```
$ kubectl get clusterrole system:discovery -o yaml
```

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: system:discovery
  ...
rules:
- nonResourceURLs:
  - /api
  - /api/*
  - /apis
  - /apis/*
  - /healthz
  - /swafferapi
  - /swafferapi/*
  - /version
  verbs:
  - get
```

```
$ kubectl get clusterrolebinding system:discovery -o yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:discovery
  ...
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:discovery
subjects:
- apiGroup: rbac.authoziation.k8s.io
  kind: Group
  name: system:authenticated
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: system:unauthenticated
```

<br>

클러스터롤이 항상 클러스터롤바인딩이 될 필요는 없음  
클러스터롤은 일반 롤바인딩과 클러스터 롤바인딩에 따라 동작 상이  

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: CluterRole
metadata:
  name: view
  ...
rules:
- apiGroups:
  - ""
  resources:
  - configmaps
  - endpoints
  - persistentvolumeclaims
  - pods
  - replicationcontrollers
  - replicationcontrollers/scale
  - serviceaccounts
  - services
  verbs:
  - get
  - list
  - watch
...
```

<img width="600" height="300" alt="clusterrole_with_clusterrolebinding" src="https://github.com/user-attachments/assets/8abeef15-0bad-44d3-aa8e-9ef9559b0ec9" />

<img width="600" height="300" alt="clusterrole_with_rolebinding" src="https://github.com/user-attachments/assets/51979577-e862-4515-a173-81f6b9af7c9e" />

<br>
<br>

| 액세스 | 롤 타입 | 바인딩타입 |
|--|--|--|
| 클러스터 수준 리소스(노드, PV) | 클러스터롤 | 클러스터롤바인딩 |
| 리소스가 아닌 URL | 클러스터롤 | 클러스터롤바인딩 |
| 모든 네임스페이스의 네임스페이스로 지정된 리소스 | 클러스터롤 | 클러스터롤바인딩 |
| 특정 네임스페이스의 네임스페이스로 지정된 리소스 <br> (여러 네임스페이스에 동일한 클러스터롤 재사용) | 클러스터롤 | 롤바인딩 |
| 특정 네임스페이스의 네임스페이스로 지정된 리소스 <br> (각 네임스페이스에 롤을 정의) | 롤 | 롤바인딩 |

<br>

























