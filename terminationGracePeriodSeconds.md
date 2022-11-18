```mermaid
sequenceDiagram
    title Tuning terminationGracePeriodSeconds (default: 30 seconds)
    participant T-7 kubectl delete pod
    participant T-6
    participant T-5
    participant T-4 SIGTERM
    participant T-3
    participant T-2
    participant T-1 SIGKILL
    participant T-0 Pod deleted
    T-7 kubectl delete pod->>T-6: API server 
    T-6->>T-5: Endpoint controller
    T-5->>T-4 SIGTERM: API server
    T-4 SIGTERM->>T-3: Kube-proxy
    T-3->>T-2: iptables 
    T-4 SIGTERM->>T-2: ingress
    T-4 SIGTERM->>T-2: Core DNS
    T-6->>T-5: kubelet
    T-5->>T-4 SIGTERM: prestop hook
    T-4 SIGTERM->>T-1 SIGKILL: Graceful shutdown
    T-1 SIGKILL->>T-0 Pod deleted: API server
    T-7 kubectl delete pod->>T-2: The Pod's IP address is still used to make requests
    T-5->>T-1 SIGKILL: terminationGracePeriodSeconds (default: 30 seconds)
    T-7 kubectl delete pod->>T-4 SIGTERM: Traffic to Pod
```

#### Further reading

- [Graceful shutdown and pod termination](https://github.com/puma/puma/blob/master/docs/kubernetes.md#graceful-shutdown-and-pod-termination)
- [https://learnk8s.io/graceful-shutdown](https://learnk8s.io/graceful-shutdown)
