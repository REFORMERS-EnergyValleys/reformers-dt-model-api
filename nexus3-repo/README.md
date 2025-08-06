# Additional Notes on Sonatype Nexus3 Repository

## Manual post-install

+ Get the initial admin password from file `admin.password`, located on the mounted volume.
```
docker cp reformers-repository-1:/nexus-data/admin.password .
cat admin.password
```
+ Login as `admin` with the initial password at `https://<HOST-NAME>`
+ Follow the steps in the setup wizard (set new admin password, enable anonymous access).
+ Go to _Server administration and configuration_ (gear symbol ⚙️) &rarr; _Security_ &rarr; _Realms_ and add `Docker Bearer Token Real` to active realms
+ Go to _Server administration and configuration_ (gear symbol ⚙️) &rarr; _Repository_ &rarr; _Repositories_:
  - Optional: remove pre-configured repositories
  - Create new repositories with the following repositories types / names / HTTP connector ports:
    * `docker (hosted)` / `model-generators` / 8082
    * `docker (hosted)` / `model-images` / 8083
[//]: # (    * `maven2 (hosted)` / `model-artifacts` / --)
  - For all new repositories, select the following options:
    * _Online_ &rarr; check
    * _HTTP_ (Create an HTTP connector at specified port) &rarr; check and set port number (see above)
[//]: # (  - For `docker (hosted)` repositories, select the following options:)
    * _Allow anonymous docker pull_ &rarr; check
    * _Enable Docker V1 API_ &rarr; check
[//]: # (  - For `maven2 (hosted)` repositories, select the following options:)
[//]: # (    * _Version policy_ &rarr; Mixed)
[//]: # (    * _Layout policy_ &rarr; Permissive)
[//]: # (    * _Deployment policy_ &rarr; Allow redeploy)

*NOTE*:
SSL/TLS encryption should be enabled via the reverse proxy (see the [Docker compose file](../docker-compose.yml)).
Hence, the Docker registries require only an HTTP connector port.

## Advanced Usage of API

### Model generators - container images

#### List model generators

+ via Sonatype API (full info):
  ```
  curl -k -X GET "https://<HOST-NAME>/service/rest/v1/search?repository=model-generators"
  ```
+ via Docker registry (names only)
  ```
  curl -k -X GET "https://<HOST-NAME>/repository/model-generators/v2/_catalog"
  ```
  or
  ```
  curl -k -X GET "https://<HOST-NAME>:8082/v2/_catalog"
  ```

#### Retrieve labels for model generator

_ATTENTION_: requires [jq](https://jqlang.github.io/jq/download/)

```
digest=$(curl -k -X GET "https://<HOST-NAME>:8082/v2/<GENERATOR-NAME>/manifests/<GENERATOR-TAG>" | jq .config.digest -r)
curl -k -X GET "https://<HOST-NAME>:8082/v2/<GENERATOR-NAME>/blobs/$digest" | jq .config.Labels
```
or
```
digest=$(curl -k -X GET "https://<HOST-NAME>/repository/model-generators/v2/<GENERATOR-NAME>/manifests/<GENERATOR-TAG>" | jq .config.digest -r)
curl -k -X GET "https://<HOST-NAME>/repository/model-generators/v2/<GENERATOR-NAME>/blobs/$digest" | jq .config.Labels
```

### Models - container images

#### List all model images

+ via Sonatype API:
  ```
  curl -k -X GET "https://<HOST-NAME>/service/rest/v1/search?repository=model-images"
  ```
+ via Docker registry:
  ```
  curl -k -X GET "https://<HOST-NAME>/repository/models/v2/_catalog"
  ```
  or
  ```
  curl -k -X GET "https://<HOST-NAME>/v2/_catalog"
  ```

#### List models images for a specific generator name / tag

```
curl -k -X GET "https://<HOST-NAME>/service/rest/v1/search?repository=model-images&name=<GENERATOR-NAME>?<GENERATOR-TAG>*"
```

[//]: # (### Models - build artifacts)

[//]: # (#### Upload)

[//]: # (```)
[//]: # (curl -k -u <USER>:<PWD> -X POST -F "maven2.generate-pom=true" -F "maven2.groupId=generator3.v1-0" -F "maven2.artifactId=model3" -F "version=latest" -F "maven2.[//]: # (asset1=@model3-artifact.txt" -F "maven2.asset1.extension=txt" "https://<HOST-NAME>/service/rest/v1/components?repository=model-artifacts")
[//]: # (```)

[//]: # (#### Download)

[//]: # (```)
[//]: # (curl -k -X GET https://reformers-dev.ait.ac.at/repository/model-artifacts/generator3/v1-0/model3/latest/model3-latest.txt)
[//]: # (```)


[//]: # (#### List artifacts)

[//]: # (List artifacts, including POM files and hashes:)
[//]: # (```
[//]: # (curl -k -X GET "https://reformers-dev.ait.ac.at/service/rest/v1/search?repository=model-artifacts")
[//]: # (```)

[//]: # (#### List artifacts with specific file extension)

[//]: # (```)
[//]: # (curl -k -X GET "https://reformers-dev.ait.ac.at/service/rest/v1/search/assets?repository=model-artifacts&maven.extension=txt")
[//]: # (```)
