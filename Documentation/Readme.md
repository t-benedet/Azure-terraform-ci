# Create VM in Azure with Terraform and Github Action

<br>

<details open>

<summary> <h2>I - Configuration on Azure</h2></summary>

<br>

First of all, you have to create a Service Principal. 

To do that, go on your Azure account and start the cloud shell :

![image0](/Documentation/Pictures/Cloud__Shell.png)

Then you have to run these commands :


```
az ad sp create-for-rbac --name TerraformFabryk --role Contributor --scopes /subscriptions/XXX --sdk auth
```

![image1](/Documentation/Pictures/1.png)

You have to keep the 4 first lines of the Json : **clientId**, **clientSecret**, **subscriptionId** and **tenantId**.

<br>

### • Create a stockage backend for the Terraform state
---
<br>

```
az group create -g ResourceGroupFabryk -l northeurope
```

![image2](/Documentation/Pictures/2.png)

<br>

### • Create a stockage account in the resource group
---
<br>

```
az storage account create -n terraformfabryk -g ResourceGroupFabryk -l northeurope --sku Standard_LRS
```

<br>

### • Create a container in the resource group
---
<br>

```
az storage container create -n terraformstatefabryk --account-name terraformfabryk
```
![image3](/Documentation/Pictures/4.PNG)

</details>

<details open>

<summary> <h2>II - Secrets and terraform files </h2></summary>

<br>

You have to save the **clientId**, **clientSecret**, **subscriptionId** and **tenantId** as a secrets in github.

Go on Settings > Secrets and variables > Actions > New repository secret.

![image4](/Documentation/Pictures/5.png)

Once that is done, you should have 4 secrets :

![image5](/Documentation/Pictures/6.png)

</details>
