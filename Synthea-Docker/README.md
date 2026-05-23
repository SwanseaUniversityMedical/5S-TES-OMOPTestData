Generates Synthetic patient data using metabolic modules in [synthea](https://github.com/synthetichealth/synthea) 

Get the required jar from [this](https://github.com/synthetichealth/synthea/releases/download/master-branch-latest/synthea-with-dependencies.jar)

properties file contains the config to be used to get the output data , which can be found [here](https://github.com/synthetichealth/synthea/wiki/Common-Configuration)

### Instructions to run 


```console 
docker build -t syntheadata:1.0 .

docker run -v ./output:/synthea/output -it syntheadata:1.0 -p 10
```
> By defualt it generates 25 patients records,it can be changed by passing in docker command