# azureDevOpsAgents

A template repo for the creation and maintenance of Azure DevOps Self Hosted Agents.

Reasons why you would use this instead of the MS hosted agents:

* [If you have a pipeline that needs to share files between jobs](https://stackoverflow.com/questions/55694545/how-to-share-files-between-yaml-stages-in-azure-devops)

## Build Journal

*Baking an image*

* Ended up creating an [Image Factory](https://dev.azure.com/IMTCloudPlatforms/cptImageFactory) repo to take care of the
  baking of the image for the ADO agent. We're going to need an image baking pipeline at some point so figured it 
  wouldn't hurt to create a basic one.
  * DONE: https://dev.azure.com/IMTCloudPlatforms/_git/cptImageFactory?path=%2F&version=GBdevelop%2F20200212-first-success-build&_a=contents

*Building an ADO agent from an image*
* See https://wouterdekort.com/2018/02/27/build-your-own-hosted-vsts-agent-cloud-part-2-deploy/

*NEXT*

* Setup the agent VSS based on the image from the image factory.
* Have the agent installed and autoconfigured per https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/v2-linux?view=azure-devops
    * Unattended config: https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/v2-linux?view=azure-devops#unattended-config
* Start and stop the agents per time schedule: https://wouterdekort.com/2018/03/05/build-hosted-vsts-agent-cloud-part-3-automate/
    * See the "Manage" heading in the above URL
    * Better yet, start and stop on demand: https://dobryak.org/self-hosted-agents-at-azure-devops-a-little-cost-saving-trick/

## References:


### PowerShell
* 
* https://github.com/janikvonrotz/awesome-powershell

### How to build your own agents

NB: These are ranked from top to bottom to represent what I think is the most promising:

* 25/2/2018 - https://wouterdekort.com/2018/02/25/build-your-own-hosted-vsts-agent-cloud-part-1-build/
    * Links to (2y old): https://github.com/WouterDeKort/VSTSHostedAgentPool
    * Small Image Packer Build for testing: https://github.com/WouterDeKort/VSTSHostedAgentPool/blob/master/config/small-image.json
* Part 2    - https://wouterdekort.com/2018/02/27/build-your-own-hosted-vsts-agent-cloud-part-2-deploy/

### Unsorted

https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/v2-linux?view=azure-devops
* 23/9/2018 - https://www.mikaelkrief.com/private-azure-devops-agent/
* https://blog.baslijten.com/how-to-run-azure-devops-hosted-linux-build-agents-as-private-agents-and-be-able-to-scale-them-accordingly/
* https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/agents?view=azure-devops&tabs=browser
* https://andrewmatveychuk.com/how-to-run-azure-devops-self-hosted-agents-effectively/
* https://stackoverflow.com/questions/55694545/how-to-share-files-between-yaml-stages-in-azure-devops
