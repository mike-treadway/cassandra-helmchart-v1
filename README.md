# Cassandra Helm Chart for IBM Cloud Kubernetes
This helm chart deploys an Apache Cassandra cluster in IBM Cloud's Kubernetes service. The configuration defined in this chart, and changes made to the Cassandra Docker image, allow for easier scaling within a cluster, and outside the cluster.

## Deploying the Chart
After pulling down this repository, make necessary changes to `values.yaml` using the configuration information described below. Once the configuration has been set, run the following command to install the chart with the name `my-release`:

```
$ helm install --name my-release ./
``` 

## Configuring the Chart
### Private IPs
This chart requires the privately routable IP addresses that came deployed with your IBM Cloud Kubernetes cluster. The IP address for your cluster can be found by running the command:

```
kubectl -n kube-system get configmap ibm-cloud-provider-vlan-ip-config -o yaml
```
The `vlanipmap.json` configuration defines the available private IPs. You should use these IP addresses in the `nodeIPs` configuration in this chart.

### Configuration Values
Parameter  | Description | Default
:------------ | :------------ | :-------
`replicas`		| The number of nodes to deploy. | `1`
`dc`	| The data center name to use in the Cassandra config | `dc1`
`rack` | The rack name to use in the Cassandra config | `rack1`
`clusterName` | The name of the cluster to use in the Cassandra config |`cassandra`
`authenticator` | The authenticator to use in the Cassandra config | `PasswordAuthenticator`
`name` | The name to use when creating the Kubernetes components (Pods, Statefulset, Services, etc.). | `cassandra`
`namespace` | The Kubernetes namespace to provision into. | `default`
`nodeIPs` | The list of Node IPs available for use. Each node in the cluster will be assigned an IP in this list where the index within the stateful set determines the IP to use. External services are created from this IP list. Having more IPs in this list than replicas allows for scaling the statefulset up and down. | `10.0.0.1, 10.0.0.2, 10.0.0.3`
`seed` | The list of Cassandra seeds to use. When spanning regions, put the IPs of the seed nodes from other regions in this list. | `10.0.0.1`
`storage.enabled` | When true, this helm chart will attempt to provision block storage from IBM Block Storage service. When false, will not order any storage and nodes become ephemeral. | `false`
`storage.billingType` | The type of billing to use when ordering block storage. | `hourly`
`storage.storageClassName` | The storage class to order. | `ibmc-block-retain-silver`
`storage.size` | The amount of storage to order. | `50Gi`
`image` | The image to use. This Helm Chart depends on changes to the original Docker image, so don't chanage this unless you've built the changes into your own image and have uploaded to a private registry. | `mtreadway/cassandra:3.11`