# Create VM in Azure with Terraform and Github Action

<br>

## I - Create a Service principal

<br>

First of all, you have to create a Service Principal. 

To do that, go on your Azure account and start the cloud shell :

![image1]()

Then you have to run these commands :


```
az ad sp create-for-rbac --name TerraformFabryk --role Contributor --scopes /subscriptions/XXX --sdk auth

```

![image1]()

You have to keep the 4 first lines of the Json : **clientId**, **clientSecret**, **subscriptionId** and **tenantId**.

<br>

## II - Create a stockage backend for the Terraform state

<br>

```
az group create -g ResourceGroupFabryk -l northeurope
```

![image2]()

<br>

## III - Create a stockage account in the resource group

<br>
```
az storage account create -n terraformfabryk -g ResourceGroupFabryk -l northeurope --sku Standard_LRS
```

![pas dimage]


<br>

## IV - Create a container in the resource group
<br>

```
az storage container create -n terraformstatefabryk --account-name terraformfabryk
```

