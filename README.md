# CloudEdge-HomeAssignment

This assignment aims to assess your self-learning skills by writing Helm charts, deploying web server, configuring Ingress controllers, and integrating the solution in a well architected Hub&Spoke topology. 
You will demonstrate your understanding of container orchestration, deployment automation, scalability, and monitoring.

## Requirements:
Deploy & Configure the environment

- Deploy an AKS cluster on the Resource Group we created for you.
- Edit the Ingress Controller HELM values to make the Ingress Controller service (Load Balancer) private.
- Deploy the Ingress Controller to the cluster.
- Edit the template of the Hello World Helm Chart and add Ingress rules for the application:

  Define an Ingress resource that routes traffic to the Hello World service based on a host.

- Deploy Hub Vnet and Application Gateway into the Hub Vnet.
- Configure the Application Gateway to route HTTP traffic to the Ingress Controller Service.


## Test The Solution Functionality
- Create a record in your host file that resolves your chosen host (that you configured in the Ingress rule) to the Application Gateway Public IP

- Access the Hostname in the browser, you should see the front end of the application you deployed to the AKS cluster.


# Configuration Steps

## Deployment AKS-Helloworld
For this demonstration we'll use a sample front application of the AKS Service 
```python
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aks-helloworld-one  
spec:
  replicas: 1
  selector:
    matchLabels:
      app: aks-helloworld-one
  template:
    metadata:
      labels:
        app: aks-helloworld-one
    spec:
      containers:
      - name: aks-helloworld-one
        image: mcr.microsoft.com/azuredocs/aks-helloworld:v1
        ports:
        - containerPort: 80
        env:
        - name: TITLE
          value: "Welcome to Azure Kubernetes Service (AKS)"
```
## Internal LoadBalancer Private Service
In order to configure the LoadBalancer service to be internal you need to add the following annotation to the configuration:


service.beta.kubernetes.io/azure-load-balancer-internal: "true" 


```python
apiVersion: v1
kind: Service
metadata:
  name: aks-helloworld-one
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: "true"
spec:
  type: LoadBalancer
  ports:
  - port: 80
  selector:
    app: aks-helloworld-one
```
after applying the change the internal-lb will be visibly from the managed AKS RG in my case the private IP address 
 10.224.0.6 
[![i-lb-logo.png](https://i.postimg.cc/j5CkNshJ/i-lb-logo.png)](https://postimg.cc/zbZjYY6J)

[![i-lb-ip.png](https://i.postimg.cc/kMR7P9d4/i-lb-ip.png)](https://postimg.cc/mh4v7vkf)
## Ingress Rules - Route Access Based On Host
We'll create with this configuration an Ingress Controller - Routing Rule that will  accept the request based on the Host in my case i choose "ingresskobidemo.westeurope.cloudapp.azure.com" the request will forwarded to the backend LB in port 80

```python
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: aks-helloworld-one-ingress
  namespace: ingress
  annotations:
    kubernetes.io/ingress.class: azure/application-gateway
    appgw.ingress.kubernetes.io/use-private-ip: "false"
spec:
  rules:
  - host: ingresskobidemo.westeurope.cloudapp.azure.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: aks-helloworld-one
            port:
              number: 80
```
## Application Gateway
I've created the AGW with following Terraform code:

For the backend to have visibility in the public IP host, there are some important points to keep in mind in order to route the HTTP request

- Confirm a VNet Perring between the AGW VNet to the AKS VNet
- Configure the AGW Public IP DNS Host - same as defined in the Ingress Controller route rule
- Configure the AGW backend address pool target to the Private LB IP Address
- Configure the backend_http_settings in HTTP - Port 80
- Configure the http_listener in HTTP 
- Configure the request_routing_rule with the specifying priority 

```python
resource "azurerm_application_gateway" "appgw" {
  name                = "kobi-appgateway"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.front_subnet.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.gw_pip.id
  }

  backend_address_pool {
    name         = local.backend_address_pool_name
    ip_addresses = ["10.224.0.6"]
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    priority                   = 100
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
}
```
## Results
[![Host-screenshoot.png](https://i.postimg.cc/W1xWFvkz/Host-screenshoot.png)](https://postimg.cc/Wd66CxSc)
