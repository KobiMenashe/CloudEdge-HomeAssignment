# CloudEdge-HomeAssignment

This assignment aims to assess your self-learning skills by writing Helm charts, deploying NGINX web server, configuring Ingress controllers, and integrating the solution in a well architected Hub&Spoke topology. 
You will demonstrate your understanding of container orchestration, deployment automation, scalability, and monitoring.

## Requirements:
Deploy & Configure the environment

- Deploy an AKS cluster on the Resource Group we created for you.
- Edit the Ingress Controller HELM values to make the Ingress Controller service (Load Balancer) private.
- Deploy the Ingress Controller to the cluster.
- Edit the template of the Hello World Helm Chart and add Ingress rules for the application:

  Define an Ingress resource that routes traffic to the Hello World service based on a host.

- Deploy Hub Vnet and Application Gateway into the Hub Vnet.
- Configure the Application Gateway to route HTTP traffic to the NGINX Ingress Controller Service.
