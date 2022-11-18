#### Tuning terminationGracePeriodSeconds (default: 30 seconds)

```mermaid
sequenceDiagram
    participant T7
    participant T6
    participant T5
    participant T4
    participant T3
    participant T2
    participant T1
    participant T0
    T7->>T7: kubectl delete pod
    T7->>T6: API server; T6->>T5: Endpoint controller; T5->>T4: API server
    T4->>T4: SIGTERM
    T4->>T3: Kube-proxy; T3->>T2: iptables 
    T4->>T2: ingress
    T4->>T2: Core DNS
    T6->>T5: kubelet; T5->>T4: prestop hook; T4->>T1: Graceful shutdown
    T1->>T1: SIGKILL
    T1->>T0: API server
    T0->>T0: Pod deleted
    T7->>T2: The Pod's IP address is still used to make requests
    T5->>T1: terminationGracePeriodSeconds (default: 30 seconds)
    T7->>T4: Traffic to Pod
```

#### Further reading

- [kubeconfig for an Amazon EKS cluster](https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html)
- [Graceful shutdown and pod termination](https://github.com/puma/puma/blob/master/docs/kubernetes.md#graceful-shutdown-and-pod-termination)
- [https://learnk8s.io/graceful-shutdown](https://learnk8s.io/graceful-shutdown)
