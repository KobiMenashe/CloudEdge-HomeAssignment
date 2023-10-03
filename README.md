# CloudEdge-HomeAssignment

Requirements:
Deploy & Configure the environment
 Deploy an AKS cluster on the Resource Group we created for you.
 Edit the Ingress Controller HELM values to make the Ingress Controller service (Load Balancer) private.
 Deploy the Ingress Controller to the cluster.
 Edit the template of the Hello World Helm Chart and add Ingress rules for the application:
o Define an Ingress resource that routes traffic to the Hello World service based on a host.
 Deploy the Hello World chart to the cluster.
 Deploy Hub Vnet and Application Gateway into the Hub Vnet.
 Configure the Application Gateway to route HTTP traffic to the NGINX Ingress Controller Service.
Test the solution functionality.
 Create a record in your host file that resolves your chosen host (that you configured in the Nginx Ingress rule) to the Application Gateway Public IP
 Access the Hostname in the browser, you should see the front end of the application you deployed to the AKS cluster.
